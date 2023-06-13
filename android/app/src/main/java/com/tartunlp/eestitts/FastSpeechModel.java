package com.tartunlp.eestitts;

import android.annotation.SuppressLint;
import android.util.Log;

import org.tensorflow.lite.DataType;
import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;

import java.io.File;
import java.nio.FloatBuffer;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class FastSpeechModel {
    private final String TAG = "FastSpeech2";
    private final Interpreter model;

    private int voice = 0;
    private float speed = 1.0f; //0.1 - 6
    private float pitch = 1.0f; //0.25 - 4
    private float energy = 1.0f;

    public FastSpeechModel(String path) {
        model = new Interpreter(new File(path));
    }

    public void setVoice(int voice) {
        this.voice = voice;
    }

    public void setSpeed(float speed) {
        this.speed = 1.0f / speed;  //speed input is actually the audio length multiplier so the faster the speech, the lower value the input
    }

    public void setPitch(float pitch) { this.pitch = pitch; }

    public void setEnergy(float energy) { this.energy = energy; }

    public TensorBuffer getMelSpectrogram(int[] inputIds) {
        Log.d(TAG, "input id length: " + inputIds.length);
        model.resizeInput(0, new int[]{1, inputIds.length});
        model.allocateTensors();

        @SuppressLint("UseSparseArrays")
        Map<Integer, Object> outputMap = new HashMap<>();
        FloatBuffer outputBuffer = FloatBuffer.allocate(350000);
        outputMap.put(0, outputBuffer);

        int[][] inputs = new int[1][inputIds.length];
        inputs[0] = inputIds;

        Object[] input = new Object[]{inputs, new int[]{voice}, new float[]{speed}, new float[]{pitch}, new float[]{energy}};
        long time = System.currentTimeMillis();
        model.runForMultipleInputsOutputs(input, outputMap);
        Log.d(TAG, "time cost: " + (System.currentTimeMillis() - time));
        Log.i(TAG, "Spectrogram shape: " + Arrays.toString(model.getOutputTensor(0).shape()));

        int size = model.getOutputTensor(0).shape()[2];
        int[] shape = {1, outputBuffer.position() / size, size};
        TensorBuffer spectrogram = TensorBuffer.createFixedSize(shape, DataType.FLOAT32);
        float[] outputArray = new float[outputBuffer.position()];
        outputBuffer.rewind();
        outputBuffer.get(outputArray);
        spectrogram.loadArray(outputArray);

        return spectrogram;
    }
}
