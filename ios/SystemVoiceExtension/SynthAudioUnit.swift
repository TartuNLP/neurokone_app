//  eSpeak-NG VoiceOver synthesis AudioUnit
//  Copyright (C) 2022  Yury Popov <git@phoenix.dj>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import AVFoundation
import Accelerate
import libespeak_ng
import OSLog

fileprivate let log = Logger(subsystem: "eesti_tts", category: "SynthAudioUnit")

enum EspeakParameter: AUParameterAddress {
  case rate, volume, pitch, wordGap, range
}

extension espeak_ng_STATUS {
  func check() throws {
    guard self == ENS_OK else {
      var stringBuffer = [CChar](repeating: 0, count: 512)
      let str = stringBuffer.withUnsafeMutableBufferPointer { buf in
        espeak_ng_GetStatusCodeMessage(self, buf.baseAddress!, buf.count)
        return String(cString: buf.baseAddress!)
      }
      throw NSError(domain: EspeakErrorDomain, code: Int(self.rawValue), userInfo: [ NSLocalizedFailureReasonErrorKey: str ])
    }
  }
}

fileprivate class SynthHolder {
  var samples: [Int16] = []
  var events: [espeak_EVENT] = []
}

fileprivate func synthCallback(samples: UnsafeMutablePointer<Int16>?, num_samples: Int32, events: UnsafeMutablePointer<espeak_EVENT>?) -> Int32 {
  let holder = events?.pointee.user_data.assumingMemoryBound(to: SynthHolder.self).pointee
  let buf = UnsafeBufferPointer(start: samples, count: Int(num_samples))
  holder?.samples.append(contentsOf: buf)
//  log.trace("samples: count=\(num_samples, privacy: .public) max=\(buf.reduce(0, { max($0, abs($1)) }), privacy: .public)")
  var evt = events
  while let e = evt?.pointee, e.type != espeakEVENT_LIST_TERMINATED {
    holder?.events.append(e)
    evt = evt?.advanced(by: 1)
//    switch e.type {
//    case espeakEVENT_SAMPLERATE:
//      log.trace("samplerate: \(e.id.number, privacy: .public)")
//    case espeakEVENT_SENTENCE:
//      log.trace("sentence: \(e.id.number, privacy: .public) (smp=\(e.sample, privacy: .public))")
//    case espeakEVENT_WORD:
//      log.trace("word: \(e.id.number, privacy: .public) (smp=\(e.sample, privacy: .public))")
//    case espeakEVENT_PHONEME:
//      log.trace("phoneme: '\(withUnsafeBytes(of: e.id.string, { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }), privacy: .private(mask: .hash))' (smp=\(e.sample, privacy: .public))")
//    case espeakEVENT_END:
//      log.trace("end: (smp=\(e.sample, privacy: .public))")
//    default:
//      log.trace("event: \(e.type.rawValue, privacy: .public)")
//    }
  }
  return 0
}

class EspeakContainer {
  struct Settings: Codable {
    var rate: Int32?
    var volume: Int32?
    var pitch: Int32?
    var wordGap: Int32?
    var range: Int32?
  }
  static let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  var langs: [_Voice]
  var voices: [_Voice]
  @JSONFileBacked<[String]>(storage: documentsDirectory.appending(component: "exposed.json")) var exposedLocales
  @JSONFileBacked<Settings>(storage: documentsDirectory.appending(component: "settings.json"), create: Settings.init) private var settings

  var rate: Int32? { get { settings?.rate } set { settings?.rate = newValue } }
  var volume: Int32? { get { settings?.volume } set { settings?.volume = newValue } }
  var pitch: Int32? { get { settings?.pitch } set { settings?.pitch = newValue } }
  var wordGap: Int32? { get { settings?.wordGap } set { settings?.wordGap = newValue } }
  var range: Int32? { get { settings?.range } set { settings?.range = newValue } }

