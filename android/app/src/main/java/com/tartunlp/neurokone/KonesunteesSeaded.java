package com.tartunlp.neurokone;

import android.app.Activity;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;

public class KonesunteesSeaded extends Activity {

    private View mProgress;

    public static volatile String voice;
    private InitTtsAsyncTask mInitTask;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tts_settings);

        mProgress = findViewById(R.id.progress_layout);

        RadioGroup mVoicesContainer = (RadioGroup) findViewById(R.id.tts_voices);
        String voice = PrefUtil.getTtsVoice(this);
        if (voice.equals(getString(R.string.label_mari))) {
            ((RadioButton)findViewById(R.id.mari)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_tambet))) {
            ((RadioButton)findViewById(R.id.tambet)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_liivika))) {
            ((RadioButton)findViewById(R.id.liivika)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_kalev))) {
            ((RadioButton)findViewById(R.id.kalev)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_kylli))) {
            ((RadioButton)findViewById(R.id.kylli)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_meelis))) {
            ((RadioButton)findViewById(R.id.meelis)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_albert))) {
            ((RadioButton)findViewById(R.id.albert)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_indrek))) {
            ((RadioButton)findViewById(R.id.indrek)).setChecked(true);
        } else if (voice.equals(getString(R.string.label_vesta))) {
            ((RadioButton)findViewById(R.id.vesta)).setChecked(true);
        } else {
            ((RadioButton)findViewById(R.id.peeter)).setChecked(true);
        }

        mVoicesContainer.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {

                String voice = null;
                switch (checkedId) {
                    case R.id.mari:
                        voice = getString(R.string.label_mari);
                        break;
                    case R.id.tambet:
                        voice = getString(R.string.label_tambet);
                        break;
                    case R.id.liivika:
                        voice = getString(R.string.label_liivika);
                        break;
                    case R.id.kalev:
                        voice = getString(R.string.label_kalev);
                        break;
                    case R.id.kylli:
                        voice = getString(R.string.label_kylli);
                        break;
                    case R.id.meelis:
                        voice = getString(R.string.label_meelis);
                        break;
                    case R.id.albert:
                        voice = getString(R.string.label_albert);
                        break;
                    case R.id.indrek:
                        voice = getString(R.string.label_indrek);
                        break;
                    case R.id.vesta:
                        voice = getString(R.string.label_vesta);
                        break;
                    case R.id.peeter:
                        voice = getString(R.string.label_peeter);
                        break;
                }

                PrefUtil.setVoice(KonesunteesSeaded.this, voice);

                if (mInitTask != null) {
                    mInitTask.cancel(true);
                }
                mInitTask = new InitTtsAsyncTask();

                mInitTask.execute(voice);
            }
        });
    }

    private class InitTtsAsyncTask extends AsyncTask<String, Void, Void> {

        @Override
        protected void onPreExecute() {
            super.onPreExecute();

            mProgress.setVisibility(View.VISIBLE);
        }

        @Override
        protected Void doInBackground(String... params) {
            voice = params[0];

            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);

            mProgress.setVisibility(View.GONE);

            Toast.makeText(KonesunteesSeaded.this, R.string.saved, Toast.LENGTH_SHORT).show();

            KonesunteesSeaded.this.finish();
        }
    }
}
