
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorInput extends StatelessWidget {
  final String id;
  final String label;
  final double value;
  final Function(double) onChanged;
  final String? unit;
  final double? min;
  final double? max;
  final double? step;
  final String? placeholder;

  const CalculatorInput({
    Key? key,
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: TextEditingController(text: value.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (newValue) {
                if (newValue.isNotEmpty) {
                  final parsed = double.tryParse(newValue);
                  if (parsed != null) {
                    onChanged(parsed);
                  }
                } else {
                  onChanged(0);
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
