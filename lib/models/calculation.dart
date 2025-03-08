
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
}

class CalculationResult {
  final double fuelRequired;
  final double totalCost;

  CalculationResult({
    required this.fuelRequired,
    required this.totalCost,
  });
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
