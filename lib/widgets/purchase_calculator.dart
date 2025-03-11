
import 'package:flutter/material.dart';
import '../models/calculation.dart';
import 'calculator_input.dart';

class PurchaseCalculator extends StatefulWidget {
  final FuelType selectedFuelType;
  final double fuelPrice;

  const PurchaseCalculator({
    Key? key,
    required this.selectedFuelType,
    required this.fuelPrice,
  }) : super(key: key);

  @override
  State<PurchaseCalculator> createState() => _PurchaseCalculatorState();
}

class _PurchaseCalculatorState extends State<PurchaseCalculator> {
  double amountPaid = 200.0;
  double fuelQuantity = 0.0;
  
  @override
  void initState() {
    super.initState();
    _calculateFuelQuantity();
  }
  
  @override
  void didUpdateWidget(PurchaseCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuelPrice != widget.fuelPrice) {
      _calculateFuelQuantity();
    }
  }
  
  void _calculateFuelQuantity() {
    if (widget.fuelPrice > 0) {
      setState(() {
        fuelQuantity = double.parse((amountPaid / widget.fuelPrice).toStringAsFixed(2));
      });
    }
  }
  
  void _handleAmountChanged(double value) {
    setState(() {
      amountPaid = value;
      _calculateFuelQuantity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fuelUnit = getFuelUnit(widget.selectedFuelType);
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Purchase Calculator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey[300],
          ),
          
          CalculatorInput(
            id: 'amount-paid',
            label: 'Amount Paid',
            value: amountPaid,
            onChanged: _handleAmountChanged,
            unit: '₹',
            placeholder: 'Enter amount paid',
          ),
          
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fuel Quantity:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Text(
                  '$fuelQuantity $fuelUnit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
