import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class Voice extends StatelessWidget {
  final String _name;
  final Color _color;
  final String _icon;

  String getName() {
    return _name;
  }

  Color getColor() {
    return _color;
  }

  const Voice(this._name, this._color, this._icon, {Key? key})
      : super(key: key);

  @override
  bool operator ==(Object other) => other is Voice && other._name == _name;

  //Builds a component for the dropdown list
  //Consists of decoration icon (that could be animated) and speaker name with coloured background and some spacing in between
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Lottie.asset(
            'assets/icons_logos/$_icon.json',
            animate: false,
          ),
          const SizedBox(
            width: 20,
          ),
          Text(_name),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }
}
