
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
