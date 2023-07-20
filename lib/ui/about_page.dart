import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/variables.dart' as Variables;
import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  final String lang;
  final Function switchLangs;

  AboutPage({required this.lang, required this.switchLangs});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLangs, widget.lang),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _aboutText(),
            _backButton(),
          ],
        ),
      ),
    );
  }

  _aboutText() {
    return Text('back');
  }

  _backButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(Variables.langs[widget.lang]!['back']!),
    );
  }
}
