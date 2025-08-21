// lib/utils/battery_calculator.dart

import 'package:flutter/material.dart';
import '../config/constants.dart';

class BatteryCalculator {
  /// Calculate if battery passes based on 85% rule
  static bool calculatePass(double ratedAmpHours, double currentReading) {
    double minRequired = getMinRequired(ratedAmpHours);
    return currentReading >= minRequired;
  }
  
  /// Get minimum required current (85% of rated)
  static double getMinRequired(double ratedAmpHours) {
    return ratedAmpHours * AppConstants.batteryPassThreshold;
  }
  
  /// Format pass/fail result for display
  static String getResultText(bool passed) {
    return passed ? 'PASS' : 'FAIL';
  }
  
  /// Get result color
  static Color getResultColor(bool passed) {
    return passed 
        ? const Color(0xFF4CAF50)  // Green
        : const Color(0xFFF44336);  // Red
  }
  
  /// Validate amp hour rating
  static bool isValidAmpHourRating(double rating) {
    return rating > 0 && rating <= 1000; // Reasonable range
  }
  
  /// Round to 2 decimal places for display
  static double roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }
}