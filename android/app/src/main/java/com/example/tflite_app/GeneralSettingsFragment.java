package com.example.tflite_app;

import android.os.Bundle;
import android.preference.PreferenceFragment;
public class GeneralSettingsFragment extends PreferenceFragment {
    static final String SHARED_PREFS_NAME = "KonesunteesSeadedActivity";
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getPreferenceManager().setSharedPreferencesName(SHARED_PREFS_NAME);
        addPreferencesFromResource(R.xml.general_settings);
    }
}