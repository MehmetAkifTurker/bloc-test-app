import 'package:bloc_test_app/data/models/variables.dart';
import 'package:flutter/material.dart';

AppBar commonAppBar(BuildContext context, String title) {
  Color textAndIconColor = titleTextAndIconColor;
  Color backgroundColor = titleBackgroundColor;
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/c4_TT_Logo_RGB_only_logo.png',
          scale: 20.0,
          //width: 200.0,
          //height: 200.0,
          color: titleTextAndIconColor,
        ),
        const SizedBox(
          width: 1.0,
        ),
        Text(title),
      ],
    ),
    foregroundColor: textAndIconColor,
    backgroundColor: backgroundColor,
  );
}
