import 'package:flutter/material.dart';

class Voice {
  final String _name;
  final MaterialColor _color;
  final String _icon;

  String getName() {
    return _name;
  }

  MaterialColor getColor() {
    return _color;
  }

  String getIcon() {
    return _icon;
  }

  const Voice(this._name, this._color, this._icon);

  @override
  bool operator ==(Object other) => other is Voice && other._name == _name;

  @override
  int get hashCode => super.hashCode;
}
