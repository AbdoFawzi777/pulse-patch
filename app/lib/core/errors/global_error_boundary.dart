import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../shared/widgets/pill_button.dart';

/// Catches uncaught UI rendering exceptions and presents a calm recovery screen.
class GlobalErrorBoundary extends StatefulWidget {
  const GlobalErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  Widget Function(FlutterErrorDetails)? _previousErrorBuilder;

  @override
  void initState() {
    super.initState();
    _previousErrorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      return _buildErrorView(details);
    };
  }

  @override
  void dispose() {
    if (_previousErrorBuilder != null) {
      ErrorWidget.builder = _previousErrorBuilder!;
    }
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
  }

  Widget _buildErrorView(FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.healing_rounded,
                      color: Colors.redAccent,
                      size: 36.0,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Application Recovered',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'An unexpected interface condition occurred. Your recorded pulse history is securely stored on disk.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  PillButton(
                    label: 'Restart Current View',
                    style: PillButtonStyle.white,
                    onPressed: _resetError,
                  ),
                  const SizedBox(height: 16.0),
                  if (kDebugMode && details.exceptionAsString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgNavy,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        details.exceptionAsString(),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.0,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return _buildErrorView(_errorDetails!);
    }
    return widget.child;
  }
}
