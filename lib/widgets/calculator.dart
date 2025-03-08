
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculation.dart';
import '../models/calculation_history_provider.dart';
import 'fuel_type_selector.dart';
import 'calculator_input.dart';
import 'calculator_result.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> with SingleTickerProviderStateMixin {
  FuelType selectedFuelType = FuelType.petrol;
  late CalculationInput inputs;
  late CalculationResult result;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    inputs = getDefaultValues(selectedFuelType);
    result = calculateFuelCost(inputs);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
  
  void saveCalculation() {
    final historyProvider = Provider.of<CalculationHistoryProvider>(
      context, 
      listen: false
    );
    
    historyProvider.addCalculation(selectedFuelType, inputs, result);
    
    setState(() {
      _showSuccessMessage = true;
    });
    
    // Hide success message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSuccessMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          FuelTypeSelector(
            selectedFuelType: selectedFuelType,
            onChanged: handleFuelTypeChange,
          ),
          const SizedBox(height: 16),
          
          // Glass Card for Inputs
          Container(
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[900]!.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: handleReset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode 
                              ? Colors.grey[800] 
                              : Colors.grey[200],
                          foregroundColor: isDarkMode 
                              ? Colors.white
                              : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: saveCalculation,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Success message
                if (_showSuccessMessage)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Calculation saved successfully',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
      ),
    );
  }
}
