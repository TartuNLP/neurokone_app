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
    func getAudio(input: Data) throws -> Data {
        //try self.model.allocateTensors()
        //NSLog("QQQ voc input tensor: \(try self.model.input(at: 0))")
        //try self.model.resizeInput(at: 0, to: Tensor.Shape([1, 80, input.count/(4*80)]))
        try self.model.resizeInput(at: 0, to: Tensor.Shape([1, input.count/(4*80), 80]))
        try self.model.allocateTensors()
        
        //NSLog("QQQ voc input tensor after resize: \(try self.model.input(at: 0))")
        //NSLog("QQQ voc input dtype: \(try self.model.input(at: 0).dataType)")
        try self.model.copy(input, toInputAt: 0)
        
        // inference
        try self.model.invoke()
        
        return try self.model.output(at: 0).data
    }
}
