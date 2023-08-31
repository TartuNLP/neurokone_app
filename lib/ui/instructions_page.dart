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
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  Duration _animationDuration = Duration(milliseconds: 200);
  
  @override
  Widget build(BuildContext context) {
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLangs, widget.lang),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: _introductionText(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child:
                    Platform.isIOS ? _iosIstructions() : _androidInstructions(),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: _proceedButton(),
              ),
            ],
          ),
        ),
      ),
      scrollButton: _animatedScrollButton(),
      bottom: _appVersionRow(),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showFab = !(_scrollController.position.maxScrollExtent ==
            _scrollController.position.pixels);
      });
    });
  }

  _introductionText() {
    return Text(
      Variables.langs[widget.lang]!['introductionText']!,
      style: TextStyle(fontSize: 17),
    );
  }

  _iosIstructions() {
    return Text(
      Variables.langs[widget.lang]!['instructionTextiOS']!,
      style: TextStyle(fontSize: 17),
    );
  }

  _androidInstructions() {
    return Text(
      Variables.langs[widget.lang]!['instructionTextAndroid']!,
      style: TextStyle(fontSize: 17),
    );
  }

  _proceedButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: ButtonStyle(
        padding:
            MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(16)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      child: Text(
        Variables.langs[widget.lang]!['understood']!,
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  _animatedScrollButton() {
    return AnimatedSlide(
      duration: _animationDuration,
      offset: _showFab ? Offset.zero : Offset(0, 2),
      child: AnimatedOpacity(
        duration: _animationDuration,
        opacity: _showFab ? 1 : 0,
        child: FloatingActionButton(
          onPressed: () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: _animationDuration,
              curve: Curves.easeInOut,
            );
            setState(() {
              _showFab = false;
            });
          },
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              side: BorderSide(width: 0.5, color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(18)),
          child: Icon(
            Icons.arrow_downward,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  _appVersionRow() {
    return Row(
      children: [
        Spacer(),
        Text(
          Variables.appVersion,
          style: TextStyle(fontSize: 14),
        )
      ],
    );
  }
}
