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
    func getAudio(input: Tensor) throws -> [Float] {
        try self.model.resizeInput(at: 0, to: input.shape)
        try self.model.allocateTensors()

        //var outputBuffer: FloatBuffer = FloatBuffer.allocate(350000)

        //var time = System.currentTimeMillis();
        let dataIn = Data(input as? Array ?? [])
        // Data to Tensor.
        try model.copy(dataIn, toInputAt: 0)
        // inference
        try model.invoke()
        
        let output = try model.output(at: 0).data
        
        var arr2 = Array<Float>(repeating: 0, count: output.count/MemoryLayout<Float>.stride)
        _ = arr2.withUnsafeMutableBytes { output.copyBytes(to: $0) }
        
        return arr2
    }
}
