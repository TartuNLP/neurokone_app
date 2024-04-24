import 'package:flutter/material.dart';

class Voice {
  final String _name;
  final Color _color;

  String getName() {
    return _name;
  }

  Color getColor() {
    return _color;
  }

  const Voice(this._name, this._color);

  @override
  bool operator ==(Object other) => other is Voice && other._name == _name;

  @override
  int get hashCode => super.hashCode;
}
