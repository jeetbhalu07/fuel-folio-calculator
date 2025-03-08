
import React, { useState, useEffect, useRef } from 'react';
import { FuelType } from '@/lib/calculate';
import { Droplet, Cpu, Car } from 'lucide-react';

interface FuelTypeSelectorProps {
  selectedFuelType: FuelType;
  onChange: (fuelType: FuelType) => void;
}

const FuelTypeSelector: React.FC<FuelTypeSelectorProps> = ({
  selectedFuelType,
  onChange
}) => {
  const [indicatorStyle, setIndicatorStyle] = useState({});
  const tabsRef = useRef<HTMLDivElement>(null);
  
  const fuelTypes: { type: FuelType; label: string; icon: React.ReactNode }[] = [
    { type: 'petrol', label: 'Petrol', icon: <Droplet className="h-4 w-4" /> },
    { type: 'diesel', label: 'Diesel', icon: <Car className="h-4 w-4" /> },
    { type: 'cng', label: 'CNG Gas', icon: <Cpu className="h-4 w-4" /> }
  ];

  useEffect(() => {
    updateIndicator();
    // Add resize listener to handle screen size changes
    window.addEventListener('resize', updateIndicator);
    return () => window.removeEventListener('resize', updateIndicator);
  }, [selectedFuelType]);

  const updateIndicator = () => {
    if (!tabsRef.current) return;
    
    const tabs = Array.from(tabsRef.current.children);
    const activeTab = tabs.find(tab => 
      (tab as HTMLElement).dataset.type === selectedFuelType
    ) as HTMLElement;
    
    if (activeTab) {
      const containerRect = tabsRef.current.getBoundingClientRect();
      const activeRect = activeTab.getBoundingClientRect();
      
      setIndicatorStyle({
        width: `${activeRect.width}px`,
        transform: `translateX(${activeRect.left - containerRect.left}px)`,
        transition: 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), width 0.3s cubic-bezier(0.16, 1, 0.3, 1)'
      });
    }
  };

  return (
    <div className="relative mb-8 animate-slide-up opacity-0">
      <div 
        className="flex bg-secondary/50 p-1 rounded-xl relative overflow-hidden"
        ref={tabsRef}
      >
        {fuelTypes.map(({ type, label, icon }) => (
          <button
            key={type}
            data-type={type}
            className={`flex items-center justify-center space-x-2 py-2 px-4 flex-1 z-10 transition-colors duration-200 ${
              selectedFuelType === type 
                ? 'text-white' 
                : 'text-foreground/60 hover:text-foreground/90'
            }`}
            onClick={() => onChange(type)}
          >
            {icon}
            <span className="font-medium text-sm">{label}</span>
          </button>
        ))}
        
        <div 
          className="absolute bg-primary rounded-lg h-[calc(100%-8px)] top-1 z-0 transition-all"
          style={indicatorStyle}
        />
      </div>
    </div>
  );
};

export default FuelTypeSelector;
