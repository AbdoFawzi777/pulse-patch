import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_icon_widget.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/pill_button.dart';

/// Screen displaying graduation project credits, hardware specifications, and licenses.
/// Derived screen #21 adhering strictly to design tokens.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignCanvasScaffold(
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              CircleIconButton(
                type: CircleIconType.back,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56.0),
            ],
          ),
          const SizedBox(height: 12.0),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),
                  // App Hero Emblem using Master Vector App Icon
                  const Center(child: AppIconWidget(size: 84.0)),
                  const SizedBox(height: 14.0),
                  const Center(
                    child: Text(
                      'PulsePatch Lite',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.0,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Center(
                    child: Text(
                      'Version 1.0.0 (Build 1) · Educational Prototype',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.0,
                        color: Color(0xFF6B6F95),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Educational Capstone Credits Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: AppColors.accentCyan,
                              size: 22.0,
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Academic Capstone Project',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          'Engineered as a senior biomedical informatics capstone project demonstration. Designed to demonstrate embedded real-time PPG signal acquisition, defensive BLE parsing, on-device neural pattern recognition, and robust local data storage.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Hardware Specifications Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.developer_board_rounded,
                              color: AppColors.accentPurple,
                              size: 22.0,
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Hardware Architecture',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        _buildSpecRow(
                          'Microcontroller',
                          'Espressif ESP32-C3 RISC-V (160 MHz)',
                        ),
                        _buildSpecRow(
                          'Optical Sensor',
                          'Maxim Integrated MAX30102 PPG',
                        ),
                        _buildSpecRow(
                          'Sensor Bus',
                          'I2C (SDA: GPIO4, SCL: GPIO5) @ 3.3V',
                        ),
                        _buildSpecRow(
                          'Wireless Protocol',
                          'Bluetooth Low Energy 5.0 (NimBLE)',
                        ),
                        _buildSpecRow(
                          'Payload Contract',
                          '12-Byte Little-Endian GATT Packets',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Software Stack Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF0F2160), Color(0xFF08122E)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.code_rounded,
                              color: AppColors.accentCyan,
                              size: 22.0,
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'Software Frameworks',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        _buildSpecRow(
                          'App Framework',
                          'Flutter 3.x / Dart 3.x (Multiplatform)',
                        ),
                        _buildSpecRow(
                          'State Management',
                          'Riverpod Reactive Container',
                        ),
                        _buildSpecRow(
                          'Database Engine',
                          'SQLite 3 (C FFI / Local Document Dir)',
                        ),
                        _buildSpecRow(
                          'AI Pattern Engine',
                          'small neural network running locally in the app',
                        ),
                        _buildSpecRow(
                          'Localization',
                          'English (LTR) and Arabic (RTL)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // Compliance & Educational Disclaimer
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.6, -0.8),
                        end: Alignment(0.6, 0.8),
                        colors: [Color(0xFF38102A), Color(0xFF1B0715)],
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.accentMagenta,
                              size: 22.0,
                            ),
                            SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Non-Diagnostic Scope',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations. Never use this software for diagnostic monitoring, treatment decisions, or emergency cardiac detection.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Open Source Licenses Button
                  PillButton(
                    label: 'View Open Source Licenses',
                    style: PillButtonStyle.dark,
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'PulsePatch Lite',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2026 PulsePatch Lite Capstone Project Team. All rights reserved.',
                      );
                    },
                  ),

                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
