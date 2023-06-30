import 'package:flutter/material.dart';

class Voice {
  final String _name;
  final Color _color;
  final String _icon;

  String getName() {
    return this._name;
  }

  Color getColor() {
    return this._color;
  }

  String getIcon() {
    return this._icon;
  }

  const Voice(this._name, this._color, this._icon);

  @override
  bool operator ==(Object other) => other is Voice && other._name == this._name;

  @override
  int get hashCode => super.hashCode;
}
