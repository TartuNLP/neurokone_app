//
//  VocoderModel.swift
//  EestiTtsMacOS
//
//  Created by Rasmus Lellep on 06.03.2024.
//

import os
import Foundation
import TensorFlowLite

class VocoderModel: TfLiteModel {
    func getAudio(input: Data) throws -> Data {
        let newShape = Tensor.Shape([1, input.count/(4*80), 80])
        if (try self.model!.input(at: 0).shape != newShape) {
            try self.model!.resizeInput(at: 0, to: newShape)
            
        }
        try self.model!.allocateTensors()
        
        try self.model!.copy(input, toInputAt: 0)
        
        // inference
        try self.model!.invoke()
        
        return try self.model!.output(at: 0).data
    }
}
