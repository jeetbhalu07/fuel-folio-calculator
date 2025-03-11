
import 'package:flutter/material.dart';
import '../models/calculation.dart';

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
  double _amount = 500;
  double _quantity = 0;

  @override
  void initState() {
    super.initState();
    _calculateQuantity();
  }

  @override
  void didUpdateWidget(PurchaseCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fuelPrice != widget.fuelPrice || 
        oldWidget.selectedFuelType != widget.selectedFuelType) {
      _calculateQuantity();
    }
  }

  void _calculateQuantity() {
    if (widget.fuelPrice > 0) {
      setState(() {
        _quantity = _amount / widget.fuelPrice;
      });
    }
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
          Text(
            'Purchase Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              color: isDarkMode 
                ? Colors.grey[800]!.withOpacity(0.3)
                : Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode 
                  ? Colors.grey[700]!.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹ ${_amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Current Price: ₹${widget.fuelPrice.toStringAsFixed(2)}/${fuelUnit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Slider(
                  value: _amount,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: isDarkMode 
                      ? Colors.grey[700] 
                      : Colors.grey[300],
                  onChanged: (value) {
                    setState(() {
                      _amount = value;
                      _calculateQuantity();
                    });
                  },
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹100',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹5000',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Result section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[850]!.withOpacity(0.5)
                  : Colors.grey[100]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : Colors.grey[300]!.withOpacity(0.5),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'You will get',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _quantity.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        fuelUnit,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'of ${widget.selectedFuelType.toString().split('.').last.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
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
