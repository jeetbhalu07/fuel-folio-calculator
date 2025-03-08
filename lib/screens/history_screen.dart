
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculation_history_provider.dart';
import '../models/calculation.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<CalculationHistoryProvider>(context);
    final historyItems = historyProvider.historyItems;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        actions: [
          if (historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(context),
            ),
        ],
      ),
      body: historyItems.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return _buildHistoryCard(context, item, isDarkMode);
              },
            ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Calculation History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your calculation history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryCard(BuildContext context, CalculationHistoryItem item, bool isDarkMode) {
    final fuelTypeName = getFuelTypeName(item.fuelType);
    final fuelUnit = getFuelUnit(item.fuelType);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context);
      },
      onDismissed: (direction) {
        Provider.of<CalculationHistoryProvider>(context, listen: false)
            .removeCalculation(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calculation removed')),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getFuelTypeIcon(item.fuelType),
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fuelTypeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(item.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(
                'Distance:',
                '${item.input.distance.toStringAsFixed(2)} km',
                context,
              ),
              _buildInfoRow(
                'Fuel Price:',
                '\$${item.input.fuelPrice.toStringAsFixed(2)} per $fuelUnit',
                context,
              ),
              _buildInfoRow(
                'Mileage:',
                '${item.input.mileage.toStringAsFixed(2)} km per $fuelUnit',
                context,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                'Fuel Required:',
                '${item.result.fuelRequired.toStringAsFixed(2)} $fuelUnit',
                context,
                isHighlighted: true,
              ),
              _buildInfoRow(
                'Total Cost:',
                '\$${item.result.totalCost.toStringAsFixed(2)}',
                context,
                isHighlighted: true,
                isTotalCost: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, BuildContext context, {bool isHighlighted = false, bool isTotalCost = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 14,
              color: isHighlighted 
                ? Theme.of(context).colorScheme.onBackground
                : Colors.grey[600],
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotalCost ? 18 : (isHighlighted ? 16 : 14),
              fontWeight: isTotalCost ? FontWeight.bold : (isHighlighted ? FontWeight.w600 : FontWeight.normal),
              color: isTotalCost 
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Calculation'),
            content: const Text('Are you sure you want to delete this calculation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
  
  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all calculation history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CalculationHistoryProvider>(context, listen: false).clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
