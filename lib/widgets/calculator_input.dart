
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorInput extends StatefulWidget {
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
  State<CalculatorInput> createState() => _CalculatorInputState();
}

class _CalculatorInputState extends State<CalculatorInput> {
  late TextEditingController _controller;
  bool _userEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(CalculatorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller value if the widget's value changed
    // and the user is not currently editing the field
    if (oldWidget.value != widget.value && !_userEditing) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              if (widget.unit != null)
                Text(
                  widget.unit!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
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
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onChanged: (newValue) {
                setState(() {
                  _userEditing = true;
                });
                
                if (newValue.isNotEmpty) {
                  final parsed = double.tryParse(newValue);
                  if (parsed != null) {
                    widget.onChanged(parsed);
                  }
                } else {
                  widget.onChanged(0);
                }
              },
              onEditingComplete: () {
                setState(() {
                  _userEditing = false;
                });
                // Close keyboard when editing is complete
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onTapOutside: (_) {
                setState(() {
                  _userEditing = false;
                });
                FocusScope.of(context).unfocus();
              },
              textInputAction: TextInputAction.done, // This will show the "Done" button on keyboard
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
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
