package com.example.tflite_app;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.util.Log;

public class GetSampleText extends Activity {
    private final String TAG = "TextSample";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        int result = TextToSpeech.LANG_AVAILABLE;
        Intent returnData = new Intent();

        Intent i = getIntent();
        String language = i.getExtras().getString("language");

        Log.i(TAG , "GetSampleText language: " + language);

        if (language.equalsIgnoreCase("et") || language.equalsIgnoreCase("est")) {
            returnData.putExtra("sampleText", getString(R.string.sample_text));
        } else {
            result = TextToSpeech.LANG_NOT_SUPPORTED;
            returnData.putExtra("sampleText", "");
        }

        setResult(result, returnData);

        finish();
    }
}