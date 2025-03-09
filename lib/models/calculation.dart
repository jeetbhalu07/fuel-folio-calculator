
import 'package:flutter/material.dart';

enum FuelType {
  petrol,
  diesel,
  cng
}

class CalculationInput {
  double fuelPrice;
  double distance;
  double mileage;

  CalculationInput({
    required this.fuelPrice,
    required this.distance,
    required this.mileage,
  });
  
  CalculationInput copyWith({
    double? fuelPrice,
    double? distance,
    double? mileage,
  }) {
    return CalculationInput(
      fuelPrice: fuelPrice ?? this.fuelPrice,
      distance: distance ?? this.distance,
      mileage: mileage ?? this.mileage,
    );
  }
}

class CalculationResult {
  final double fuelRequired;
  final double totalCost;

  CalculationResult({
    required this.fuelRequired,
    required this.totalCost,
  });
}

// New class for purchase calculation
class PurchaseCalculation {
  final double amountPaid;
  final double fuelPrice;
  
  PurchaseCalculation({
    required this.amountPaid,
    required this.fuelPrice,
  });
  
  double get fuelQuantity {
    if (fuelPrice <= 0) return 0;
    return double.parse((amountPaid / fuelPrice).toStringAsFixed(2));
  }
  
  // Verify if the bill matches the expected calculation
  bool verifyBill(double claimedQuantity) {
    final expectedAmount = claimedQuantity * fuelPrice;
    final expectedRounded = double.parse(expectedAmount.toStringAsFixed(2));
    final amountRounded = double.parse(amountPaid.toStringAsFixed(2));
    
    // Allow a small tolerance (0.05) for rounding errors
    return (expectedRounded - amountRounded).abs() <= 0.05;
  }
}

CalculationResult calculateFuelCost(CalculationInput input) {
  // Avoid division by zero
  if (input.mileage <= 0) {
    return CalculationResult(fuelRequired: 0, totalCost: 0);
  }
  
  final fuelRequired = input.distance / input.mileage;
  final totalCost = fuelRequired * input.fuelPrice;
  
  return CalculationResult(
    fuelRequired: double.parse(fuelRequired.toStringAsFixed(2)),
    totalCost: double.parse(totalCost.toStringAsFixed(2))
  );
}

// New function to calculate fuel quantity based on amount paid
double calculateFuelQuantity(double amountPaid, double fuelPrice) {
  if (fuelPrice <= 0) return 0;
  return double.parse((amountPaid / fuelPrice).toStringAsFixed(2));
}

String getFuelUnit(FuelType fuelType) {
  return fuelType == FuelType.cng ? 'kg' : 'liter';
}

CalculationInput getDefaultValues(FuelType fuelType) {
  switch (fuelType) {
    case FuelType.petrol:
      return CalculationInput(fuelPrice: 95.41, distance: 100, mileage: 15);
    case FuelType.diesel:
      return CalculationInput(fuelPrice: 88.67, distance: 100, mileage: 20);
    case FuelType.cng:
      return CalculationInput(fuelPrice: 76.21, distance: 100, mileage: 25);
  }
}

String getFuelTypeName(FuelType type) {
  switch (type) {
    case FuelType.petrol:
      return 'Petrol';
    case FuelType.diesel:
      return 'Diesel';
    case FuelType.cng:
      return 'CNG Gas';
  }
}

IconData getFuelTypeIcon(FuelType type) {
  switch (type) {
    case FuelType.petrol:
      return Icons.local_gas_station;
    case FuelType.diesel:
      return Icons.directions_car;
    case FuelType.cng:
      return Icons.gas_meter;
  }
}
