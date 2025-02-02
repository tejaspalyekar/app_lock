import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

class CustomSnackBar {
  SnackBar customAwesomeSnackBar(
      String title, String msg, ContentType snackBarContentType) {
    final snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: msg,

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: snackBarContentType,
      ),
    );
    return snackBar;
  }

  void customAnimatedSnackBar(String title, String msg,
      AnimatedSnackBarType snackBarContentType, BuildContext context) {
    AnimatedSnackBar.rectangle(
      title,
      msg,
      type: snackBarContentType,
      brightness: Brightness.dark,
    ).show(context);
  }
}
