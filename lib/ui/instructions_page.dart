import 'dart:io' show Platform;
import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/variables.dart' as Variables;
import 'package:flutter/material.dart';

class InstructionsPage extends StatefulWidget {
  final String lang;
  final Function switchLangs;

  InstructionsPage({required this.lang, required this.switchLangs});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  @override
  Widget build(BuildContext context) {
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLangs, widget.lang),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _introductionText(),
              SizedBox(
                height: 30,
              ),
              Platform.isIOS ? _iosIstructions() : _androidInstructions(),
              _proceedButton(),
            ],
          ),
        ),
      ),
      bottom: Row(
        children: [
          Spacer(),
          Text(
            Variables.appVersion,
            style: TextStyle(fontSize: 14),
          )
        ],
      ),
    );
  }

  _introductionText() {
    return Text(
      Variables.langs[widget.lang]!['introductionText']!,
      style: TextStyle(fontSize: 16),
    );
  }

  _iosIstructions() {
    return Text(
      Variables.langs[widget.lang]!['instructionTextiOS']!,
      style: TextStyle(fontSize: 16),
    );
  }

  _androidInstructions() {
    return Text(
      Variables.langs[widget.lang]!['instructionTextAndroid']!,
      style: TextStyle(fontSize: 16),
    );
  }

  _proceedButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(Variables.langs[widget.lang]!['understood']!),
    );
  }
}
