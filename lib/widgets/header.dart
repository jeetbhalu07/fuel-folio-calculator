
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Fuel Calc Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Theme.of(context).primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Calculate your fuel costs quickly and efficiently',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
