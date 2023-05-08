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
            var options = Interpreter.Options()
            //var options = InterpreterOptions()
            options.threadCount = 1
            
            // Initialize as Interpreter
            self.model = try Interpreter(modelPath: modelPath, options: options)
            logger.info("QQQInitialised model \(modelPath.split(separator: ".").last ?? "")")
            
            // Allocate memory for the input tensor
            try self.model.allocateTensors()
        } catch {
            logger.info("QQQFailed to create the interpreter with error: \(error.localizedDescription)")
            throw NSError()
        }
    }
}
