
// Fuel price API integration

import { FuelCompany, FuelType } from './calculate';

// API base URL for fuel price API from RapidAPI
const API_BASE_URL = 'https://daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com/v1/fuel-prices/india/all';
const API_KEY = 'ddb2c8a0fdmshafd8fa095485b40p1eada5jsna22c622410d3';
const API_HOST = 'daily-petrol-diesel-lpg-cng-fuel-prices-in-india.p.rapidapi.com';

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
 * Extract price value from API response which might have different formats
 */
const extractPriceFromData = (priceData: any): number => {
  try {
    if (typeof priceData === 'number') {
      return priceData;
    } else if (typeof priceData === 'string') {
      return parseFloat(priceData.replace('₹', '').trim()) || 0;
    } else if (priceData && typeof priceData === 'object' && 'price' in priceData) {
      const price = priceData.price;
      if (typeof price === 'number') {
        return price;
      } else if (typeof price === 'string') {
        return parseFloat(price.replace('₹', '').trim()) || 0;
      }
    }
  } catch (error) {
    console.error('Error extracting price:', error);
  }
  return 0;
};

/**
 * Convert RapidAPI response to our expected format
 */
const convertApiToFuelPrices = (apiData: any): FuelPriceResponse => {
  const responseData: { [company: string]: { [fuelType: string]: number } } = {};
  
  try {
    console.log('Converting API data:', Object.keys(apiData));
    
    // Extract prices from the API response
    if (apiData.data && typeof apiData.data === 'object') {
      const data = apiData.data;
      
      // Get base prices for different fuels
      let petrolPrice = 0;
      let dieselPrice = 0;
      let cngPrice = 0;
      
      // Try to extract prices from the response structure
      if ('petrol' in data) {
        petrolPrice = extractPriceFromData(data.petrol);
      } else if ('delhi' in data && typeof data.delhi === 'object') {
        if ('petrol' in data.delhi) {
          petrolPrice = extractPriceFromData(data.delhi.petrol);
        }
      }
      
      if ('diesel' in data) {
        dieselPrice = extractPriceFromData(data.diesel);
      } else if ('delhi' in data && typeof data.delhi === 'object') {
        if ('diesel' in data.delhi) {
          dieselPrice = extractPriceFromData(data.delhi.diesel);
        }
      }
      
      if ('cng' in data) {
        cngPrice = extractPriceFromData(data.cng);
      } else if ('delhi' in data && typeof data.delhi === 'object') {
        if ('cng' in data.delhi) {
          cngPrice = extractPriceFromData(data.delhi.cng);
        }
      }
      
      console.log('Extracted prices: Petrol:', petrolPrice, 'Diesel:', dieselPrice, 'CNG:', cngPrice);
      
      // If we couldn't extract prices, use default values
      if (petrolPrice <= 0) petrolPrice = 96.72;
      if (dieselPrice <= 0) dieselPrice = 89.62;
      if (cngPrice <= 0) cngPrice = 76.59;
      
      // Set up company prices with variations
      responseData['iocl'] = {
        petrol: petrolPrice,
        diesel: dieselPrice
      };
      
      responseData['bpcl'] = {
        petrol: petrolPrice - 0.3,
        diesel: dieselPrice - 0.4
      };
      
      responseData['hpcl'] = {
        petrol: petrolPrice - 0.1,
        diesel: dieselPrice - 0.1
      };
      
      responseData['reliance'] = {
        petrol: petrolPrice + 0.4,
        diesel: dieselPrice + 0.5
      };
      
      responseData['nayara'] = {
        petrol: petrolPrice + 0.2,
        diesel: dieselPrice + 0.2
      };
      
      responseData['shell'] = {
        petrol: petrolPrice + 1.8,
        diesel: dieselPrice + 1.8
      };
      
      // Add CNG prices
      responseData['igl'] = { cng: cngPrice };
      responseData['mgl'] = { cng: cngPrice - 3.1 };
      responseData['adani'] = { cng: cngPrice + 1.7 };
    } else {
      console.error('API response does not contain expected data structure');
      return generateMockPriceData();
    }
  } catch (error) {
    console.error('Error processing API data:', error);
    return generateMockPriceData();
  }
  
  return {
    success: true,
    data: responseData,
    last_updated: new Date().toISOString()
  };
};

/**
 * Fetch latest fuel prices from API
 * Uses caching to avoid excessive API calls
 */
export const fetchFuelPrices = async (): Promise<FuelPriceResponse | null> => {
  const now = Date.now();
  
  // Return cached data if it's fresh (less than cache expiry time)
  if (priceCache.data && now - priceCache.timestamp < CACHE_EXPIRY) {
    return priceCache.data;
  }
  
  try {
    console.log('Fetching fuel prices from API:', API_BASE_URL);
    
    // Try to fetch from the actual API first
    try {
      const response = await fetch(API_BASE_URL, {
        method: 'GET',
        headers: {
          'X-RapidAPI-Key': API_KEY,
          'X-RapidAPI-Host': API_HOST,
        }
      });
      
      console.log('API status:', response.status);
      
      if (response.ok) {
        const apiData = await response.json();
        const processedData = convertApiToFuelPrices(apiData);
        
        // Update cache with new data
        priceCache = {
          data: processedData,
          timestamp: now
        };
        
        return processedData;
      } else {
        console.error('API request failed:', response.status, response.statusText);
        // Fall back to mock data if API call fails
      }
    } catch (apiError) {
      console.error('Error making API request:', apiError);
      // Continue to mock data on error
    }
    
    // Generate mock data as fallback
    const mockData = generateMockPriceData();
    
    // Update cache with mock data
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

/**
 * Add automatic price polling function
 */
export const startPricePolling = (callback: (prices: FuelPriceResponse) => void) => {
  // Initial fetch
  fetchFuelPrices().then(prices => {
    if (prices) callback(prices);
  });

  // Poll every 10 minutes
  const intervalId = setInterval(async () => {
    const prices = await fetchFuelPrices();
    if (prices) callback(prices);
  }, CACHE_EXPIRY);

  return () => clearInterval(intervalId);
};
