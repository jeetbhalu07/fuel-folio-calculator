
import React, { useEffect, useState } from 'react';
import { 
  getCompaniesForFuelType, 
  FuelType, 
  FuelCompany, 
  getCompanyFuelPrice 
} from '@/lib/calculate';
import { Car, Fuel, Cpu } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface CompanySelectorProps {
  selectedFuelType: FuelType;
  selectedCompany: FuelCompany;
  onCompanyChange: (company: FuelCompany) => void;
}

const CompanySelector: React.FC<CompanySelectorProps> = ({
  selectedFuelType,
  selectedCompany,
  onCompanyChange
}) => {
  const [companies, setCompanies] = useState<FuelCompany[]>([]);
  
  useEffect(() => {
    const availableCompanies = getCompaniesForFuelType(selectedFuelType);
    setCompanies(availableCompanies);
  }, [selectedFuelType]);

  const getIcon = (iconType: string) => {
    switch (iconType) {
      case 'gasStation':
        return <Fuel className="h-4 w-4 mr-2" />;
      case 'gasMeter':
        return <Cpu className="h-4 w-4 mr-2" />;
      default:
        return <Car className="h-4 w-4 mr-2" />;
    }
  };

  return (
    <div className="w-full mb-4 mt-2 animate-slide-up opacity-0 animate-delay-150">
      <Select
        value={selectedCompany.type}
        onValueChange={(value) => {
          const company = companies.find(c => c.type === value);
          if (company) {
            onCompanyChange(company);
          }
        }}
      >
        <SelectTrigger className="w-full h-12 bg-background/60 border-input/30 dark:border-input/20">
          <SelectValue placeholder="Select a company" />
        </SelectTrigger>
        <SelectContent>
          {companies.map((company) => (
            <SelectItem key={company.type} value={company.type}>
              <div className="flex items-center">
                {getIcon(company.icon)}
                <div>
                  <div className="font-medium">{company.shortName}</div>
                  <div className="text-xs text-muted-foreground">
                    {selectedFuelType.charAt(0).toUpperCase() + selectedFuelType.slice(1)} Price: 
                    ₹{getCompanyFuelPrice(company, selectedFuelType).toFixed(2)}
                  </div>
                </div>
              </div>
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};

export default CompanySelector;
