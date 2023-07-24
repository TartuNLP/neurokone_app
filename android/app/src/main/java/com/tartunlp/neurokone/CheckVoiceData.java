/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.tartunlp.neurokone;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.ArrayList;

/*
 * Checks if the voice data is present.
 */
public class CheckVoiceData extends Activity {
    private static final String TAG = "CheckVoiceData";

    private static final String[] SUPPORTED_LANGUAGES = { "est-EST" };

    @RequiresApi(api = Build.VERSION_CODES.O)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ArrayList<String> available = new ArrayList<String>();
        ArrayList<String> unavailable = new ArrayList<String>();

        for (String lang : SUPPORTED_LANGUAGES) {
            if (isDataInstalled(lang)) {
                available.add(lang);
            } else {
                unavailable.add(lang);
            }
        }

        int result;
        if (available.isEmpty()) {
            // No voices available at all.
            result = TextToSpeech.Engine.CHECK_VOICE_DATA_FAIL;
        } else {
            // All voices are available.
            result = TextToSpeech.Engine.CHECK_VOICE_DATA_PASS;
        }

        // We now return the list of available and unavailable voices
        // as well as the return code.
        Intent returnData = new Intent();
        returnData.putStringArrayListExtra(
                TextToSpeech.Engine.EXTRA_AVAILABLE_VOICES, available);
        returnData.putStringArrayListExtra(
                TextToSpeech.Engine.EXTRA_UNAVAILABLE_VOICES, unavailable);
        setResult(result, returnData);
        finish();
    }

    /*
     * Note that in our example, all data is packaged in our APK as
     * assets (it could be a raw resource as well). This check is unnecessary
     * because it will always succeed.
     *
     * If for example, engine data was downloaded or installed on external storage,
     * this check would make much more sense.
     */
    @RequiresApi(api = Build.VERSION_CODES.O)
    private boolean isDataInstalled(String lang) {
        String synthPath = "fastspeech2-" + lang.split("-")[0] + ".tflite";
        //String vocPath = getFilesDir().getAbsolutePath() + "/hifigan-" + lang.split("-")[0] + ".v2.tflite";
        try {
            InputStream is = Files.newInputStream(new File(getFilesDir().getAbsolutePath() + "/" + synthPath).toPath());

            if (is != null) {
                is.close();
            } else {
                return false;
            }
        } catch (IOException e) {
            Log.w(TAG, "Unable to find data for: " + synthPath + ", exception: " + e);
            return false;
        }

        // The asset InputStream was non null, and therefore this
        // data file is available.
        return true;
    }
}
