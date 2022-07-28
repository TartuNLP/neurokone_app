package com.example.tflite_app;

import android.util.Log;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;

import java.io.File;
import java.nio.FloatBuffer;

public class VocoderModel {
    private final Interpreter model;
    public VocoderModel(String path) {
        model = new Interpreter(new File(path));
    }

    public float[] getAudio(TensorBuffer input) {
        model.resizeInput(0, input.getShape());
        model.allocateTensors();

        FloatBuffer outputBuffer = FloatBuffer.allocate(350000);

        long time = System.currentTimeMillis();
        model.run(input.getBuffer(), outputBuffer);
        String TAG = "Vocoder";
        Log.d(TAG, "time cost: " + (System.currentTimeMillis() - time));
        Log.i(TAG, "pikkus: " + outputBuffer.position());

        float[] audioArray = new float[outputBuffer.position()];
        outputBuffer.rewind();
        outputBuffer.get(audioArray);
        return audioArray;
    }
}
