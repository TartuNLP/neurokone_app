import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neurokone/variables.dart' as Variables;
import 'dart:io' show Platform;

class Header extends StatelessWidget {
  final Function callback;
  final String _lang;
  bool get isIOS => Platform.isIOS;

  Header(this.callback, this._lang);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Semantics(
      explicitChildNodes: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(
            'assets/icons_logos/neurokone-logo-clean.svg',
            width: screenWidth < 370 ? screenWidth / 2.5 : null,
          ),
          Spacer(),
          _languageButtons(),
          _moreButton(context),
        ],
      ),
    );
  }

  //App language radio buttons
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

  //Button that, when selected, has a blueish background
  _radioButton(String langCode, String language) {
    return Semantics(
      excludeSemantics: true,
      container: true,
      label: Variables.langs[this._lang]![language],
      selected: this._lang == language,
      child: TextButton(
        style: ButtonStyle(
            backgroundColor: this._lang == language
                ? MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 228, 251, 255))
                : null,
            minimumSize: MaterialStateProperty.all<Size>(Size(50, 40))),
        onPressed:
            this._lang == language ? null : () => this.callback(language),
        child: Text(langCode),
      ),
    );
  }

  //Button that opens the 'More' menu
  _moreButton(BuildContext context) {
    return Semantics(
      label: Variables.langs[this._lang]!['more'],
      excludeSemantics: true,
      child: PopupMenuButton<String>(
        initialValue: Variables.langs[this._lang]!['more'],
        enabled: ModalRoute.of(context)?.settings.name == 'home',
        icon: isIOS
            ? Icon(
                Icons.more_horiz_rounded,
                color: Colors.black54,
              )
            : Icon(
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
      ),
    );
  }

  //'More' menu items
  Set<String> _getPages(BuildContext context) {
    Set<String> out = Set();
    List<String> options =
        isIOS ? ['instructions'] : ['TTS settings', 'instructions'];
    for (String option in options) {
      out.add(Variables.langs[_lang]![option]!);
    }
    return out;
  }

  //Route to take when selected an option in 'More' menu
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
