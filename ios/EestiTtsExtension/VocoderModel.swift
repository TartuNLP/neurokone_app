//
//  VocoderModel.swift
//  EestiTtsExtension
//
//  Created by Rasmus Lellep on 28.04.2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//
import os
import Foundation
import TensorFlowLite

class VocoderModel: TfLiteModel {
    func getAudio(input: Tensor) throws -> Tensor {
        try self.model.resizeInput(at: 0, to: input.shape)
        try self.model.allocateTensors()
        
        NSLog("model input shape: \(try self.model.input(at: 0).shape)")
        NSLog("model input dtype: \(try self.model.input(at: 0).dataType)")
        try self.model.copy(input.data, toInputAt: 0)
        
        // inference
        try self.model.invoke()
        
        return try self.model.output(at: 0)
        
        /*
        let output = try self.model.output(at: 0).data
        
         var audioArray = Array<Float>(repeating: 0, count: output.count/MemoryLayout<Float>.stride)
        _ = audioArray.withUnsafeMutableBytes { output.copyBytes(to: $0) }
        
        return audioArray*/
        
        /*
        let primaryInputs: [[Int32]] = [inputIds.map { Int32($0) }, [Int32(self.voice)]]
        let secondaryInputs: [[Float]] = [[self.speed], [self.pitch], [self.energy]]
        */
    }
}
