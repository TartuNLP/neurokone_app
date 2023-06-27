import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eestitts/variables.dart';

class Header extends StatelessWidget {
  final Function callback;
  final String _lang;

  Header(this.callback, this._lang);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SvgPicture.asset('assets/icons_logos/neurokone-logo-clean.svg'),
        Spacer(),
        _languageButtons(),
        if (ModalRoute.of(context)?.settings.name == 'home')
          _moreButton(context),
      ],
    );
  }

  _languageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _radioButton('ET', 'Eesti'),
        _radioButton('EN', 'English'),
      ],
    );
  }

  //Button that, when selected, has a blueish background and is disabled.
  _radioButton(String langCode, String language) {
    return TextButton(
        style: this._lang == language
            ? ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 228, 251, 255)))
            : null,
        onPressed:
            this._lang == language ? null : () => this.callback(language),
        child: Text(langCode));
  }

  _moreButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Colors.black54,
      ),
      onSelected: (value) => _handleClick(value, context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      itemBuilder: (BuildContext context) {
        return _getPages(context).map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  Set<String> _getPages(BuildContext context) {
    Set<String> out = Set();
    for (String page in ['TTS settings', 'about', 'instructions']) {
      out.add(Variables.langs[_lang]![page]!);
    }
    return out;
  }

  void _handleClick(String value, BuildContext context) async {
    if (value == Variables.langs[_lang]!['TTS settings']!) {
      await AndroidIntent(action: 'com.android.settings.TTS_SETTINGS').launch();
    } else if (value == Variables.langs[_lang]!['about']!) {
      await Navigator.pushNamed(context, 'about');
    } else if (value == Variables.langs[_lang]!['instructions']!) {
      await Navigator.pushNamed(context, 'instructions');
    }
  }
}
