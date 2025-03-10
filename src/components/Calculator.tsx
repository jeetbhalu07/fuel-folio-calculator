
import React, { useState, useEffect } from 'react';
import CalculatorInput from '@/components/CalculatorInput';
import CalculatorResult from '@/components/CalculatorResult';
import FuelTypeSelector from '@/components/FuelTypeSelector';
import CompanySelector from '@/components/CompanySelector';
import PurchaseCalculator from '@/components/PurchaseCalculator';
import { 
  calculateFuelCost, 
  getFuelUnit, 
  getDefaultValues,
  getDefaultCompany,
  getCompanyFuelPrice,
  getFuelCompanies,
  CalculationInput,
  FuelType,
  FuelCompany
} from '@/lib/calculate';
import { updateCompaniesWithApiPrices, getLastPriceUpdateTime } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { RotateCw, Calculator as CalculatorIcon, IndianRupee, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';

const Calculator: React.FC = () => {
  const [fuelType, setFuelType] = useState<FuelType>('petrol');
  const [companies, setCompanies] = useState<FuelCompany[]>(getFuelCompanies());
  const [selectedCompany, setSelectedCompany] = useState<FuelCompany>(getDefaultCompany('petrol'));
  const [inputs, setInputs] = useState<CalculationInput>(getDefaultValues('petrol'));
  const [result, setResult] = useState(calculateFuelCost(inputs));
  const [fuelUnit, setFuelUnit] = useState(getFuelUnit('petrol'));
  const [activeTab, setActiveTab] = useState("trip");
  const [isLoadingPrices, setIsLoadingPrices] = useState(false);
  const [lastUpdateTime, setLastUpdateTime] = useState('');
  
  // Load prices from API when component mounts
  useEffect(() => {
    refreshPrices();
  }, []);
  
  // Update everything when fuel type changes
  useEffect(() => {
    const company = getDefaultCompany(fuelType);
    setSelectedCompany(company);
    
    const defaultValues = getDefaultValues(fuelType);
    // Update with company's fuel price
    defaultValues.fuelPrice = getCompanyFuelPrice(company, fuelType);
    
    setInputs(defaultValues);
    setFuelUnit(getFuelUnit(fuelType));
    setResult(calculateFuelCost(defaultValues));
  }, [fuelType, companies]);

  // Recalculate result when inputs change
  useEffect(() => {
    setResult(calculateFuelCost(inputs));
  }, [inputs]);

  const refreshPrices = async () => {
    setIsLoadingPrices(true);
    try {
      const updatedCompanies = await updateCompaniesWithApiPrices(getFuelCompanies());
      setCompanies(updatedCompanies);
      setLastUpdateTime(getLastPriceUpdateTime());
      
      // Update selected company's fuel price
      if (selectedCompany) {
        const refreshedCompany = updatedCompanies.find(c => c.type === selectedCompany.type);
        if (refreshedCompany) {
          setSelectedCompany(refreshedCompany);
          
          // Update fuel price in inputs
          setInputs(prev => ({
            ...prev,
            fuelPrice: getCompanyFuelPrice(refreshedCompany, fuelType)
          }));
        }
      }
      
      toast.success("Fuel prices updated successfully", {
        description: `Latest prices as of ${getLastPriceUpdateTime()}`,
      });
    } catch (error) {
      console.error("Failed to update prices:", error);
      toast.error("Failed to update fuel prices");
    } finally {
      setIsLoadingPrices(false);
    }
  };

  const handleFuelTypeChange = (type: FuelType) => {
    setFuelType(type);
  };

  const handleCompanyChange = (company: FuelCompany) => {
    setSelectedCompany(company);
    
    // Update just the fuel price based on the selected company
    setInputs(prev => ({
      ...prev,
      fuelPrice: getCompanyFuelPrice(company, fuelType)
    }));
  };

  const handleInputChange = (field: keyof CalculationInput, value: number) => {
    setInputs(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleReset = () => {
    const defaultValues = getDefaultValues(fuelType);
    // Use the current company's price
    defaultValues.fuelPrice = getCompanyFuelPrice(selectedCompany, fuelType);
    setInputs(defaultValues);
  };

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="flex justify-between items-center mb-2">
        <FuelTypeSelector 
          selectedFuelType={fuelType} 
          onChange={handleFuelTypeChange} 
        />
        
        <Button
          variant="outline"
          size="sm"
          onClick={refreshPrices}
          disabled={isLoadingPrices}
          className="h-8 animate-slide-up opacity-0 animate-delay-300"
        >
          {isLoadingPrices ? (
            <RefreshCw className="h-3.5 w-3.5 mr-1.5 animate-spin" />
          ) : (
            <RefreshCw className="h-3.5 w-3.5 mr-1.5" />
          )}
          Refresh Prices
        </Button>
      </div>
      
      {lastUpdateTime && (
        <p className="text-xs text-muted-foreground text-right mb-2 animate-slide-up opacity-0 animate-delay-400">
          Prices updated: {lastUpdateTime}
        </p>
      )}
      
      <CompanySelector
        selectedFuelType={fuelType}
        selectedCompany={selectedCompany}
        onCompanyChange={handleCompanyChange}
        companies={companies}
      />
      
      <Tabs defaultValue="trip" value={activeTab} onValueChange={setActiveTab} className="w-full mt-4">
        <TabsList className="grid w-full grid-cols-2 h-12">
          <TabsTrigger value="trip" className="flex items-center gap-2">
            <CalculatorIcon className="h-4 w-4" />
            <span>Trip Calculator</span>
          </TabsTrigger>
          <TabsTrigger value="purchase" className="flex items-center gap-2">
            <IndianRupee className="h-4 w-4" />
            <span>Purchase Calculator</span>
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="trip" className="mt-4">
          <div className="glass-card rounded-2xl p-6 shadow-lg">
            <CalculatorInput
              id="fuel-price"
              label="Fuel Price"
              value={inputs.fuelPrice}
              onChange={(value) => handleInputChange('fuelPrice', value)}
              unit={`₹ per ${fuelUnit}`}
              placeholder="Enter fuel price"
              animationDelay="animate-delay-100"
            />
            
            <CalculatorInput
              id="distance"
              label="Distance"
              value={inputs.distance}
              onChange={(value) => handleInputChange('distance', value)}
              unit="km"
              placeholder="Enter distance"
              animationDelay="animate-delay-200"
            />
            
            <CalculatorInput
              id="mileage"
              label="Vehicle Mileage"
              value={inputs.mileage}
              onChange={(value) => handleInputChange('mileage', value)}
              unit={`km per ${fuelUnit}`}
              placeholder="Enter mileage"
              animationDelay="animate-delay-300"
            />
            
            <Button 
              onClick={handleReset}
              variant="outline" 
              className="w-full h-12 mt-2 rounded-xl animate-slide-up opacity-0 animate-delay-400 border-secondary-foreground/20 hover:bg-secondary/80"
            >
              <RotateCw className="mr-2 h-4 w-4" />
              Reset to Defaults
            </Button>
          </div>
          
          <CalculatorResult 
            result={result} 
            fuelUnit={fuelUnit}
          />
        </TabsContent>
        
        <TabsContent value="purchase" className="mt-4">
          <PurchaseCalculator 
            selectedFuelType={fuelType} 
            fuelPrice={inputs.fuelPrice} 
          />
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default Calculator;
