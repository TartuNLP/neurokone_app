import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  final String language;
  final Function switchLanguage;

  const AboutPage(
      {super.key, required this.language, required this.switchLanguage});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLanguage, widget.language),
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
    return const Text('back');
  }

  _backButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(vars.langs[widget.language]!['back']!),
    );
  }
}
