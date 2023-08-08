import 'package:flutter/material.dart';

class Voice {
  final String _name;
  final Color _color;

  String getName() {
    return this._name;
  }

  Color getColor() {
    return this._color;
  }

  const Voice(this._name, this._color);

  @override
  bool operator ==(Object other) => other is Voice && other._name == this._name;

  @override
  int get hashCode => super.hashCode;
}
