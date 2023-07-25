package com.tartunlp.neurokone;

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
        this.model = new Interpreter(new File(path));
    }

    public void setVoice(int voice) {
        this.voice = voice;
    }

    public void setSpeed(float speed) {
        this.speed = 1.0f / speed;  //speed input is actually the audio length multiplier so the faster the speech, the lower value the input
    }

    public void setPitch(float pitch) { this.pitch = pitch; }

    public void setEnergy(float energy) { this.energy = energy; }

    public synchronized TensorBuffer getMelSpectrogram(int[] inputIds) {
        Log.d(TAG, "input id length: " + inputIds.length);
        this.model.resizeInput(0, new int[]{1, inputIds.length});
        this.model.allocateTensors();

        @SuppressLint("UseSparseArrays")
        Map<Integer, Object> outputMap = new HashMap<>();
        FloatBuffer outputBuffer = FloatBuffer.allocate(300000);
        outputMap.put(0, outputBuffer);

        int[][] inputs = new int[1][inputIds.length];
        inputs[0] = inputIds;

        Object[] input = new Object[]{inputs, new int[]{voice}, new float[]{speed}, new float[]{pitch}, new float[]{energy}};
        this.model.runForMultipleInputsOutputs(input, outputMap);

        int[] shape = this.model.getOutputTensor(0).shape();
        Log.d(TAG, "Spectrogram shape: " + Arrays.toString(shape));

        int[] newShape = {1, outputBuffer.position() / shape[2], shape[2]};
        TensorBuffer spectrogram = TensorBuffer.createFixedSize(newShape, DataType.FLOAT32);
        float[] outputArray = new float[outputBuffer.position()];
        outputBuffer.rewind();
        outputBuffer.get(outputArray);
        spectrogram.loadArray(outputArray);
        return spectrogram;
    }
}
