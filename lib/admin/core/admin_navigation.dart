import 'package:flutter/material.dart';

class AuthNavigation {
  static void replaceAllWithBuilder(
    BuildContext context,
    WidgetBuilder builder, {
    bool maintainState = false,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: builder),
      (route) => false,
    );
  }

  static void replaceWithBuilder(
    BuildContext context,
    WidgetBuilder builder,
  ) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: builder));
  }
}
