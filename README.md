<h2 align="center">
<p>Demo app and service for Estonian speech synthesis

<p align="center">
    <a href="https://colab.research.google.com/drive/1K6ZRVmBPdAG7bU7ohKEmVtM_6kFjSbP8?usp=sharing">
        <img alt="Colab" src="https://colab.research.google.com/assets/colab-badge.svg">
</p>
</h2>
<h2 align="center">
Synthesize speech from text in Estonian using FastSpeech2 with Multiband MelGAN or HiFi-GAN.
</h2>

## Mobile App
- Adjustable speech rate.
- Works on both Android and iOS.
- 10 speaker voices to choose from.

## Service usage (Android)
1. Install the app using the apk from [Releases](https://github.com/TartuNLP/tflite_app_flutter/releases).
2. On your device, go to Settings -> System -> Languages and input -> Text-to-speech output.
3. Switch the preferred engine to ''.
4. Choose the speaker by tapping the gear icon on the right.
5. Adjust the speech rate and pitch.
6. Now this synthesis with set options is called every time the system's text to speech service is used.

## Models
The models used in this project were trained using [TensorFlowTTS](https://github.com/TensorSpeech/TensorflowTTS) architecture and converted to TensorFlow Lite using [this Colab](https://colab.research.google.com/drive/1K6ZRVmBPdAG7bU7ohKEmVtM_6kFjSbP8?usp=sharing).