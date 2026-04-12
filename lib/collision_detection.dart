import 'package:flutter/material.dart';

/// Collision severity levels used by the Sentinel app.
enum CollisionSeverity { none, minor, moderate, severe }

/// Collision thresholds for the helmet-mounted IoT device.
///
/// Adjust these constants to match the sensor calibration for your helmet.
class CollisionThresholds {
  static const double minor = 2.5;
  static const double moderate = 4.0;
  static const double severe = 6.5;
}

class CollisionDetectionService {
  CollisionDetectionService._();

  /// Converts a raw impact value into a severity level.
  static CollisionSeverity classifyImpact(double impactG) {
    if (impactG >= CollisionThresholds.severe) {
      return CollisionSeverity.severe;
    }
    if (impactG >= CollisionThresholds.moderate) {
      return CollisionSeverity.moderate;
    }
    if (impactG >= CollisionThresholds.minor) {
      return CollisionSeverity.minor;
    }
    return CollisionSeverity.none;
  }

  /// Process an incoming IoT collision event and show the correct alert.
  ///
  /// Call this once the helmet sends a collision or out-of-the-ordinary event.
  static Future<void> processImpact(
      BuildContext context, double impactG) async {
    final severity = classifyImpact(impactG);

    if (severity == CollisionSeverity.none) {
      return;
    }

    if (severity == CollisionSeverity.minor) {
      await _showMinorCollisionAlert(context, impactG);
      return;
    }

    await _triggerEmergencyResponse(context, severity, impactG);
  }

  static Future<void> _showMinorCollisionAlert(
      BuildContext context, double impactG) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Minor Collision Detected'),
          content: Text(
            'A minor impact was detected (impact value: ${impactG.toStringAsFixed(1)}).'
            ' No emergency response was triggered. Please check the helmet and confirm you are okay.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _triggerEmergencyResponse(
    BuildContext context,
    CollisionSeverity severity,
    double impactG,
  ) {
    final severityLabel =
        severity == CollisionSeverity.severe ? 'Severe' : 'Moderate';
    final message = severity == CollisionSeverity.severe
        ? 'A severe collision was detected. Emergency response has been activated.'
        : 'A moderate collision was detected. Emergency response has been activated.';

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$severityLabel Collision Detected'),
          content: Text(
            '$message\n\nImpact value: ${impactG.toStringAsFixed(1)}\n'
            'The system will notify emergency contacts and dispatch assistance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
