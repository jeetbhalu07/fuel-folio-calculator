
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'calculation.dart';

class CalculationHistoryProvider with ChangeNotifier {
  final SharedPreferences prefs;
  List<CalculationHistoryItem> _historyItems = [];
  
  CalculationHistoryProvider(this.prefs) {
    _loadHistory();
  }
  
  List<CalculationHistoryItem> get historyItems => _historyItems;
  
  void _loadHistory() {
    final historyJson = prefs.getStringList('calculationHistory') ?? [];
    _historyItems = historyJson
        .map((item) => CalculationHistoryItem.fromJson(jsonDecode(item)))
        .toList();
    notifyListeners();
  }
  
  Future<void> addCalculation(
    FuelType fuelType, 
    CalculationInput input, 
    CalculationResult result
  ) async {
    final newItem = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fuelType: fuelType,
      input: input,
      result: result,
      date: DateTime.now(),
    );
    
    _historyItems.insert(0, newItem);
    
    // Limit history to 20 items
    if (_historyItems.length > 20) {
      _historyItems = _historyItems.sublist(0, 20);
    }
    
    await _saveHistory();
    notifyListeners();
  }
  
  Future<void> removeCalculation(String id) async {
    _historyItems.removeWhere((item) => item.id == id);
    await _saveHistory();
    notifyListeners();
  }
  
  Future<void> clearHistory() async {
    _historyItems.clear();
    await _saveHistory();
    notifyListeners();
  }
  
  Future<void> _saveHistory() async {
    final historyJson = _historyItems
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList('calculationHistory', historyJson);
  }
}

class CalculationHistoryItem {
  final String id;
  final FuelType fuelType;
  final CalculationInput input;
  final CalculationResult result;
  final DateTime date;
  
  CalculationHistoryItem({
    required this.id,
    required this.fuelType,
    required this.input,
    required this.result,
    required this.date,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fuelType': fuelType.index,
      'fuelPrice': input.fuelPrice,
      'distance': input.distance,
      'mileage': input.mileage,
      'fuelRequired': result.fuelRequired,
      'totalCost': result.totalCost,
      'date': date.millisecondsSinceEpoch,
    };
  }
  
  factory CalculationHistoryItem.fromJson(Map<String, dynamic> json) {
    final input = CalculationInput(
      fuelPrice: json['fuelPrice'],
      distance: json['distance'],
      mileage: json['mileage'],
    );
    
    final result = CalculationResult(
      fuelRequired: json['fuelRequired'],
      totalCost: json['totalCost'],
    );
    
    return CalculationHistoryItem(
      id: json['id'],
      fuelType: FuelType.values[json['fuelType']],
      input: input,
      result: result,
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }
}
