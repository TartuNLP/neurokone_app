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

    func getMelSpectrogram(inputIds: [Int]) throws -> Tensor {
        logger.info("input id length: \(inputIds.count)");
        try self.model.resizeInput(at: 0, to: [inputIds.count]);
        try self.model.allocateTensors();
        
        let allInputs = [[inputIds], [self.voice], [self.speed], [self.pitch], [self.energy]]
        for id in 0..<allInputs.count {
            let dataIn = Data(allInputs[id] as? Array ?? [])
            try model.copy(dataIn, toInputAt: id)
        }
        
        // inference
        try model.invoke()
        
        return try model.output(at: 0)
        
        /*
        Map<Integer, Object> outputMap = new HashMap<>();
        FloatBuffer outputBuffer = FloatBuffer.allocate(350000);
        outputMap.put(0, outputBuffer);

        int[][] inputs = new int[1][inputIds.length];
        inputs[0] = inputIds;

        Object[] input = new Object[]{inputs, new int[]{voice}, new float[]{speed}, new float[]{pitch}, new float[]{energy}};
        long time = System.currentTimeMillis();
        self.model.runForMultipleInputsOutputs(input, outputMap);
        Log.d(TAG, "time cost: " + (System.currentTimeMillis() - time));
        Log.i(TAG, "Spectrogram shape: " + Arrays.toString(self.model.getOutputTensor(0).shape()));

        int size = self.model.getOutputTensor(0).shape()[2];
        int[] shape = {1, outputBuffer.position() / size, size};
        TensorBuffer spectrogram = TensorBuffer.createFixedSize(shape, DataType.FLOAT32);
        float[] outputArray = new float[outputBuffer.position()];
        outputBuffer.rewind();
        outputBuffer.get(outputArray);
        spectrogram.loadArray(outputArray);

        return spectrogram;
        */
    }
}