  private init() {
    do {
      let sp = OSSignposter(logger: log)
      try sp.withIntervalSignpost("espeak_bundle") {
        let root = Self.documentsDirectory
        try EspeakLib.ensureBundleInstalled(inRoot: root)
        espeak_ng_InitializePath(root.path)
      }
      try sp.withIntervalSignpost("espeak_init") {
        try espeak_ng_Initialize(nil).check()
        try espeak_ng_InitializeOutput(ENOUTPUT_MODE_SYNCHRONOUS, 0, nil).check()
        try espeak_ng_SetVoiceByName(ESPEAKNG_DEFAULT_VOICE).check()
        try espeak_ng_SetPhonemeEvents(1, 0).check()
        espeak_SetSynthCallback(synthCallback)
      }
      (langs, voices) = sp.withIntervalSignpost("espeak_voices") {
        let new = espeakVoiceList()
        log.info("Langs: \(new.langs, privacy: .public)")
        log.info("Voices: \(new.voices, privacy: .public)")
        return new
      }
      sp.withIntervalSignpost("expose") {
        if exposedLocales == nil {
          exposedLocales = defaultLanguages.filter({ matchLang(langs, $0) != nil }).map({ $0.universalId })
        }
        log.info("Exposed: \(self.exposedLocales ?? [], privacy: .public)")
      }
    } catch let e {
      log.error("\(e, privacy: .public)")
      langs = []
      voices = []
    }
  }
  func setParams() throws {
    try rate.flatMap({ try espeak_ng_SetParameter(espeakRATE, $0, 0).check() })
    try volume.flatMap({ try espeak_ng_SetParameter(espeakVOLUME, $0, 0).check() })
    try pitch.flatMap({ try espeak_ng_SetParameter(espeakPITCH, $0, 0).check() })
    try wordGap.flatMap({ try espeak_ng_SetParameter(espeakWORDGAP, $0, 0).check() })
    try range.flatMap({ try espeak_ng_SetParameter(espeakRANGE, $0, 0).check() })
  }
  static private let _single = EspeakContainer()
  static var single: EspeakContainer {
    if Thread.isMainThread { return _single }
    return DispatchQueue.main.sync { return _single }
  }
}

private let emptyVoiceId = "__espeak"

public class SynthAudioUnit: AVSpeechSynthesisProviderAudioUnit {
  private var outputBus: AUAudioUnitBus
  private var parameterObserver: NSKeyValueObservation!
  private var _outputBusses: AUAudioUnitBusArray!
  private var format: AVAudioFormat
  private var output: [Float32] = []
  private var outputOffset: Int = 0
  private var outputMutex = DispatchSemaphore(value: 1)
  private static var espeakVoice = ""

