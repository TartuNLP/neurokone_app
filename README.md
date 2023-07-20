<h2 align="center">
<p>Demo app and service for Estonian speech synthesis
</h2>
<h3 align="center">
Text to speech in Estonian using FastSpeech2 with HiFi-GAN.
</h3>

## Mobile App
- 10 speaker voices to choose from.
- Adjustable speech rate.
- Works on both Android and iOS.

## Service usage (Android)
1. Install the app using the apk in the latest [release](https://github.com/TartuNLP/tflite_app_flutter/releases).
2. Do one of the following:
   a) Open the app and tap on the "Süsteemi hääl" / "System voice" button.
   b) On your device, go to Settings -> System -> Languages and input -> Text-to-speech output.
4. Switch the preferred engine to "TartuNLP Neurokõne".
5. Choose the speaker by tapping the gear icon on the right.
6. Adjust the speech rate and pitch.
Now our synthesis voice is used every time Android calls for text-to-speech in Estonian.

## Service usage (iOS)
1. Install and run the app (currently only available by running this project through Xcode).
2. Open the app and tap on the "Süsteemi hääl" / "System voice" button.
3. Toggle on the voices you would like to add to your system and tap "Luba hääled" / "Enable voices".
4. Close the app and head to Settings -> Accessibility -> Spoken Content -> Voices -> Eesti / Estonian -> TartuNLP.
5. Tap on your preferred voice.
Now our synthesis voice is used every time iOS calls for text-to-speech in Estonian.

## Models
The models used in this project were trained using the [TensorFlowTTS](https://github.com/TensorSpeech/TensorflowTTS) architecture and converted to TensorFlow Lite using [this Colab](https://colab.research.google.com/drive/1K6ZRVmBPdAG7bU7ohKEmVtM_6kFjSbP8?usp=sharing).