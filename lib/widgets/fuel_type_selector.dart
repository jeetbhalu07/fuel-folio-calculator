
import 'package:flutter/material.dart';
import '../models/calculation.dart';

class FuelTypeSelector extends StatefulWidget {
  final FuelType selectedFuelType;
  final Function(FuelType) onChanged;

  const FuelTypeSelector({
    Key? key,
    required this.selectedFuelType,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FuelTypeSelector> createState() => _FuelTypeSelectorState();
}

class _FuelTypeSelectorState extends State<FuelTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(FuelType.petrol, 'Petrol', Icons.local_gas_station),
          _buildTabButton(FuelType.diesel, 'Diesel', Icons.directions_car),
          _buildTabButton(FuelType.cng, 'CNG Gas', Icons.gas_meter),
        ],
      ),
    );
  }

  Widget _buildTabButton(FuelType type, String label, IconData icon) {
    final isSelected = widget.selectedFuelType == type;
    
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onChanged(type),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.medium,
                      color: isSelected ? Colors.white : Colors.grey[600],
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
}
