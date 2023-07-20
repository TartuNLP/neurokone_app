package com.tartunlp.neurokone;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.text.TextUtils;

import androidx.annotation.NonNull;

public class PrefUtil {
    private static final String TTS_VOICE = "app.voice";

    public static void setVoice(Context context, String voice) {
        putString(context, TTS_VOICE, voice);
    }

    public static String getTtsVoice(Context context) {
        String voice = getString(context, TTS_VOICE);
        if (TextUtils.isEmpty(voice)) {
            voice = context.getString(R.string.label_mari);
            setVoice(context, voice);
        }
        return voice;
    }

    private static void putString(Context context, String key, String value) {
        getPrefs(context).edit().putString(key, value).apply();
    }

    private static String getString(Context context, String key) {
        return getPrefs(context).getString(key, "");
    }

    private static SharedPreferences getPrefs(Context context) {
        return PreferenceManager.getDefaultSharedPreferences(context);
    }
}

