//
//  TfLiteModel.swift
//  EestiTtsMacOS
//
//  Created by Rasmus Lellep on 06.03.2024.
//

import Foundation
import TensorFlowLite

class TfLiteModel {
    let modelPath: String
    var model: Interpreter?
    
    init(modelPath: String) throws {
        self.modelPath = modelPath
        do {
            //var options = Interpreter.Options()
            //options.threadCount = 1
            
            // Initialize as Interpreter
            self.model = try Interpreter(modelPath: modelPath/*, options: options*/)
            NSLog("QQQ Initialised model \(modelPath)")
            
            // Allocate memory for the input tensor
            try self.model!.allocateTensors()
        } catch {
            NSLog("QQQ Failed to create the interpreter with error: \(error.localizedDescription)")
            throw NSError()
        }
    }

    func reload() {
        self.model = try! Interpreter(modelPath: modelPath/*, options: options*/)
        try! self.model!.allocateTensors()
    }
        
    func remove() {
        self.model = nil
    }
}
