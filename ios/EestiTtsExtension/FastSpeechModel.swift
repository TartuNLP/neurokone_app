//
//  FastSpeechModel.swift
//  EestiTtsExtension
//
//  Created by Rasmus Lellep on 28.04.2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//
import os
import Foundation
import TensorFlowLite

class FastSpeechModel: TfLiteModel {
    private var voice: Int = 0;
    private var speed: Float = 1.0; //0.1 - 6
    private var pitch: Float = 1.0; //0.25 - 4
    private var energy: Float = 1.0;
    
    func setVoice(voice: Int) {
        self.voice = voice;
    }

    func setSpeed(speed: Float) {
        self.speed = 1.0 / speed;  //speed input is actually the audio length multiplier so the faster the speech, the lower value the input
    }

    func setPitch(pitch: Float) { self.pitch = pitch; }

    func setEnergy(energy: Float) { self.energy = energy; }
    
    func getMelSpectrogram(inputIds: [Int]) throws -> Data {
        try self.model.allocateTensors()
        let primaryInputs: [[Int32]] = [inputIds.map { Int32($0) }, [Int32(self.voice)]]
        let secondaryInputs: [[Float]] = [[self.speed], [self.pitch], [self.energy]]
        
        try self.model.resizeInput(at: 0, to: Tensor.Shape([1, inputIds.count]))
        for id in 1..<primaryInputs.count {
            try self.model.resizeInput(at: id, to: Tensor.Shape([primaryInputs[id].count]))
        }
        for id in 0..<secondaryInputs.count {
            try self.model.resizeInput(at: id+primaryInputs.count, to: Tensor.Shape([secondaryInputs[id].count]))
        }
        //NSLog("QQQ inputs resized")
        
        try self.model.allocateTensors()
        
        for id in 0..<primaryInputs.count {
            let dataIn = primaryInputs[id].withUnsafeBufferPointer(Data.init)
            try self.model.copy(dataIn, toInputAt: id)
        }
        for id in 0..<secondaryInputs.count {
            let dataIn = secondaryInputs[id].withUnsafeBufferPointer(Data.init)
            try self.model.copy(dataIn, toInputAt: id+primaryInputs.count)
        }
        //NSLog("QQQ input prepared")
        
        // inference
        try self.model.invoke()
        //NSLog("QQQ model invoked")
        
        for id in 0..<self.model.outputTensorCount {
            NSLog("QQQ synth output \(id), tensor: \(try self.model.output(at: id))")
        }
        
        return try self.model.output(at: 0).data
    }
}
