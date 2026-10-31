import 'package:flutter/material.dart';

class IndiaFlag extends StatelessWidget {
  const IndiaFlag({super.key});

  static const Color _saffron = Color(0xFFFF6A1A);
  static const Color _green = Color(0xFF046A38);
  static const Color _chakra = Color(0xFF06038D);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 30,
        height: 20,
        child: Column(
          children: [
            const Expanded(child: ColoredBox(color: _saffron)),
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _chakra, width: 1),
                  ),
                ),
              ),
            ),
            const Expanded(child: ColoredBox(color: _green)),
          ],
        ),
      ),
    );
  }
}