  @objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {
    let basicDescription = AudioStreamBasicDescription(
      mSampleRate: 22050.0,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
      mBytesPerPacket: 4,
      mFramesPerPacket: 1,
      mBytesPerFrame: 4,
      mChannelsPerFrame: 1,
      mBitsPerChannel: 32,
      mReserved: 0
    )
    self.format = AVAudioFormat(cmAudioFormatDescription: try! CMAudioFormatDescription(audioStreamBasicDescription: basicDescription))
    outputBus = try AUAudioUnitBus(format: self.format)
    try super.init(componentDescription: componentDescription, options: options)
    _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus])

    let container = EspeakContainer.single

    self.parameterTree = .createTree(withChildren: [
      AUParameterTree.createGroup(
        withIdentifier: "espeak",
        name: "eSpeak-NG",
        children: [
          AUParameterTree.createParameter(
            withIdentifier: "rate",
            name: "Rate",
            address: EspeakParameter.rate.rawValue,
            min: AUValue(espeakRATE_MINIMUM), max: 900, unit: .BPM,
            unitName: "words per minute",
            valueStrings: nil,
            dependentParameters: nil
          ),
          AUParameterTree.createParameter(
            withIdentifier: "volume",
            name: "Volume",
            address: EspeakParameter.volume.rawValue,
            min: 0, max: 200, unit: .percent,
            unitName: nil,
            valueStrings: nil,
            dependentParameters: nil
          ),
          AUParameterTree.createParameter(
            withIdentifier: "pitch",
            name: "Pitch",
            address: EspeakParameter.pitch.rawValue,
            min: 0, max: 100, unit: .percent,
            unitName: nil,
            valueStrings: nil,
            dependentParameters: nil
          ),
          AUParameterTree.createParameter(
            withIdentifier: "wordGap",
            name: "Word gap",
            address: EspeakParameter.wordGap.rawValue,
            min: 0, max: 500, unit: .milliseconds,
            unitName: nil,
            valueStrings: nil,
            dependentParameters: nil
          ),
          AUParameterTree.createParameter(
            withIdentifier: "range",
            name: "Inflection",
            address: EspeakParameter.range.rawValue,
            min: 0, max: 100, unit: .percent,
            unitName: nil,
            valueStrings: nil,
            dependentParameters: nil
          ),
        ]
      )
    ])
    self.parameterTree?.implementorValueProvider = { param in
      switch param.address {
      case EspeakParameter.rate.rawValue: return AUValue(container.rate ?? espeak_GetParameter(espeakRATE, 1))
      case EspeakParameter.volume.rawValue: return AUValue(container.volume ?? espeak_GetParameter(espeakVOLUME, 1))
      case EspeakParameter.pitch.rawValue: return AUValue(container.pitch ?? espeak_GetParameter(espeakPITCH, 1))
      case EspeakParameter.wordGap.rawValue: return AUValue(container.wordGap ?? espeak_GetParameter(espeakWORDGAP, 1))
      case EspeakParameter.range.rawValue: return AUValue(container.range ?? espeak_GetParameter(espeakRANGE, 1))
      default:
        log.warning("\(param, privacy: .public) => ???")
        return 0
      }
    }
    self.parameterTree?.implementorValueObserver = { param, value in
      switch param.address {
      case EspeakParameter.rate.rawValue: container.rate = Int32(value)
      case EspeakParameter.volume.rawValue: container.volume = Int32(value)
      case EspeakParameter.pitch.rawValue: container.pitch = Int32(value)
      case EspeakParameter.wordGap.rawValue: container.wordGap = Int32(value)
      case EspeakParameter.range.rawValue: container.range = Int32(value)
      default:
        log.warning("\(param, privacy: .public) => \(value, privacy: .public)")
      }
    }
    for p in self.parameterTree?.allParameters ?? [] {
      if p.unit != .indexed {
        p.value = self.parameterTree?.implementorValueProvider(p) ?? 0
      }
    }
  }

  public override var outputBusses: AUAudioUnitBusArray {
    return _outputBusses
  }

  public override func allocateRenderResources() throws {
    try super.allocateRenderResources()
  }

  private func performRender(
    actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    timestamp: UnsafePointer<AudioTimeStamp>,
    frameCount: AUAudioFrameCount,
    outputBusNumber: Int,
    outputAudioBufferList: UnsafeMutablePointer<AudioBufferList>,
    renderEvents: UnsafePointer<AURenderEvent>?,
    renderPull: AURenderPullInputBlock?
  ) -> AUAudioUnitStatus {
    let unsafeBuffer = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)
    let frames = unsafeBuffer[0].mData!.assumingMemoryBound(to: Float32.self)
    frames.assign(repeating: 0, count: Int(frameCount))

    self.outputMutex.wait()
    let count = min(self.output.count - self.outputOffset, Int(frameCount))
    self.output.withUnsafeBufferPointer { ptr in
      frames.assign(from: ptr.baseAddress!.advanced(by: self.outputOffset), count: count)
    }
    outputAudioBufferList.pointee.mBuffers.mDataByteSize = UInt32(count * MemoryLayout<Float32>.size)

    self.outputOffset += count
    if self.outputOffset >= self.output.count {
      actionFlags.pointee = .offlineUnitRenderAction_Complete
      self.output.removeAll()
      self.outputOffset = 0
    }
    self.outputMutex.signal()

    return noErr
  }

  public override var internalRenderBlock: AUInternalRenderBlock { self.performRender }

  public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
    let container = EspeakContainer.single
    let text = speechRequest.ssmlRepresentation
    let voice = speechRequest.voice.identifier
    let parts = voice.split(separator: ".")
    let voice_id = parts.last.flatMap({ String($0) })
    let lang_id: String?
    log.trace("lang query: \(parts, privacy: .public)")
    if parts.count >= 2, parts[0] == "auto" {
      let espeakLang = matchLang(container.langs, Locale.Language(identifier: String(parts[1])))
      lang_id = espeakLang?.identifier
      log.info("lang auto: \(espeakLang?.identifier ?? "<???>", privacy: .public)")
    } else {
      lang_id = parts.prefix(parts.count-1).joined(separator: "/")
      log.info("lang spec: \(lang_id ?? "<???>", privacy: .public)")
    }
    let full_voice_id = [lang_id, voice_id == emptyVoiceId ? nil : voice_id].compactMap({ $0 }).joined(separator: "+")
    log.info("synth request: \(full_voice_id, privacy: .public) \(text, privacy: .public)")
    do {
      var holder = SynthHolder()
      try withUnsafeMutablePointer(to: &holder) { ptr in
        if Self.espeakVoice != full_voice_id {
          try espeak_ng_SetVoiceByName(full_voice_id).check()
          Self.espeakVoice = full_voice_id
        }
        try container.setParams()
        try espeak_ng_Synthesize(text, text.count, 0, POS_CHARACTER, 0, UInt32(espeakSSML | espeakCHARS_UTF8), nil, ptr).check()
        try espeak_ng_Synchronize().check()
      }
      let resampled = vDSP.multiply(Float(1.0/32767.0), vDSP.integerToFloatingPoint(holder.samples, floatingPointType: Float.self))
      self.outputMutex.wait()
      self.output = resampled
      self.outputOffset = 0
      log.info("synth output: \(self.output.count) samples")
      self.outputMutex.signal()
    } catch let e {
      log.error("synth error: \(e, privacy: .public)")
    }
  }

  public override func cancelSpeechRequest() {
    self.outputMutex.wait()
    self.output.removeAll()
    self.outputOffset = 0
    log.info("stop synthesizing")
    self.outputMutex.signal()
  }

  public override func messageChannel(for channelName: String) -> AUMessageChannel {
    class MC: AUMessageChannel {
      var callHostBlock: CallHostBlock? { get { return nil } set {} }
      func callAudioUnit(_ message: [AnyHashable : Any]) -> [AnyHashable : Any] {
        let container = EspeakContainer.single
        var resp: [AnyHashable:Any] = [:]
        if message["initHost"] as? Bool == true {
          let langs = container.langs
          let voices = container.voices
          resp["langIds"] = langs.map({ $0.identifier })
          resp["langNames"] = langs.map({ $0.name })
          resp["voiceIds"] = voices.map({ $0.identifier })
          resp["voiceNames"] = voices.map({ $0.name })
          resp["voiceOverLocales"] = systemLanguages.flatMap({ $0.value }).filter({ matchLang(langs, $0) != nil }).map({ $0.universalId })
          resp["exposedLocales"] = container.exposedLocales ?? []
        }
        if let expose = message["expose"] as? [String] {
          container.exposedLocales = Set(expose).sorted()
          resp["exposedLocales"] = container.exposedLocales ?? []
        }
        return resp
      }
    }
    return MC()
  }

  public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
    get {
      let container = EspeakContainer.single
      log.info("speechVoices begin")
      var list = [AVSpeechSynthesisProviderVoice]()
      let voices = container.voices
      let langs = container.langs
      let exposed = container.exposedLocales ?? []
      log.info("exposed: \(exposed, privacy: .public)")
      for (_, langVariants) in systemLanguages {
        for langVar in langVariants.filter({ exposed.contains($0.universalId) }) {
          guard let _ = matchLang(langs, langVar) else { continue }
          let langId = langVar.universalId
          let langPath = "auto.\(langId.lowercased())"
          let localeIds = [langId] // langVariants.map({ $0.universalId })
          list.append(AVSpeechSynthesisProviderVoice(
            name: "ESpeak",
            identifier: "\(langPath).\(emptyVoiceId)",
            primaryLanguages: [langId],
            supportedLanguages: localeIds
          ))
          for voice in voices {
            let v = AVSpeechSynthesisProviderVoice(
              name: voice.name,
              identifier: "\(langPath).\(voice.identifier)",
              primaryLanguages: [langId],
              supportedLanguages: localeIds
            )
            switch UInt32(voice.gender) {
            case ENGENDER_MALE.rawValue: v.gender = .male
            case ENGENDER_FEMALE.rawValue: v.gender = .female
            default: v.gender = .unspecified
            }
            v.age = Int(voice.age)
            list.append(v)
          }
        }
      }
      log.info("speechVoices done: \(list.count)")
      return list
    }
    set { }
  }

}

