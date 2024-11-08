import 'dart:io' show Platform;
import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter/material.dart';

class InstructionsPage extends StatefulWidget {
  final String language;
  final Function switchLanguage;

  const InstructionsPage(
      {super.key, required this.language, required this.switchLanguage});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  final Duration _animationDuration = const Duration(milliseconds: 200);
  AssetImage? _tutorialImage;

  @override
  Widget build(BuildContext context) {
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLanguage, widget.language),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _introductionText(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Platform.isAndroid
                    ? _androidInstructions()
                    : Platform.isIOS
                        ? _iosIstructions()
                        : _macosInstructions(),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
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
    _scrollController.addListener(() {
      setState(() {
        _showFab = !(_scrollController.position.maxScrollExtent ==
            _scrollController.position.pixels);
      });
    });
    super.initState();
  }

  _introductionText() {
    return Column(
      children: [
        Text(
          vars.langs[widget.language]!['introductionText']!,
          style: const TextStyle(fontSize: 17),
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          vars.langs[widget.language]!['instructionText']!,
          style: const TextStyle(fontSize: 17),
        )
      ],
    );
  }

  _androidInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertButton('enableEngineApp'),
        _alertButton('enableEngineSettings'),
        _alertButton('configureEngine'),
      ],
    );
  }

  _iosIstructions() {
    return Text(
      vars.langs[widget.language]!['instructionTextiOS']!,
      style: const TextStyle(fontSize: 17),
    );
  }

  _macosInstructions() {
    return Text(
      vars.langs[widget.language]!['instructionTextMacOS']!,
      style: const TextStyle(fontSize: 17),
    );
  }

  _alertButton(String key) {
    String gifPath = vars.langs[widget.language]![key]!;
    String text = vars.langs[widget.language]!['${key}Text']!;
    return TextButton(
        onPressed: () {
          Widget okButton = TextButton(
              child: Text(
                "OK",
                semanticsLabel:
                    "${vars.langs[widget.language]!['${key}Label']!}OK",
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _tutorialImage!.evict();
              });
          _tutorialImage = AssetImage(
            gifPath,
            //width: MediaQuery.of(context).size.width / 2,
          );
          AlertDialog popup = AlertDialog(
            elevation: 24,
            backgroundColor: Colors.transparent,
            contentPadding: const EdgeInsets.all(0),
            content: Image(
              image: _tutorialImage!,
              width: MediaQuery.of(context).size.width / 2,
            ),
            //semanticLabel: Variables.langs[widget.lang]![key + 'Label'],
            actionsPadding: const EdgeInsets.all(0),
            actions: [okButton],
          );
          showDialog(context: context, builder: (_) => popup)
              .then((value) => _tutorialImage!.evict());
        },
        child: Text(text));
  }

  _proceedButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: ButtonStyle(
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            const EdgeInsets.all(16)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      child: Text(
        vars.langs[widget.language]!['understood']!,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  _animatedScrollButton() {
    return AnimatedSlide(
      duration: _animationDuration,
      offset: _showFab ? Offset.zero : const Offset(0, 2),
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
              side: const BorderSide(width: 0.5, color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(18)),
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  _appVersionRow() {
    return const Row(
      children: [
        Spacer(),
        Padding(
          padding: EdgeInsets.only(right: 40),
          child: Text(
            vars.appVersion,
            style: TextStyle(fontSize: 14),
          ),
        )
      ],
    );
  }
}
