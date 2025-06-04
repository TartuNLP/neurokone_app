//
//  Synthesizer.swift
//  Runner
//
//  Created by Rasmus Lellep on 4/6/25.
//  Copyright © 2025 The Chromium Authors. All rights reserved.
//
import AVFoundation

class Synthesizer {
    private var synthMutex = DispatchSemaphore(value: 1)
    
    private final let preprocessor: Preprocessor = Preprocessor()
    private final let encoder: Encoder = Encoder()
    
    private var isiOS: Bool!
    private var synthesizer: FastSpeechModel!
    private var vocoder: VocoderModel!
    
    private let bytesInFrame = 4*80 //80 bins of 4-byte float values
    private let audioChunkSize = 160
    private let overlapSize = 16
    
    init(isiOS: Bool) throws {
        self.isiOS = isiOS
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
            
            if self.isiOS {
                for id in 0...synthOutput.count/(bytesInFrame*(self.audioChunkSize - self.overlapSize)) {
                    
                    var start_id = id*bytesInFrame*(self.audioChunkSize - self.overlapSize)
                    let end_id = min(synthOutput.count, bytesInFrame*((id+1)*self.audioChunkSize - id*self.overlapSize))
                    
                    var padding = Data()
                    var tempOverlapAddition = 0
                    let length = (end_id-start_id)/bytesInFrame
                    NSLog("QQQ Mel length: \(length).")
                    if length % 2 != 0 {
                        if start_id == 0 {
                            padding = Data(repeating: 0, count: bytesInFrame)
                            NSLog("QQQ Adding padding...")
                        } else {
                            NSLog("QQQ Adding overlap...")
                            start_id -= bytesInFrame
                            tempOverlapAddition = 1
                        }
                    }
                    let vocInput = synthOutput.subdata(in: start_id..<end_id) + padding
                    let vocOutput = try self.vocoder.getAudio(input: vocInput)
                    
                    let tempOverlapSize = self.overlapSize + tempOverlapAddition
                    let overlapRatio: Double = Double(bytesInFrame * tempOverlapSize) / Double(end_id - start_id)
                    if id != 0 && end_id == synthOutput.count && overlapRatio >= 1 {
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
            } else {
                var padding = Data()
                if synthOutput.count/bytesInFrame % 2 == 1 {
                    padding = Data(repeating: 0, count: bytesInFrame)
                }
                
                let vocInput = synthOutput + padding
                output = try self.vocoder.getAudio(input: vocInput)
            }

            self.vocoder.reload()
            self.synthMutex.signal()
        } catch {
            NSLog("QQQ Synthesis failed (\(ids): \(error.localizedDescription)")
        }
        return output
    }
}
