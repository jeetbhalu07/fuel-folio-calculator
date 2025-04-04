
import 'package:flutter/material.dart';
import '../models/calculation.dart';
import '../models/fuel_company.dart';

class CompanySelector extends StatelessWidget {
  final FuelType selectedFuelType;
  final FuelCompany selectedCompany;
  final Function(FuelCompany) onChanged;
  final List<FuelCompany>? companies;
  final bool isRefreshing;

  const CompanySelector({
    Key? key,
    required this.selectedFuelType,
    required this.selectedCompany,
    required this.onChanged,
    this.companies,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final availableCompanies = companies != null 
        ? getCompaniesForFuelTypeFromList(selectedFuelType, companies!) 
        : getCompaniesForFuelType(selectedFuelType);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]!.withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
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
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: Stack(
            children: [
              DropdownButton<FuelCompany>(
                value: selectedCompany,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).primaryColor,
                ),
                dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onChanged: isRefreshing 
                    ? null 
                    : (FuelCompany? newValue) {
                        if (newValue != null) {
                          onChanged(newValue);
                        }
                      },
                items: availableCompanies.map<DropdownMenuItem<FuelCompany>>((FuelCompany company) {
                  return DropdownMenuItem<FuelCompany>(
                    value: company,
                    child: Row(
                      children: [
                        Icon(
                          company.icon,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                company.shortName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${fuelTypeToString(selectedFuelType)} Price: ₹${getCompanyFuelPrice(company, selectedFuelType).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
              // Loading indicator overlay
              if (isRefreshing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20, 
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String fuelTypeToString(FuelType type) {
    switch (type) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.cng:
        return 'CNG';
    }
  }
  
  List<FuelCompany> getCompaniesForFuelTypeFromList(FuelType fuelType, List<FuelCompany> allCompanies) {
    switch (fuelType) {
      case FuelType.petrol:
      case FuelType.diesel:
        return allCompanies.where((company) => 
            company.fuelPrices.containsKey(fuelType.toString().split('.').last)).toList();
      case FuelType.cng:
        return allCompanies.where((company) => company.supportsCNG).toList();
    }
  }
}
