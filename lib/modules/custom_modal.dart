import 'package:flutter/material.dart';

class CustomModal extends PopupRoute<void> {
  final Widget contents;

  CustomModal(this.contents) : super();

  @override
  Duration get transitionDuration => Duration(milliseconds: 100);
  @override
  bool get barrierDismissible => false;
  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);
  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Material(
        type: MaterialType.transparency,
        child: SafeArea(child: _buildOverlayContent(context)));
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child));
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Center(child: this.contents));
  }
}
