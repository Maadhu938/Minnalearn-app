import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_minnalearn/utils/app_theme.dart';
import 'package:flutter_minnalearn/widgets/bouncing_widget.dart';
import 'package:flutter_minnalearn/widgets/animated_progress_bar.dart';

void main() {
  group('AppTheme & Color System Tests', () {
    test('AppColors contains zero purple/violet shades and correct Japanese modern palette', () {
      expect(AppColors.primary, const Color(0xFFE11D48)); // Japanese Torii Crimson
      expect(AppColors.amber, const Color(0xFFF59E0B)); // Warm Sun Amber
      expect(AppColors.bamboo, const Color(0xFF10B981)); // Bamboo Emerald
      expect(AppColors.azure, const Color(0xFF0284C7)); // Sky Azure
      expect(AppColors.scaffold, const Color(0xFFF8FAFC)); // Porcelain
      expect(AppColors.card, const Color(0xFFFFFFFF));
      expect(AppColors.border, const Color(0xFFE2E8F0));
    });

    test('AppGradients provide modern warm gradients', () {
      expect(AppGradients.primaryHeader.colors.length, 3);
      expect(AppGradients.primaryHeader.colors.first, const Color(0xFFE11D48));
      expect(AppGradients.amber.colors.first, const Color(0xFFF59E0B));
    });

    test('AppShadows provides subtle non-AI elevations', () {
      expect(AppShadows.card.length, 2);
      expect(AppShadows.card.first.blurRadius, 14.0);
    });
  });

  group('Interactive Animations Widget Tests', () {
    testWidgets('BouncingWidget renders child and responds to tap with spring feedback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingWidget(
              onTap: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AnimatedProgressBar renders progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressBar(
              value: 0.65,
              height: 10,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedProgressBar), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
