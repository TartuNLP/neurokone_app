<h2 align="center">
<p>Demo app and service for Estonian speech synthesis
</h2>
<h3 align="center">
Text to speech in Estonian using FastSpeech2 with Multiband MelGAN or HiFi-GAN.
</h3>

## Mobile App
- 10 speaker voices to choose from.
- Adjustable speech rate.
- Works on both Android and iOS.

## Service usage (Android only)
1. Install the app using the apk from [Releases](https://github.com/TartuNLP/tflite_app_flutter/releases).
2. On your device, go to Settings -> System -> Languages and input -> Text-to-speech output.
3. Switch the preferred engine to ''.
4. Choose the speaker by tapping the gear icon on the right.
5. Adjust the speech rate and pitch.
6. Now this synthesis with set options is called every time the system's text to speech service is used.

## Models
The models used in this project were trained using [TensorFlowTTS](https://github.com/TensorSpeech/TensorflowTTS) architecture and converted to TensorFlow Lite using [this Colab](https://colab.research.google.com/drive/1K6ZRVmBPdAG7bU7ohKEmVtM_6kFjSbP8?usp=sharing).
Due to the slow speed of HiFi-GAN, the vocoder model is set to Multiband MelGAN by default.