import 'package:eestitts/ui/header.dart';
import 'package:eestitts/ui/page_view.dart';
import 'package:eestitts/variables.dart';
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
        child: Column(
          children: [
            _instructionText(),
            _proceedButton(),
          ],
        ),
      ),
    );
  }

  _instructionText() {
    return Text("Instructions");
  }

  _proceedButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(Variables.langs[widget.lang]!['understood']!),
    );
  }
}
