//
//  TfLiteModel.swift
//  EestiTtsExtension
//
//  Created by Rasmus Lellep on 28.04.2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import Foundation
import TensorFlowLite

class TfLiteModel {
    var model: Interpreter
    
    init(modelPath: String) throws {
        do {
            //var options = Interpreter.Options()
            //options.threadCount = 1
            
            // Initialize as Interpreter
            self.model = try Interpreter(modelPath: modelPath/*, options: options*/)
            NSLog("QQQ Initialised model \(modelPath)")
            
            // Allocate memory for the input tensor
            try self.model.allocateTensors()
        } catch {
            NSLog("QQQ Failed to create the interpreter with error: \(error.localizedDescription)")
            throw NSError()
        }
    }
}
