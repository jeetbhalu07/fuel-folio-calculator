
export type FuelType = 'petrol' | 'diesel' | 'cng';

export interface CalculationInput {
  fuelPrice: number;
  distance: number;
  mileage: number;
}

export interface CalculationResult {
  fuelRequired: number;
  totalCost: number;
}

export type FuelCompanyType = 
  | 'iocl' | 'bpcl' | 'hpcl' 
  | 'reliance' | 'nayara' | 'shell'
  | 'igl' | 'mgl' | 'ggl' | 'adani' | 'ioagpl' 
  | 'gail' | 'torrent' | 'hpcl_cng' | 'bpcl_igl';

export interface FuelCompany {
  type: FuelCompanyType;
  name: string;
  shortName: string;
  icon: string;
  fuelPrices: Record<string, number>;
  supportsCNG?: boolean;
}

export const calculateFuelCost = (input: CalculationInput): CalculationResult => {
  const { fuelPrice, distance, mileage } = input;
  
  // Avoid division by zero
  if (mileage <= 0) {
    return { fuelRequired: 0, totalCost: 0 };
  }
  
  const fuelRequired = distance / mileage;
  const totalCost = fuelRequired * fuelPrice;
  
  return {
    fuelRequired: parseFloat(fuelRequired.toFixed(2)),
    totalCost: parseFloat(totalCost.toFixed(2))
  };
};

export const getFuelUnit = (fuelType: FuelType): string => {
  return fuelType === 'cng' ? 'kg' : 'liter';
};

export const getDefaultValues = (fuelType: FuelType): CalculationInput => {
  switch (fuelType) {
    case 'petrol':
      return { fuelPrice: 95.41, distance: 100, mileage: 15 };
    case 'diesel':
      return { fuelPrice: 88.67, distance: 100, mileage: 20 };
    case 'cng':
      return { fuelPrice: 76.21, distance: 100, mileage: 25 };
    default:
      return { fuelPrice: 0, distance: 0, mileage: 0 };
  }
};

export const getFuelCompanies = (): FuelCompany[] => {
  return [
    // PSU Oil Companies
    {
      type: 'iocl',
      name: 'Indian Oil Corporation Limited',
      shortName: 'IndianOil',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 96.72,
        'diesel': 89.62,
      },
    },
    {
      type: 'bpcl',
      name: 'Bharat Petroleum Corporation Limited',
      shortName: 'BPCL',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 96.43,
        'diesel': 89.27,
      },
    },
    {
      type: 'hpcl',
      name: 'Hindustan Petroleum Corporation Limited',
      shortName: 'HPCL',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 96.66,
        'diesel': 89.52,
      },
    },
    
    // Private Oil Companies
    {
      type: 'reliance',
      name: 'Reliance Industries Limited',
      shortName: 'Reliance',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 97.12,
        'diesel': 90.05,
      },
    },
    {
      type: 'nayara',
      name: 'Nayara Energy',
      shortName: 'Nayara',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 96.92,
        'diesel': 89.77,
      },
    },
    {
      type: 'shell',
      name: 'Shell India',
      shortName: 'Shell',
      icon: 'gasStation',
      fuelPrices: {
        'petrol': 98.45,
        'diesel': 91.22,
      },
    },
    
    // CNG Suppliers
    {
      type: 'igl',
      name: 'Indraprastha Gas Limited',
      shortName: 'IGL',
      icon: 'gasMeter',
      fuelPrices: {
        'cng': 76.59,
      },
      supportsCNG: true,
    },
    {
      type: 'mgl',
      name: 'Mahanagar Gas Limited',
      shortName: 'MGL',
      icon: 'gasMeter',
      fuelPrices: {
        'cng': 74.21,
      },
      supportsCNG: true,
    },
    {
      type: 'adani',
      name: 'Adani Total Gas Limited',
      shortName: 'Adani Gas',
      icon: 'gasMeter',
      fuelPrices: {
        'cng': 77.89,
      },
      supportsCNG: true,
    },
  ];
};

export const getDefaultCompany = (fuelType: FuelType): FuelCompany => {
  const companies = getFuelCompanies();
  
  if (fuelType === 'cng') {
    return companies.find(company => company.supportsCNG) || companies[0];
  } else {
    return companies[0]; // Return IOCL by default for petrol/diesel
  }
};

export const getCompanyFuelPrice = (company: FuelCompany, fuelType: FuelType): number => {
  return company.fuelPrices[fuelType] || 0;
};

export const getCompaniesForFuelType = (fuelType: FuelType): FuelCompany[] => {
  const allCompanies = getFuelCompanies();
  
  if (fuelType === 'cng') {
    return allCompanies.filter(company => company.supportsCNG);
  } else {
    return allCompanies.filter(company => company.fuelPrices[fuelType] !== undefined);
  }
};
