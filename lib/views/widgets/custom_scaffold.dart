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
          children: [
            // 🔹 Main content of the screen
            Positioned.fill(child: body),

            // 🔹 Watermark (bottom-left)
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                "M. Atef",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // 🔹 Second watermark (bottom-right)
            Positioned(
              right: 12,
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
