/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that's responsible for rendering the speech the system requests.
*/

import os
import AVFoundation

public class EestiTtsUnit: AVSpeechSynthesisProviderAudioUnit {
    private let langCodes: [String] = ["et-EE"]

    private let groupDefaults = UserDefaults(suiteName: "group.com.tartunlp.eestitts")
    
    private var request: AVSpeechSynthesisProviderRequest?
    
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    private var currentBuffer: AVAudioPCMBuffer?
    private var framePosition: AVAudioFramePosition = 0
    private var format: AVAudioFormat
    //private var output: [Int16] = []
    //private var outputOffset: Int = 0
    
    private var parameterObserver: NSKeyValueObservation!
    private var outputMutex = DispatchSemaphore(value: 1)
    
    private let voices = ["Mari", "Tambet", "Liivika", "Kalev", "Külli", "Meelis", "Albert", "Indrek", "Vesta", "Peeter"]
    
    private final let processor: Processor = Processor()
    private final let encoder: Encoder = Encoder()
    private var synthesizer: FastSpeechModel!
    private var vocoder: VocoderModel!
    
    private let filemanager = ARFileManager()
    
    
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
        
        /*
        let count = min(self.output.count - self.outputOffset, Int(frameCount))
        self.output.withUnsafeBufferPointer { ptr in
          frames.update(from: ptr.baseAddress!.advanced(by: self.outputOffset), count: count)
        }
        outputAudioBufferList.pointee.mBuffers.mDataByteSize = UInt32(count * MemoryLayout<Float32>.size)

        self.outputOffset += count
        if self.outputOffset >= self.output.count {
          actionFlags.pointee = .offlineUnitRenderAction_Complete
          self.output.removeAll()
          self.outputOffset = 0
        }*/

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
    
    func floatDataToArray(_ floatData: Data) -> [Float] {
        var floatArray = Array<Float>(repeating: 0, count: floatData.count/MemoryLayout<Float>.stride)
        _ = floatArray.withUnsafeMutableBytes { floatData.copyBytes(to: $0) }
        return floatArray
    }
    
    func toShortArray(_ floatArray: [Float]) -> [Int16] {
        return floatArray.map { Int16(round($0 * 32768))}
    }
    
    func arrayToData(_ array: [Int16]) -> Data {
        return array.withUnsafeBufferPointer(Data.init)
    }
    
    func saveAudio(_ audioData: Data) -> String {
        return try! filemanager.createWavFile(using: audioData).absoluteString
    }
    
    public override func cancelSpeechRequest() {
        self.outputMutex.wait()
        self.framePosition = 0
        request = nil
        self.outputMutex.signal()
    }
    
    func getAudioBufferForSSML(_ filePath: String) -> AVAudioPCMBuffer? {
        let fileUrl = URL(string: filePath)!
        NSLog("QQQ audio file url: \(fileUrl.description)")
        var fileSize: Double = 0.0
        fileSize = try! (fileUrl.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
        fileSize = (fileSize / (1024 * 1024))
        NSLog("QQQ audio file size: \(fileSize) MB")
        
        /*
        do {
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: false)!  // given NSData audio format
            guard let PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(shortData.count) / audioFormat.streamDescription.pointee.mBytesPerFrame) else {
                return nil
            }
            PCMBuffer.frameLength = PCMBuffer.frameCapacity
            let channels = UnsafeBufferPointer(start: PCMBuffer.int16ChannelData, count: Int(PCMBuffer.format.channelCount))
            (shortData as NSData).getBytes(UnsafeMutableRawPointer(channels[0]) , length: shortData.count)
            return PCMBuffer
        }*/
        
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
    
    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        let audioChunkSize = 4*80*50
        NSLog("QQQ request: \(speechRequest)")

        let text: String = speechRequest.ssmlRepresentation
        let voice: AVSpeechSynthesisProviderVoice = speechRequest.voice
        NSLog("QQQ ssml text: \(text)")
        NSLog("QQQ ssml voice: \(voice)")

        self.outputMutex.wait()
        
        request = speechRequest
        synthesizer.setVoice(voice: voices.firstIndex(of: voice.name)!)
        
        //let sentences = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).split(separator: " . ")
        let sentences = processor.splitSentences(text: text)
        NSLog("QQQ sentences: \(sentences)")
        var audioData = Data()
        for sentence in sentences {
            let ids: [Int] = encoder.textToIds(text: String(sentence))
            //let ids: [Int] = encoder.textToIds(text: sentence)
            NSLog("QQQ ids: \(ids)")
            do {
                let synthOutput: Data = try self.synthesizer.getMelSpectrogram(inputIds: ids)
                self.synthesizer.reload()
                NSLog("QQQ spectrogram: \(synthOutput)")
                
                for id in 0...synthOutput.count/audioChunkSize {
                    NSLog("QQQ part \(id+1)")
                    let vocOutput = try self.vocoder.getAudio(input: synthOutput.subdata(in: audioChunkSize*id..<min(synthOutput.count, audioChunkSize*(id+1))))
                    self.vocoder.reload()
                    NSLog("QQQ part of audio: \(vocOutput)")
                    audioData += vocOutput
                    //let floatArray: [Float] = floatDataToArray(modelOutput)
                    //let int16Data: [Int16] = toShortArray(floatArray)
                }
            } catch {
                NSLog("QQQ inference failed: \(error.localizedDescription)")
            }
            //Silence between sentences
            audioData += Data(repeating: 0, count: 160)
        }
        NSLog("QQQ whole in audio: \(audioData)")
        //let audioFilePath: String = saveAudio(arrayToData(int16Data))
        let audioFilePath: String = saveAudio(arrayToData(toShortArray(floatDataToArray(audioData))))
        currentBuffer = getAudioBufferForSSML(audioFilePath)
        
        self.framePosition = 0
        self.outputMutex.signal()
    }
}

//MARK: Logic for Creating Audio file

class ARFileManager {

    var documentDirectoryURL: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        //return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func createWavFile(using rawData: Data) throws -> URL {
        //Prepare Wav file header
        let waveHeaderFormate = createWaveHeader(dataLen: rawData.count) as Data

        //Prepare Final Wav File Data
        let waveFileData = waveHeaderFormate + rawData

        //Store Wav file in document directory.
        return try storeMusicFile(data: waveFileData)
    }

    private func createWaveHeader(dataLen: Int) -> NSData {
        let sampleRate: Int32 = 22050
        let chunkSize: Int32 = 36 + Int32(dataLen)
        let subChunkSize: Int32 = 16
        let format: Int16 = 1
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate: Int32 = sampleRate * Int32(channels * bitsPerSample / 8)
        let blockAlign: Int16 = channels * bitsPerSample / 8
        let dataSize: Int32 = Int32(dataLen)

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
            NSLog("Error: Failed to fetch mediaDirectoryURL")
            throw AVError(_nsError: NSError())
        }
        let filePath = documentDirectoryURL!.appendingPathComponent("\(fileName).wav")
        debugPrint("File Path: \(filePath.path)")
        try data.write(to: filePath)

        return filePath //Save file's path to directory.
    }
 }
