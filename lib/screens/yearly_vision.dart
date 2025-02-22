import 'package:flutter/material.dart';

class YearlyVisionPage extends StatelessWidget {
  const YearlyVisionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yearly Vision'),
      ),
      body: Center(
        child: Text('This is the Yearly Vision Page'),
      ),
    );
  }
}