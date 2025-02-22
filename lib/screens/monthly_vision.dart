import 'package:flutter/material.dart';

class MonthlyVisionPage extends StatelessWidget {
  const MonthlyVisionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Vision'),
      ),
      body: Center(
        child: Text('This is the Monthly Vision Page'),
      ),
    );
  }
}