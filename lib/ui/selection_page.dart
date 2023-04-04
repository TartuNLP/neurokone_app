import 'package:eesti_tts/ui/header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageSelectionPage extends StatefulWidget {
  final Map<String, String> langText;
  final String lang;
  final Function switchLangs;

  const LanguageSelectionPage(
      {required this.langText, required this.lang, required this.switchLangs});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.android:
        return Scaffold(
            backgroundColor: const Color.fromARGB(255, 238, 238, 238),
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              title: Header(widget.switchLangs, widget.lang),
            ),
            body: TextButton(
              child: Text(widget.langText['Selected']!),
              onPressed: _confirm,
            ));
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  _confirm() {
    Navigator.pop(context);
  }
}
