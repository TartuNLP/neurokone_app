package com.tartunlp.eesti_tts;

import android.media.AudioFormat;
import android.speech.tts.SynthesisCallback;
import android.speech.tts.SynthesisRequest;
import android.speech.tts.TextToSpeech;
import android.speech.tts.TextToSpeechService;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.Nullable;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.tensorflow.lite.DataType;
import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;
import java.io.*;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Konesuntees extends TextToSpeechService {  //FlutterPlugin
    private final String TAG = "Kõnesüntees";
    /*
     * This is the sampling rate of our output audio. This engine outputs
     * audio at 22.05kHz 16bits per sample PCM audio.
     */
    private static final int SAMPLING_RATE_HZ = 22050;
    private final int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
    private final static ByteOrder byteOrder = ByteOrder.LITTLE_ENDIAN;

    private volatile String[] mCurrentLanguage = null;
    private volatile boolean mStopRequested = false;

    private boolean isInit = false;
    private final Encoder mEncoder = new Encoder();
    private FastSpeechModel mModule;
    private VocoderModel vocModule;

    //private int voice = 0;
    private final List<String> voices = Arrays.asList("Mari", "Tambet", "Liivika", "Kalev", "Külli", "Meelis", "Albert", "Indrek", "Vesta", "Peeter");
    

    @Override
    public void onCreate() {
        super.onCreate();
        // We load the default language when we start up. This isn't strictly
        // required though, it can always be loaded lazily on the first call to
        // onLoadLanguage or onSynthesizeText. This a tradeoff between memory usage
        // and the latency of the first call.
        onLoadLanguage("est", "est", "");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    protected String[] onGetLanguage() {
        // Note that mCurrentLanguage is volatile because this can be called from
        // multiple threads.
        return mCurrentLanguage;
    }

    @Override
    protected int onIsLanguageAvailable(String lang, String country, String variant) {
        // The robot speak synthesizer supports only english.
        if ("est".equals(lang)) { // || "eng".equals(lang)
            // We support two specific robot languages, the british robot language
            // and the american robot language.
            if ("EST".equals(country)) {    // || "USA".equals(country) || "GBR".equals(country)
                // If the engine supported a specific variant, we would have
                // something like.
                //
                // if ("android".equals(variant)) {
                //     return TextToSpeech.LANG_COUNTRY_VAR_AVAILABLE;
                // }
                return TextToSpeech.LANG_COUNTRY_AVAILABLE;
            }
            // We support the language, but not the country.
            return TextToSpeech.LANG_AVAILABLE;
        }
        return TextToSpeech.LANG_NOT_SUPPORTED;
    }

    private String copyFile(String strOutFileName) {
        Log.d(TAG, "start copy file " + strOutFileName);
        File file = getFilesDir();

        String tmpFile = file.getAbsolutePath() + "/" + strOutFileName;
        File f = new File(tmpFile);
        if (f.exists()) {
            Log.d(TAG, "file exists " + strOutFileName);
            return f.getAbsolutePath();
        }

        try (OutputStream myOutput = new FileOutputStream(f);
             InputStream myInput = getAssets().open(strOutFileName)) {
            byte[] buffer = new byte[1024];
            int length = myInput.read(buffer);
            while (length > 0) {
                myOutput.write(buffer, 0, length);
                length = myInput.read(buffer);
            }
            myOutput.flush();
            Log.d(TAG, "Copy task successful");
        } catch (Exception e) {
            Log.e(TAG, "copyFile: Failed to copy", e);
        } finally {
            Log.d(TAG, "end copy file " + strOutFileName);
        }
        return f.getAbsolutePath();
    }

    /*
     * Note that this method is synchronized, as is onSynthesizeText because
     * onLoadLanguage can be called from multiple threads (while onSynthesizeText
     * is always called from a single thread only).
     */
    @Override
    protected synchronized int onLoadLanguage(String lang, String country, String variant) {
        final int isLanguageAvailable = onIsLanguageAvailable(lang, country, variant);
        if (isLanguageAvailable == TextToSpeech.LANG_NOT_SUPPORTED) {
            return isLanguageAvailable;
        }
        String loadCountry = country;
        if (isLanguageAvailable == TextToSpeech.LANG_AVAILABLE) {
            loadCountry = "EST"; //"USA"
        }
        // If we've already loaded the requested language, we can return early.
        if (mCurrentLanguage != null) {
            if (mCurrentLanguage[0].equals(lang) && mCurrentLanguage[1].equals(country)) {
                return isLanguageAvailable;
            }
        }
        if (!isInit) {
            String modulePath = copyFile("fastspeech2-" + lang + ".tflite");
            String vocoderPath = copyFile("hifigan-" + lang + ".tflite");
            try {
                mModule = new FastSpeechModel(modulePath);
                isInit = true;
                Log.i(TAG, "Loaded Fastspeech2 model in " + lang);
            } catch (Exception error) {
                Log.e(TAG, "Error loading synth model for : " + lang + ", error: " + error);
                isInit = false;
            }
            try {
                vocModule = new VocoderModel(vocoderPath);
                isInit = true;
                Log.i(TAG, "Loaded Vocoder model in " + lang);
            } catch (Exception error) {
                Log.e(TAG, "Error loading vocoder model for : " + lang + ", error: " + error);
                isInit = false;
            }
        }
        mCurrentLanguage = new String[] { lang, loadCountry, ""};
        return isLanguageAvailable;
    }
    
    @Override
    protected void onStop() {
        mStopRequested = true;
    }

    @Override
    protected synchronized void onSynthesizeText(SynthesisRequest request,
            SynthesisCallback callback) {
        if (request == null) return;
        // Note that we call onLoadLanguage here since there is no guarantee
        // that there would have been a prior call to this function.
        int load = onLoadLanguage(request.getLanguage(), request.getCountry(),
                request.getVariant());
        // We might get requests for a language we don't support - in which case
        // we error out early before wasting too much time.
        if (load == TextToSpeech.LANG_NOT_SUPPORTED) {
            callback.error();
            return;
        }
        String text = request.getCharSequenceText().toString();

        if (TextUtils.isEmpty(text)) {
            callback.done();
            return;
        }
        // At this point, we have loaded the language we need for synthesis and
        // it is guaranteed that we support it so we proceed with synthesis.
        // We denote that we are ready to start sending audio across to the
        // framework. We use a fixed sampling rate (22.05khz), and send data across
        // in 16bit PCM mono.
        callback.start(SAMPLING_RATE_HZ, audioFormat, 1);

        /*
        if (mStopRequested) {
            callback.done();
            return;
        }*/
        mStopRequested = false;

        int speakerId = voices.indexOf(PrefUtil.getTtsVoice(this));
        mModule.setVoice(speakerId);
        float speed = (float) request.getSpeechRate() / 100;
        mModule.setSpeed(speed);
        float pitch = (float) request.getPitch() / 100;
        mModule.setPitch(pitch);
        Log.i(TAG, "Prefs: text " + text + ", voice " + speakerId + ", speed " + speed + ", pitch " + pitch);

        final String[] sentences = text.split(" . ");
        for (int i = 0; i < sentences.length; ++i) {
            List<Integer> idsList = mEncoder.textToIds(sentences[i]);
            Integer[] integerList = idsList.toArray(new Integer[idsList.size()]);
            int[] ids = Arrays.stream(integerList).mapToInt(Integer::intValue).toArray();
            // It is crucial to call either of callback.error() or callback.done() to ensure
            // that audio / other resources are released as soon as possible.
            if (!generateOneSentenceOfAudio(ids, callback)) {
                callback.error();
                return;
            }
        }
        // Alright, we're done with our synthesis - yay!
        callback.done();
    }

    private boolean generateOneSentenceOfAudio(int[] inputIds, SynthesisCallback cb) {
        
        if (mStopRequested) {
            return false;
        }
        TensorBuffer spectrogram = mModule.getMelSpectrogram(inputIds);
        //Log.i(TAG, Arrays.toString(spectrogram.getFloatArray()));
        float[] outputArray = vocModule.getAudio(spectrogram);

        byte[] mAudioBuffer = new byte[4 * outputArray.length + 1]; // +1 because less throws buffervoverflow
        ByteBuffer buffer = ByteBuffer.wrap(mAudioBuffer).order(ByteOrder.LITTLE_ENDIAN);

        for (int i = 0; i < outputArray.length; i++) {
            buffer.putShort((short) Math.round(32768 * outputArray[i]));
        }
        // Get the maximum allowed size of data we can send across in audioAvailable.
        final int maxBufferSize = cb.getMaxBufferSize();
        int offset = 0;
        while (offset < mAudioBuffer.length) {
            int bytesToWrite = Math.min(maxBufferSize, mAudioBuffer.length - offset);
            cb.audioAvailable(mAudioBuffer, offset, bytesToWrite);
            offset += bytesToWrite;
        }
        return true;
    }

    /*
    
    public static byte[] floatArray2IntByteArray(float[] values) {
        /*
        int[] intArray = new int[values.length];
        for (int i = 0; i < values.length; i++) {
            intArray[i] = Math.round(values[i]*2147483647);
        }
        values = null;
        /
        ByteBuffer buffer = ByteBuffer.allocate(4 * values.length).order(byteOrder);
        for (float value : values) {
            //buffer.putInt(value);
            buffer.putFloat(value);
        }
        return buffer.array();
    }

    public float arrayMinOrMax(float[] array, boolean max) {
        if (max) {
            float maxF = -100F;
            for (float v : array) {
                maxF = Math.max(maxF, v);
            }
            return maxF;
        }
        else {
            float minF = 100F;
            for (float v : array) {
                minF = Math.min(minF, v);
            }
            return minF;
        }
    }

    private boolean generateOneSentenceOfAudio(int[] inputIds, SynthesisCallback cb) {
        if (mStopRequested) {
            return false;
        }
        TensorBuffer spectrogram = mModule.getMelSpectrogram(inputIds);
        float[] specArray = spectrogram.getFloatArray();
        Log.i(TAG, "spec len: " + specArray.length);
        /*for (int i = 0; i <= specArray.length/80; i++) {
            Log.i(TAG, Arrays.toString(Arrays.copyOfRange(specArray, 80 * i, 80 * (i + 1))));
        }/
        float[] outputArray = vocModule.getAudio(spectrogram);
        //Log.i(TAG, "min: " + arrayMinOrMax(outputArray, false) + ", max: " + arrayMinOrMax(outputArray, true));
        Log.i(TAG, "audio len: " + outputArray.length);
        /*for (int i = 0; i <= outputArray.length/100; i++) {
            if (outputArray.length < 100*(i+1)) {
                Log.i(TAG, Arrays.toString(Arrays.copyOfRange(outputArray, 100 * i, outputArray.length)));
            } else {
                Log.i(TAG, Arrays.toString(Arrays.copyOfRange(outputArray, 100 * i, 100 * (i + 1))));
            }
        }/
        Log.i(TAG, "end");
        byte[] audioArray = floatArray2IntByteArray(outputArray);
        //Log.i(TAG, "len: " + audioArray.length + "; array: " + Arrays.toString(audioArray));

        // Get the maximum allowed size of data we can send across in audioAvailable.
        final int maxBufferSize = cb.getMaxBufferSize();
        int offset = 0;
        while (offset < audioArray.length) {
            int bytesToWrite = Math.min(maxBufferSize, audioArray.length - offset);
            if (cb.audioAvailable(audioArray, offset, bytesToWrite) == TextToSpeech.ERROR) {
                mStopRequested = true;
                return false;
            }
            offset += bytesToWrite;
        }
        return true;
    }

    */
}

/*

https://github.com/Miserlou/Android-SDK-Samples/blob/master/TtsEngine/src/com/example/android/ttsengine/RobotSpeakTtsService.java

*/