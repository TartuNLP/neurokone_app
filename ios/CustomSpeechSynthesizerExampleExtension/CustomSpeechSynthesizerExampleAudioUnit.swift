/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that's responsible for rendering the speech the system requests.
*/

import AVFoundation

public class CustomSpeechSynthesizerExampleAudioUnit: AVSpeechSynthesisProviderAudioUnit {
    
    // MARK: - Private Properties

    private let groupDefaults = UserDefaults(suiteName: "group.com.example.apple.samplecode.CustomSpeechSynthesizerExample")
    
    private var request: AVSpeechSynthesisProviderRequest?
    
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    private var currentBuffer: AVAudioPCMBuffer?
    private var framePosition: AVAudioFramePosition = 0
    private var format: AVAudioFormat
        
    // MARK: - Lifecycle
    
    @objc
    override init(componentDescription: AudioComponentDescription,
                  options: AudioComponentInstantiationOptions) throws {
        
        let basicDescription = AudioStreamBasicDescription(mSampleRate: 22_050,
                                                           mFormatID: kAudioFormatLinearPCM,
                                                           mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
                                                           mBytesPerPacket: 4,
                                                           mFramesPerPacket: 1,
                                                           mBytesPerFrame: 4,
                                                           mChannelsPerFrame: 1,
                                                           mBitsPerChannel: 32,
                                                           mReserved: 0)
        
        format = AVAudioFormat(cmAudioFormatDescription: try! CMAudioFormatDescription(audioStreamBasicDescription: basicDescription))
        outputBus = try AUAudioUnitBus(format: self.format)
        
        try super.init(componentDescription: componentDescription,
                       options: options)
        
        _outputBusses = AUAudioUnitBusArray(audioUnit: self,
                                            busType: AUAudioUnitBusType.output,
                                            busses: [outputBus])
        
    }
    
    // MARK: - Public Properties
    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            let voices: [String] = (groupDefaults?.value(forKey: "voices") as? [String]) ?? []
            return voices.map { voice in
                return AVSpeechSynthesisProviderVoice(name: voice,
                                                      identifier: "com.identifier.\(voice)",
                                                      primaryLanguages: ["en-US"],
                                                      supportedLanguages: ["en-US"])
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
    
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { actionFlags, timestamp, frameCount, outputBusNumber, outputAudioBufferList, _, _ in
            
            // The audio buffer to fill with data to return to the system
            let unsafeBuffer = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)[0]
            let frames = unsafeBuffer.mData!.assumingMemoryBound(to: Float32.self)
            
            // Get the frames from the current buffer that represents the SSML.
            let sourceBuffer = UnsafeMutableAudioBufferListPointer(self.currentBuffer!.mutableAudioBufferList)[0]
            let sourceFrames = sourceBuffer.mData!.assumingMemoryBound(to: Float32.self)

            // Clear the target buffer.
            for frame in 0..<frameCount {
                frames[Int(frame)] = 0.0
            }
            
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
            return noErr
        }
    }
    
    // MARK: - Public Methods
    
    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        request = speechRequest
        currentBuffer = getAudioBufferForSSML(speechRequest.ssmlRepresentation)
        framePosition = 0
    }
    
    public override func cancelSpeechRequest() {
        request = nil
    }
    
    func getAudioBufferForSSML(_ ssml: String) -> AVAudioPCMBuffer? {
        let audioFileName = ssml.contains("goodbye") ? "goodbye" : "hello"
        guard let fileUrl = Bundle.main.url(forResource: audioFileName,
                                            withExtension: "aiff") else {
            return nil
        }
        
        do {
            let file = try AVAudioFile(forReading: fileUrl)
            let buffer = AVAudioPCMBuffer(pcmFormat: self.format,
                                          frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
            return buffer
        } catch {
            return nil
        }
    }
}

