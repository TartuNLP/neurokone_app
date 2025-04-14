/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that's responsible for rendering the speech the system requests.
*/

import os
import AVFoundation

public class EestiTtsUnit: AVSpeechSynthesisProviderAudioUnit {
    private var request: AVSpeechSynthesisProviderRequest?
    
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    
    private var framePosition: AVAudioFramePosition = 0
    private var format: AVAudioFormat
    
    private var parameterObserver: NSKeyValueObservation!
    private var outputMutex = DispatchSemaphore(value: 1)
    
    private let langCode: String = "et-EE"
    private let voices = ["Mari", "Tambet", "Liivika", "Kalev", "Külli", "Meelis", "Albert", "Indrek", "Vesta", "Peeter"]
    
    private final let sentprocessor: SentProcessor = SentProcessor()
    private var synthesizer: Synthesizer!
    private var sentIdDone = 0
    private var sentIdRendered = 0
    private var isSynthDone = true
    private var allData: [Data] = []
    private var currentData: Data?
    private var volume: Float = 1.0
    
    @objc
    override init(componentDescription: AudioComponentDescription,
            options: AudioComponentInstantiationOptions) throws {
        
        let basicDescription = AudioStreamBasicDescription(
            mSampleRate: 22_050,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 32,
            mReserved: 0
        )
        format = AVAudioFormat(
            cmAudioFormatDescription: try! CMAudioFormatDescription(
                audioStreamBasicDescription: basicDescription
            )
        )
        outputBus = try AUAudioUnitBus(format: self.format)
        try super.init(componentDescription: componentDescription, options: options)
        
        _outputBusses = AUAudioUnitBusArray(
            audioUnit: self,
            busType: AUAudioUnitBusType.output,
            busses: [outputBus]
        )

        AVSpeechSynthesisVoice.speechVoices()
        self.synthesizer = try Synthesizer()
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
    }

    // MARK: - Public Properties

    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            return self.voices.map { voice in
                return AVSpeechSynthesisProviderVoice(name: voice,
                                                      identifier: "auto.\(langCode.lowercased()).\(voice)",
                                                      primaryLanguages: [langCode],
                                                      supportedLanguages: [langCode])
            }
        }
        set { }
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
        // The audio buffer to fill with data to return to the system
        let unsafeBuffer = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)[0]
        let frames = unsafeBuffer.mData!.assumingMemoryBound(to: Float32.self)

        // Clear the target buffer.
        frames.update(repeating: 0, count: Int(frameCount))
        
        if self.framePosition == 0 {
            while self.allData.isEmpty {
                usleep(1000)
            }
            NSLog("QQQ stopped for render, trying new sentence")
            self.outputMutex.wait()
            self.currentData = self.allData.popLast()
            self.outputMutex.signal()
        }
        
        guard let audioData = self.currentData else {
            // Handle the case when rawAudioData is nil
            return kAudioUnitErr_Uninitialized
        }

        let floatData = audioData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            return ptr.baseAddress?.assumingMemoryBound(to: Float32.self)
        }
        
        guard let sourceFrames = floatData else {
            // Handle the case when conversion to UnsafeMutablePointer<Float32> fails
            return kAudioUnitErr_InvalidPropertyValue
        }
        
        if self.framePosition == 0 {
            NSLog("QQQ starting to render sentence..")
        }

        // Iterate through the requested number of frames.
        for frame in 0..<frameCount {
            // Copy the source frames into the target buffer.
            frames[Int(frame)] = sourceFrames[Int(self.framePosition)] * volume
            self.framePosition += 1
            // Complete the request if the frame position exceeds the available buffer.
            if self.framePosition >= audioData.count / MemoryLayout<Float32>.size {
                NSLog("QQQ sentence rendered, length: \(self.framePosition)")
                self.currentData = nil
                self.framePosition = 0
                self.sentIdRendered += 1
                if self.isSynthDone && self.allData.isEmpty {
                    actionFlags.pointee = .offlineUnitRenderAction_Complete
                }
                NSLog("QQQ checked if was last sent")
                break
            }
        }

        outputAudioBufferList.pointee.mBuffers.mDataByteSize = UInt32(Int(self.framePosition) * MemoryLayout<Float32>.size)
        return noErr
    }

    public override var internalRenderBlock: AUInternalRenderBlock { self.performRender }
    
    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        NSLog("QQQQ request: \(speechRequest)")

        let text: String = speechRequest.ssmlRepresentation
        let voice: AVSpeechSynthesisProviderVoice = speechRequest.voice

        self.outputMutex.wait()
        
        self.request = speechRequest
        self.synthesizer.setVoice(voice: voices.firstIndex(of: voice.name)!)
        self.setProsody(ssml: text)
        
        var sentences = [] as [String]
        if let match = text.firstMatch(of: /\<say-as interpret-as=\"characters\"\>(.*?)\<\/say-as\>/) {
            sentences = [String(match.output.1.split(separator: "").joined(separator: "-"))]
        }
        else {
            sentences = sentprocessor.splitSentences(speaker: voice.name, input_text: text)
        }
        NSLog("QQQ sentences: \(sentences)")

        self.sentIdDone = 0
        self.sentIdRendered = 0
        self.isSynthDone = false
        
        var sentId = 1
        for sentence in sentences {
            let currentId = sentId
            Task.init {
                await synthesizeSentence(sentence: sentence, current: currentId, totalSents: sentences.count)
            }
            sentId += 1
        }
        
        self.outputMutex.signal()
    }
    
    private func setProsody(ssml: String) {
        NSLog("QQQ ssml: \(ssml)")
        if let prosody_text = ssml.firstMatch(of: /\<prosody (.*?)\>/) {
            var text = prosody_text.output.1
            while let match = text.firstMatch(of: /([a-z]+)="(.*?)"/) {
                let current_key = match.output.1
                let current_value = match.output.2
                switch current_key {
                    case "rate":
                        self.synthesizer.setSpeed(speed: (current_value as NSString).floatValue/100)
                    case "pitch":
                        self.synthesizer.setPitch(pitch: (current_value as NSString).floatValue/100 + 1)
                    case "volume":
                        switch current_value {
                        case "silent":
                            self.volume = 0
                        case "+0.0dB":
                            self.volume = 1.0
                        default:
                            self.volume = pow(10, (current_value.replacingOccurrences(of: "dB", with: "") as NSString).floatValue/10)
                        }
                    default:
                        break
                }
                text = text[match.range.upperBound...]
            }
        } else {
            self.synthesizer.setSpeed(speed: 1)
            self.synthesizer.setPitch(pitch: 1)
            self.volume = 1.0
        }
    }
    
    private func synthesizeSentence(sentence: String, current: Int, totalSents: Int) async {
        usleep(1000)
        while sentIdDone < current - 1 {
            usleep(10000)
        }
        let sentData = self.synthesizer.synthesizeSentence(sentence: sentence)
        self.allData.insert(sentData, at: 0)
        self.sentIdDone = current
        NSLog("QQQ sentence done, size \(sentData.count)")
        if current == totalSents {
            NSLog("QQQ synth done")
            self.isSynthDone = true
        }
    }
    
    public override func cancelSpeechRequest() {
        self.outputMutex.wait()
        self.framePosition = 0
        request = nil
        self.outputMutex.signal()
    }
}

