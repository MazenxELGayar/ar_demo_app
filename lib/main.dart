
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ARDemo());
}


class ARDemo extends StatelessWidget {
  const ARDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello, AR!'),
        ),
      ),
    );
  }
}