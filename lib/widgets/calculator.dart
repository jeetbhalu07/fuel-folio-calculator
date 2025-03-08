
import 'package:flutter/material.dart';
import '../models/calculation.dart';
import 'fuel_type_selector.dart';
import 'calculator_input.dart';
import 'calculator_result.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  FuelType selectedFuelType = FuelType.petrol;
  late CalculationInput inputs;
  late CalculationResult result;

  @override
  void initState() {
    super.initState();
    inputs = getDefaultValues(selectedFuelType);
    result = calculateFuelCost(inputs);
  }

  void handleFuelTypeChange(FuelType type) {
    setState(() {
      selectedFuelType = type;
      inputs = getDefaultValues(type);
      result = calculateFuelCost(inputs);
    });
  }

  void handleInputChange(String field, double value) {
    setState(() {
      switch (field) {
        case 'fuelPrice':
          inputs.fuelPrice = value;
          break;
        case 'distance':
          inputs.distance = value;
          break;
        case 'mileage':
          inputs.mileage = value;
          break;
      }
      result = calculateFuelCost(inputs);
    });
  }

  void handleReset() {
    setState(() {
      inputs = getDefaultValues(selectedFuelType);
      result = calculateFuelCost(inputs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FuelTypeSelector(
          selectedFuelType: selectedFuelType,
          onChanged: handleFuelTypeChange,
        ),
        const SizedBox(height: 16),
        
        // Glass Card for Inputs
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CalculatorInput(
                id: 'fuel-price',
                label: 'Fuel Price',
                value: inputs.fuelPrice,
                onChanged: (value) => handleInputChange('fuelPrice', value),
                unit: '\$ per ${getFuelUnit(selectedFuelType)}',
                placeholder: 'Enter fuel price',
              ),
              
              CalculatorInput(
                id: 'distance',
                label: 'Distance',
                value: inputs.distance,
                onChanged: (value) => handleInputChange('distance', value),
                unit: 'km',
                placeholder: 'Enter distance',
              ),
              
              CalculatorInput(
                id: 'mileage',
                label: 'Vehicle Mileage',
                value: inputs.mileage,
                onChanged: (value) => handleInputChange('mileage', value),
                unit: 'km per ${getFuelUnit(selectedFuelType)}',
                placeholder: 'Enter mileage',
              ),
              
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: handleReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Results Card
        CalculatorResult(
          result: result,
          fuelUnit: getFuelUnit(selectedFuelType),
        ),
      ],
    );
  }
}