class Synthesizer {
    private var synthMutex = DispatchSemaphore(value: 1)
    
    private final let preprocessor: Preprocessor = Preprocessor()
    private final let encoder: Encoder = Encoder()
    
    private var synthesizer: FastSpeechModel!
    private var vocoder: VocoderModel!
    
    private let bytesInFrame = 4*80 //80 bins of 4-byte float values
    private let audioChunkSize = 160
    private let overlapSize = 16

    private var volume: Float = 1.0
    
    init() throws { 
        self.synthesizer = try FastSpeechModel(modelPath: Bundle.main.path(forResource: "fastspeech2-est", ofType: "tflite")!)
        self.vocoder = try VocoderModel(modelPath: Bundle.main.path(forResource: "hifigan-est.v2", ofType: "tflite")!)
    }
    
    func setVoice(voice: Int) {
        self.synthesizer.setVoice(voice: voice)
    }
    
    func setSpeed(speed: Float) {
        self.synthesizer.setSpeed(speed: speed)
    }

    func setPitch(pitch: Float) {
        self.synthesizer.setPitch(pitch: pitch)
    }
    
    func synthesizeSentence(sentence: String) -> Data {
        let processedSentence = preprocessor.processSentence(sentence.replacingOccurrences(of: "\n", with: ""))
        let ids: [Int] = encoder.textToIds(text: processedSentence)
        var output = Data()
        do {
            self.synthMutex.wait()
            
            let synthOutput: Data = try self.synthesizer.getMelSpectrogram(inputIds: ids)
            self.synthesizer.reload()
            
            for id in 0...synthOutput.count/(bytesInFrame*(self.audioChunkSize - self.overlapSize)) {
                
                var start_id = id*bytesInFrame*(self.audioChunkSize - self.overlapSize)
                let end_id = min(synthOutput.count, bytesInFrame*((id+1)*self.audioChunkSize - id*self.overlapSize))
                
                var padding = Data()
                var tempOverlapAddition = 0
                let length = (end_id-start_id)/bytesInFrame
                NSLog("QQQ part is of length \(length).")
                if (length % 2 != 0) {
                    NSLog("QQQ adding padding or overlap...")
                    if (start_id == 0) {
                        padding = Data(repeating: 0, count: bytesInFrame)
                    } else {
                        start_id -= bytesInFrame
                        tempOverlapAddition = 1
                    }
                }
                let vocInput = synthOutput.subdata(in: start_id..<end_id) + padding
                let vocOutput = try self.vocoder.getAudio(input: vocInput)
                
                let tempOverlapSize = self.overlapSize + tempOverlapAddition
                let overlapRatio: Double = Double(bytesInFrame * tempOverlapSize) / Double(end_id - start_id)
                if end_id == synthOutput.count && overlapRatio >= 1 {
                    break
                }
                let numValuesCut = Int(ceil(Double(vocOutput.count)*overlapRatio/2.0))
                let clip_start = start_id == 0 ? 0 : numValuesCut
                let clip_end = end_id == synthOutput.count ? vocOutput.count : vocOutput.count - numValuesCut
                
                output += vocOutput.subdata(in: clip_start..<clip_end)
                if end_id == synthOutput.count {
                    break
                }
            }
            self.vocoder.reload()
            
            self.synthMutex.signal()
        } catch {
            NSLog("QQQ inference failed (\(ids): \(error.localizedDescription)")
        }
        return output
    }
}
