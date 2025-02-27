import 'package:flutter/material.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planner'),
      ),
      body: Center(
        child: Text('Planner Page'),
      ),
    );
  }
}

