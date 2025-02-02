import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  CustomTextButton(
      {super.key, required this.callBackFun, required this.btnTitle});

  String btnTitle;
  Function callBackFun;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () => callBackFun(),
        child: Text(
          btnTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ));
  }
}
