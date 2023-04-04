import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        _langRadioButtons(),
      ],
    );
  }

  //Toggle buttons for UI language.
  _langRadioButtons() {
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
        style: _lang == language
            ? ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 228, 251, 255)))
            : null,
        onPressed: _lang == language ? null : () => this.callback(language),
        child: Text(langCode));
  }
}
