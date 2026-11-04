import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that constrains the app UI to a mobile phone form factor
/// when viewed on web browsers or desktop screens, giving a realistic mobile experience.
class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;
  final double maxMobileWidth;

  const ResponsiveMobileWrapper({
    super.key,
    required this.child,
    this.maxMobileWidth = 450.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the viewport is already mobile-sized, render normally
        if (constraints.maxWidth <= maxMobileWidth) {
          return child;
        }

        // On larger screens (Web Desktop / Tablet), center and frame the content
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark slate aesthetic backdrop
          body: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxMobileWidth,
                maxHeight: 900.0,
              ),
              margin: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 6,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Simulated top phone speaker / notch bar for web preview
                  if (kIsWeb)
                    Container(
                      height: 24,
                      color: Colors.white,
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
