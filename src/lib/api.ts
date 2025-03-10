
// Fuel price API integration

import { FuelCompany, FuelType } from './calculate';

// API base URL - replace with actual fuel price API when available
const API_BASE_URL = 'https://fuel-price-api.example.com';

// Interface for API response
interface FuelPriceResponse {
  success: boolean;
  data: {
    [company: string]: {
      [fuelType: string]: number;
    };
  };
  last_updated: string;
}

// Cache to store fetched prices with timestamp
let priceCache: {
  data: FuelPriceResponse | null;
  timestamp: number;
} = {
  data: null,
  timestamp: 0
};

// Cache expiry in milliseconds (10 minutes)
const CACHE_EXPIRY = 10 * 60 * 1000;

/**
 * Fetch latest fuel prices from API
 * Uses caching to avoid excessive API calls
 */
export const fetchFuelPrices = async (): Promise<FuelPriceResponse | null> => {
  const now = Date.now();
  
  // Return cached data if it's fresh
  if (priceCache.data && now - priceCache.timestamp < CACHE_EXPIRY) {
    return priceCache.data;
  }
  
  try {
    // In a real implementation, you would fetch from an actual API
    // For now, we'll use a mock that simulates API behavior
    
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // Mock response with random price fluctuations
    const mockData = generateMockPriceData();
    
    // Update cache
    priceCache = {
      data: mockData,
      timestamp: now
    };
    
    return mockData;
  } catch (error) {
    console.error('Failed to fetch fuel prices:', error);
    return null;
  }
};

/**
 * Generate mock fuel price data with small random fluctuations
 * This simulates a real API response during development
 */
const generateMockPriceData = (): FuelPriceResponse => {
  // Base prices for different fuel types
  const basePrices = {
    petrol: 96.72,
    diesel: 89.62,
    cng: 76.59
  };
  
  // Companies with their price variations (percentage difference from base)
  const companyVariations = {
    iocl: { petrol: 0, diesel: 0 },
    bpcl: { petrol: -0.3, diesel: -0.4 },
    hpcl: { petrol: -0.1, diesel: -0.1 },
    reliance: { petrol: 0.4, diesel: 0.5 },
    nayara: { petrol: 0.2, diesel: 0.2 },
    shell: { petrol: 1.8, diesel: 1.8 },
    igl: { cng: 0 },
    mgl: { cng: -3.1 },
    adani: { cng: 1.7 }
  };
  
  // Add random daily fluctuation (-0.5% to +0.5%)
  const fluctuation = () => (Math.random() - 0.5) * 0.01;
  
  // Generate response data
  const responseData: { [company: string]: { [fuelType: string]: number } } = {};
  
  // Fill in the data for each company
  Object.entries(companyVariations).forEach(([company, fuels]) => {
    responseData[company] = {};
    
    Object.entries(fuels).forEach(([fuelType, variation]) => {
      const basePrice = basePrices[fuelType as keyof typeof basePrices];
      const variationFactor = 1 + (variation / 100) + fluctuation();
      responseData[company][fuelType] = parseFloat((basePrice * variationFactor).toFixed(2));
    });
  });
  
  return {
    success: true,
    data: responseData,
    last_updated: new Date().toISOString()
  };
};

/**
 * Update fuel companies with latest prices from API
 */
export const updateCompaniesWithApiPrices = async (companies: FuelCompany[]): Promise<FuelCompany[]> => {
  const priceData = await fetchFuelPrices();
  
  if (!priceData || !priceData.success) {
    return companies;
  }
  
  // Create a copy of companies to update
  const updatedCompanies = [...companies];
  
  // Update each company with prices from API
  updatedCompanies.forEach(company => {
    const apiCompanyData = priceData.data[company.type];
    if (!apiCompanyData) return;
    
    // Update each fuel price that exists in the API response
    Object.entries(apiCompanyData).forEach(([fuelType, price]) => {
      if (company.fuelPrices[fuelType] !== undefined) {
        company.fuelPrices[fuelType] = price;
      }
    });
  });
  
  return updatedCompanies;
};

/**
 * Get the last update time for fuel prices
 */
export const getLastPriceUpdateTime = (): string => {
  if (!priceCache.data) return 'Not available';
  
  try {
    const date = new Date(priceCache.data.last_updated);
    return date.toLocaleString();
  } catch (e) {
    return 'Unknown';
  }
};
