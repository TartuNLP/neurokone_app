/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that's responsible for rendering the speech the system requests.
*/

import os
import AVFoundation
import TensorFlowLite

private let appCode = "com.tartunlp.eestitts"
//let logger = Logger(subsystem: appCode, category: "SynthAudioUnit")

public class EestiTtsUnit: AVSpeechSynthesisProviderAudioUnit {
    private let langCodes: [String] = ["et-EE"];

    private let groupDefaults = UserDefaults(suiteName: "group.\(appCode)")
    
    private var request: AVSpeechSynthesisProviderRequest?
    
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    private var currentBuffer: AVAudioPCMBuffer?
    private var framePosition: AVAudioFramePosition = 0
    private var format: AVAudioFormat
    
    private var parameterObserver: NSKeyValueObservation!
    private var outputMutex = DispatchSemaphore(value: 1)
    
    private let voices = ["Mari", "Tambet", "Liivika", "Kalev", "Külli", "Meelis", "Albert", "Indrek", "Vesta", "Peeter"]
    
    private final let processor: Processor = Processor()
    private final let encoder: Encoder = Encoder()
    private var synthesizer: FastSpeechModel!
    private var vocoder: VocoderModel!
    
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
        
        self.synthesizer = try FastSpeechModel(modelPath: (groupDefaults?.value(forKey: "synthesizer") as? String)!)
        self.vocoder = try VocoderModel(modelPath: (groupDefaults?.value(forKey: "vocoder") as? String)!)
    }

    // MARK: - Public Properties

    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            //let langs: [String] = (groupDefaults?.value(forKey: "langs") as? [String])!
            let voices: [String] = (groupDefaults?.value(forKey: "voices") as? [String])!
            return voices.map { voice in
                return AVSpeechSynthesisProviderVoice(name: voice,
                                                      identifier: "auto.\(langCodes[0].lowercased()).\(voice)",
                                                      primaryLanguages: langCodes,
                                                      supportedLanguages: langCodes)
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

        self.outputMutex.wait()

        // Get the frames from the current buffer that represents the SSML.
        let sourceBuffer = UnsafeMutableAudioBufferListPointer(self.currentBuffer!.mutableAudioBufferList)[0]
        let sourceFrames = sourceBuffer.mData!.assumingMemoryBound(to: Float32.self)

        // Iterate through the requested number of frames.
        for frame in 0..<frameCount {
            // Copy the source frames into the target buffer.
            frames[Int(frame)] = sourceFrames[Int(self.framePosition)]
            self.framePosition += 1
            // Complete the request if the frame position exceeds the available buffer.
            if self.framePosition >= self.currentBuffer!.frameLength {
                actionFlags.pointee = .offlineUnitRenderAction_Complete
                break
            }
        }

        outputAudioBufferList.pointee.mBuffers.mDataByteSize = UInt32(Int(self.framePosition) * MemoryLayout<Float32>.size)
        self.outputMutex.signal()

        return noErr
    }

    public override var internalRenderBlock: AUInternalRenderBlock { self.performRender }
    
    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        NSLog("QQQ request: \(speechRequest)")

        let text: String = speechRequest.ssmlRepresentation
        let voice: AVSpeechSynthesisProviderVoice = speechRequest.voice
        NSLog("QQQ ssml text: \(text)")
        NSLog("QQQ ssml voice: \(voice)")

        self.outputMutex.wait()
        
        request = speechRequest
        synthesizer.setVoice(voice: voices.firstIndex(of: voice.name)!)
        
        let sentences = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).split(separator: " . ")
        //let sentences = processor.splitSentences(text: text)
        NSLog("QQQ sentences: \(sentences)")
        for sentence in sentences {
            let ids: [Int] = encoder.textToIds(text: String(sentence))
            //let ids: [Int] = encoder.textToIds(text: sentence)
            NSLog("QQQ ids: \(ids)")
            do {
                let spectrogram: Tensor = try self.synthesizer.getMelSpectrogram(inputIds: ids)
                NSLog("QQQ spectrogram: \(spectrogram)")
                let audioDataTensor: Tensor = try self.vocoder.getAudio(input: spectrogram)
                NSLog("QQQ audio: \(audioDataTensor)")
                let audioInt16Data: Data = convertFloatDataToShortData(floatData: audioDataTensor.data)
                let audioFilePath: String = saveAudio(audioData: audioInt16Data)
                currentBuffer = getAudioBufferForSSML(audioFilePath)
            } catch {
                NSLog("QQQ inference failed: \(error.localizedDescription)")
            }
        }
        
        framePosition = 0
        self.outputMutex.signal()
    }
    
    func convertFloatDataToShortData(floatData: Data) -> Data {
        var floatArray = Array<Float>(repeating: 0, count: floatData.count/MemoryLayout<Float>.stride)
        _ = floatArray.withUnsafeMutableBytes { floatData.copyBytes(to: $0) }
        
        let int16Array: [Int16] = floatArray.map { Int16(round($0 * 32768))}
        return int16Array.withUnsafeBufferPointer(Data.init)
    }
    
    func saveAudio(audioData: Data) -> String {
        return try! ARFileManager().createWavFile(using: audioData).absoluteString
    }
    
    public override func cancelSpeechRequest() {
        self.outputMutex.wait()
        request = nil
        self.outputMutex.signal()
    }
    
    func getAudioBufferForSSML(_ filePath: String) -> AVAudioPCMBuffer? {
        //let audioFileName = filePath.hasPrefix("goodbye") ? "goodbye" : "hello"
        //guard let fileUrl = Bundle.main.url(forResource: audioFileName, withExtension: "aiff") else { return nil }
        //guard let fileUrl = Bundle.main.url(forResource: filePath, withExtension: "wav") else { return nil }
        let fileUrl = URL(string: filePath)!
        NSLog("QQQ audio file url: \(fileUrl.description)")
        
        do {
            let file = try AVAudioFile(forReading: fileUrl)
            let buffer = AVAudioPCMBuffer(pcmFormat: self.format,
                                          frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
            return buffer
        } catch {
            NSLog("QQQ audio playing failed: \(error.localizedDescription)")
            return nil
        }
    }
}

