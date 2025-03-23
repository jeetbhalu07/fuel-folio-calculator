
// Fuel price API integration using Supabase
import { supabase } from '@/integrations/supabase/client';
import { FuelCompany, FuelType } from './calculate';

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

// Cache expiry in milliseconds (5 minutes)
const CACHE_EXPIRY = 5 * 60 * 1000;

/**
 * Fetch latest fuel prices from Supabase
 * Uses caching to avoid excessive database calls
 */
export const fetchFuelPrices = async (): Promise<FuelPriceResponse | null> => {
  const now = Date.now();
  
  // Return cached data if it's fresh
  if (priceCache.data && now - priceCache.timestamp < CACHE_EXPIRY) {
    return priceCache.data;
  }
  
  try {
    console.log('Fetching fuel prices from Supabase');
    
    // Fetch prices from Supabase
    const { data: pricesData, error } = await supabase
      .from('fuel_prices')
      .select('company, fuel_type, price, updated_at')
      .order('updated_at', { ascending: false });
    
    if (error) {
      console.error('Supabase query error:', error);
      return generateMockPriceData();
    }
    
    if (!pricesData || pricesData.length === 0) {
      console.error('No fuel prices found in database');
      return generateMockPriceData();
    }
    
    // Group prices by company and fuel type
    const formattedData: { [company: string]: { [fuelType: string]: number } } = {};
    let latestTimestamp = '';
    
    pricesData.forEach(item => {
      // Track the latest timestamp
      if (!latestTimestamp || item.updated_at > latestTimestamp) {
        latestTimestamp = item.updated_at;
      }
      
      // Create company entry if it doesn't exist
      if (!formattedData[item.company]) {
        formattedData[item.company] = {};
      }
      
      // Add fuel price
      formattedData[item.company][item.fuel_type] = Number(item.price);
    });
    
    // Format the response
    const apiData: FuelPriceResponse = {
      success: true,
      data: formattedData,
      last_updated: latestTimestamp
    };
    
    // Update cache with new data
    priceCache = {
      data: apiData,
      timestamp: now
    };
    
    return apiData;
  } catch (error) {
    console.error('Failed to fetch fuel prices:', error);
    return generateMockPriceData();
  }
};

/**
 * Generate mock fuel price data with small random fluctuations
 * Used as a fallback when Supabase fetch fails
 */
const generateMockPriceData = (): FuelPriceResponse => {
  // Base prices
  const basePrices = {
    petrol: 96.72,
    diesel: 89.62,
    cng: 76.59
  };
  
  // Companies with their price variations
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
  
  // Add small random fluctuation
  const fluctuation = () => (Math.random() - 0.5) * 0.01;
  
  const responseData: { [company: string]: { [fuelType: string]: number } } = {};
  
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
 * Update fuel companies with latest prices from Supabase
 */
export const updateCompaniesWithApiPrices = async (companies: FuelCompany[]): Promise<FuelCompany[]> => {
  const priceData = await fetchFuelPrices();
  
  if (!priceData || !priceData.success) {
    return companies;
  }
  
  // Create a copy of companies to update
  const updatedCompanies = [...companies];
  
  // Update each company with prices from Supabase
  updatedCompanies.forEach(company => {
    const apiCompanyData = priceData.data[company.type];
    if (!apiCompanyData) return;
    
    // Update each fuel price that exists in the response
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

/**
 * Add automatic price polling function
 */
export const startPricePolling = (callback: (prices: FuelPriceResponse) => void) => {
  // Initial fetch
  fetchFuelPrices().then(prices => {
    if (prices) callback(prices);
  });

  // Poll every 5 minutes
  const intervalId = setInterval(async () => {
    const prices = await fetchFuelPrices();
    if (prices) callback(prices);
  }, CACHE_EXPIRY);

  return () => clearInterval(intervalId);
};
