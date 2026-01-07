import 'package:flutter/material.dart';

class BodyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ListBody(),
              ListTile(
                title: Text("Aldrin"),
                onTap: () => print("Pressed the button Aldrin"),
              ),
              ListTile(
                title: Text("Basil"),
                onTap: () => print("Pressed the button Basil"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
