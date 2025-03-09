
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
  CalculationInput,
  FuelType,
  FuelCompany
} from '@/lib/calculate';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { RotateCw, Calculator as CalculatorIcon, DollarSign } from 'lucide-react';

const Calculator: React.FC = () => {
  const [fuelType, setFuelType] = useState<FuelType>('petrol');
  const [selectedCompany, setSelectedCompany] = useState<FuelCompany>(getDefaultCompany('petrol'));
  const [inputs, setInputs] = useState<CalculationInput>(getDefaultValues('petrol'));
  const [result, setResult] = useState(calculateFuelCost(inputs));
  const [fuelUnit, setFuelUnit] = useState(getFuelUnit('petrol'));
  const [activeTab, setActiveTab] = useState("trip");
  
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
  }, [fuelType]);

  // Recalculate result when inputs change
  useEffect(() => {
    setResult(calculateFuelCost(inputs));
  }, [inputs]);

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
      <FuelTypeSelector 
        selectedFuelType={fuelType} 
        onChange={handleFuelTypeChange} 
      />
      
      <CompanySelector
        selectedFuelType={fuelType}
        selectedCompany={selectedCompany}
        onCompanyChange={handleCompanyChange}
      />
      
      <Tabs defaultValue="trip" value={activeTab} onValueChange={setActiveTab} className="w-full mt-4">
        <TabsList className="grid w-full grid-cols-2 h-12">
          <TabsTrigger value="trip" className="flex items-center gap-2">
            <CalculatorIcon className="h-4 w-4" />
            <span>Trip Calculator</span>
          </TabsTrigger>
          <TabsTrigger value="purchase" className="flex items-center gap-2">
            <DollarSign className="h-4 w-4" />
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
              unit={`$ per ${fuelUnit}`}
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
