package com.tartunlp.neurokone;

import android.util.Log;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;

import java.io.File;
import java.nio.FloatBuffer;

public class VocoderModel {
    private final Interpreter model;
    public VocoderModel(String path) {
        this.model = new Interpreter(new File(path));
    }

    public synchronized float[] getAudio(TensorBuffer input) {
        int[] inputShape = input.getShape();
        this.model.resizeInput(0, inputShape);
        this.model.allocateTensors();

        FloatBuffer outputBuffer = FloatBuffer.allocate(6 * inputShape[1] * inputShape[2]);
        //FloatBuffer outputBuffer = FloatBuffer.allocate(300000);

        this.model.run(input.getBuffer(), outputBuffer);
        String TAG = "Vocoder";
        Log.i(TAG, "pikkus: " + outputBuffer.position());

        float[] audioArray = new float[outputBuffer.position()];
        outputBuffer.rewind();
        outputBuffer.get(audioArray);
        return audioArray;
    }
}
