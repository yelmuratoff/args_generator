import 'package:args_generator_annotations/args_annotations.dart';
import 'package:flutter/material.dart';

part 'test_page.args.g.dart';

void main() {
  runApp(MaterialApp(
      home: TestPage(
    title: 'Test Page',
  )));
}

@GenerateArgs()
class TestPage extends StatefulWidget {
  const TestPage({
    required this.title,
  });

  final String title;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/second');
          },
          child: Text('Go to Second Page'),
        ),
      ),
    );
  }
}
