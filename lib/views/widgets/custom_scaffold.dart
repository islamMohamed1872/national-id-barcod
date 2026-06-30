import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;

  const CustomScaffold({super.key, required this.body, this.backgroundColor, this.appBar, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentGeometry.center,
          children: [
            // 🔹 Main content of the screen
            Positioned.fill(child: body),

            // 🔹 Second watermark (bottom-right)
            Positioned(
              bottom: 12,
              child: Text(
                "M. Osama El Baz",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 40.0),
        child: floatingActionButton,
      ),
    );
  }
}