//MARK: Logic for Creating Audio file

class ARFileManager {

      static let shared = ARFileManager()
      let fileManager = FileManager.default

      var documentDirectoryURL: URL? {
          return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      }

      func createWavFile(using rawData: Data) throws -> URL {
           //Prepare Wav file header
           let waveHeaderFormate = createWaveHeader(data: rawData) as Data

           //Prepare Final Wav File Data
           let waveFileData = waveHeaderFormate + rawData

           //Store Wav file in document directory.
           return try storeMusicFile(data: waveFileData)
       }

       private func createWaveHeader(data: Data) -> NSData {

            let sampleRate: Int32 = 22050
            let chunkSize: Int32 = 36 + Int32(data.count)
            let subChunkSize: Int32 = 16
            let format: Int16 = 1
            let channels: Int16 = 1
            let bitsPerSample: Int16 = 16
            let byteRate: Int32 = sampleRate * Int32(channels * bitsPerSample / 8)
            let blockAlign: Int16 = channels * bitsPerSample / 8
            let dataSize: Int32 = Int32(data.count)

            let header = NSMutableData()

            header.append([UInt8]("RIFF".utf8), length: 4)
            header.append(intToByteArray(chunkSize), length: 4)

            //WAVE
            header.append([UInt8]("WAVE".utf8), length: 4)

            //FMT
            header.append([UInt8]("fmt ".utf8), length: 4)

            header.append(intToByteArray(subChunkSize), length: 4)
            header.append(shortToByteArray(format), length: 2)
            header.append(shortToByteArray(channels), length: 2)
            header.append(intToByteArray(sampleRate), length: 4)
            header.append(intToByteArray(byteRate), length: 4)
            header.append(shortToByteArray(blockAlign), length: 2)
            header.append(shortToByteArray(bitsPerSample), length: 2)

            header.append([UInt8]("data".utf8), length: 4)
            header.append(intToByteArray(dataSize), length: 4)

            return header
       }

      private func intToByteArray(_ i: Int32) -> [UInt8] {
            return [
              //little endian
              UInt8(truncatingIfNeeded: (i      ) & 0xff),
              UInt8(truncatingIfNeeded: (i >>  8) & 0xff),
              UInt8(truncatingIfNeeded: (i >> 16) & 0xff),
              UInt8(truncatingIfNeeded: (i >> 24) & 0xff)
             ]
       }

       private func shortToByteArray(_ i: Int16) -> [UInt8] {
              return [
                  //little endian
                  UInt8(truncatingIfNeeded: (i      ) & 0xff),
                  UInt8(truncatingIfNeeded: (i >>  8) & 0xff)
              ]
        }

       func storeMusicFile(data: Data) throws -> URL {

           let fileName = "Record \(Date().description)"

             guard documentDirectoryURL != nil else {
                debugPrint("Error: Failed to fetch mediaDirectoryURL")
                //throw ARError(localizedDescription:             AlertMessage.medioDirectoryPathNotAvaiable)
                 throw AVError(_nsError: NSError())
              }

             let filePath = documentDirectoryURL!.appendingPathComponent("\(fileName).wav")
              debugPrint("File Path: \(filePath.path)")
              try data.write(to: filePath)

             return filePath //Save file's path respected to document directory.
        }
 }
