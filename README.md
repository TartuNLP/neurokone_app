<h2 align="center">
<p>Demo app and service for Estonian speech synthesis
</h2>
<h3 align="center">
Text to speech in Estonian using FastSpeech2 with HiFi-GAN.
</h3>

## Mobile App
- 10 speaker voices to choose from.
- Adjustable speech rate.
- Works on Android, iOS and MacOS.

## System extension usage: 
### Android
1. Install the app from the Play Store [HERE](https://play.google.com/store/apps/details?id=ee.ut.cs.nlp.neurokone) or using the apk in the latest [release](https://github.com/TartuNLP/neurokone_app/releases).
2. Do one of the following:
   a) Open the app and tap on the "Süsteemi hääl" / "System voice" button.
   b) On your device, go to Settings -> System -> Languages and input -> Text-to-speech output.
4. Switch the preferred engine to "TartuNLP Neurokõne".
5. Choose the speaker by tapping the gear icon on the right.
6. Adjust the speech rate and pitch.
Now our synthesis voice is used every time Android calls for text-to-speech in Estonian.

### iOS / iPadOS / MacOS
1. Get the app from the App Store [HERE](https://apps.apple.com/app/neurokõne/id6673896376) and run it.
2. Close the app and head to Settings -> Accessibility -> Spoken Content -> Voices -> Estonian -> TartuNLP Neurokone.
3. Choose your preferred voice.
Optional:
4. Go to Settings -> Accessibility -> Spoken Content and turn off the option "Detect languages".
Now our synthesis voice is used every time the system calls for text-to-speech in Estonian.

## Models
The models used in this project were trained using the [TensorFlowTTS](https://github.com/TensorSpeech/TensorflowTTS) architecture and converted to TensorFlow Lite using [this Colab](https://colab.research.google.com/drive/1K6ZRVmBPdAG7bU7ohKEmVtM_6kFjSbP8?usp=sharing).