import 'package:flutter/material.dart';

void pushScreen(BuildContext context, String screenName) {
  Navigator.of(context).pushNamed(screenName);
}

void popScreen(BuildContext context) {
  Navigator.of(context).pop();
}

pushReplacement(BuildContext context, String screenName) {
  Navigator.of(context).pushReplacementNamed(screenName);
}
