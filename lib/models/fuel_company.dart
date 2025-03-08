
import 'package:flutter/material.dart';

enum FuelCompanyType {
  iocl,
  bpcl,
  hpcl,
  reliance,
  nayara,
  shell,
  igl,
  mgl,
  ggl,
  adani,
  ioagpl,
  gail,
  torrent,
  hpcl_cng,
  bpcl_igl
}

class FuelCompany {
  final FuelCompanyType type;
  final String name;
  final String shortName;
  final IconData icon;
  final Map<String, double> fuelPrices;
  final bool supportsCNG;

  const FuelCompany({
    required this.type,
    required this.name,
    required this.shortName,
    required this.icon,
    required this.fuelPrices,
    this.supportsCNG = false,
  });
}

List<FuelCompany> getFuelCompanies() {
  return [
    // PSU Oil Companies
    FuelCompany(
      type: FuelCompanyType.iocl,
      name: 'Indian Oil Corporation Limited',
      shortName: 'IndianOil',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 96.72,
        'diesel': 89.62,
      },
    ),
    FuelCompany(
      type: FuelCompanyType.bpcl,
      name: 'Bharat Petroleum Corporation Limited',
      shortName: 'BPCL',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 96.43,
        'diesel': 89.27,
      },
    ),
    FuelCompany(
      type: FuelCompanyType.hpcl,
      name: 'Hindustan Petroleum Corporation Limited',
      shortName: 'HPCL',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 96.66,
        'diesel': 89.52,
      },
    ),
    
    // Private Oil Companies
    FuelCompany(
      type: FuelCompanyType.reliance,
      name: 'Reliance Industries Limited',
      shortName: 'Reliance',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 97.12,
        'diesel': 90.05,
      },
    ),
    FuelCompany(
      type: FuelCompanyType.nayara,
      name: 'Nayara Energy',
      shortName: 'Nayara',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 96.92,
        'diesel': 89.77,
      },
    ),
    FuelCompany(
      type: FuelCompanyType.shell,
      name: 'Shell India',
      shortName: 'Shell',
      icon: Icons.local_gas_station,
      fuelPrices: {
        'petrol': 98.45,
        'diesel': 91.22,
      },
    ),
    
    // CNG Suppliers
    FuelCompany(
      type: FuelCompanyType.igl,
      name: 'Indraprastha Gas Limited',
      shortName: 'IGL',
      icon: Icons.gas_meter,
      fuelPrices: {
        'cng': 76.59,
      },
      supportsCNG: true,
    ),
    FuelCompany(
      type: FuelCompanyType.mgl,
      name: 'Mahanagar Gas Limited',
      shortName: 'MGL',
      icon: Icons.gas_meter,
      fuelPrices: {
        'cng': 74.21,
      },
      supportsCNG: true,
    ),
    FuelCompany(
      type: FuelCompanyType.adani,
      name: 'Adani Total Gas Limited',
      shortName: 'Adani Gas',
      icon: Icons.gas_meter,
      fuelPrices: {
        'cng': 77.89,
      },
      supportsCNG: true,
    ),
  ];
}

FuelCompany getDefaultCompany(FuelType fuelType) {
  final companies = getFuelCompanies();
  
  if (fuelType == FuelType.cng) {
    return companies.firstWhere((company) => company.supportsCNG);
  } else {
    return companies.first; // Return IOCL by default for petrol/diesel
  }
}

double getCompanyFuelPrice(FuelCompany company, FuelType fuelType) {
  switch (fuelType) {
    case FuelType.petrol:
      return company.fuelPrices['petrol'] ?? 0.0;
    case FuelType.diesel:
      return company.fuelPrices['diesel'] ?? 0.0;
    case FuelType.cng:
      return company.fuelPrices['cng'] ?? 0.0;
  }
}

// Get only companies that support a specific fuel type
List<FuelCompany> getCompaniesForFuelType(FuelType fuelType) {
  final allCompanies = getFuelCompanies();
  
  switch (fuelType) {
    case FuelType.petrol:
    case FuelType.diesel:
      return allCompanies.where((company) => 
          company.fuelPrices.containsKey(fuelType.toString().split('.').last)).toList();
    case FuelType.cng:
      return allCompanies.where((company) => company.supportsCNG).toList();
  }
}
