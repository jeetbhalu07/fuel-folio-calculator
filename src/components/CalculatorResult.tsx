
import React from 'react';
import { CalculationResult } from '@/lib/calculate';
import { Separator } from "@/components/ui/separator";
import { motion } from "framer-motion";

interface CalculatorResultProps {
  result: CalculationResult;
  fuelUnit: string;
  className?: string;
}

const CalculatorResult: React.FC<CalculatorResultProps> = ({
  result,
  fuelUnit,
  className = ""
}) => {
  const { fuelRequired, totalCost } = result;
  
  return (
    <div className={`glass-card rounded-2xl p-6 mt-6 animate-scale-in opacity-0 ${className}`}>
      <h3 className="text-lg font-medium text-center mb-4">Calculation Results</h3>
      <Separator className="mb-4 bg-border/50" />
      
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm text-muted-foreground">Fuel Required:</span>
          <span className="text-lg font-semibold">
            {fuelRequired.toFixed(2)} {fuelUnit}
          </span>
        </div>
        
        <div className="flex justify-between items-center">
          <span className="text-sm text-muted-foreground">Total Cost:</span>
          <span className="text-xl font-bold text-primary">
            ₹{totalCost.toFixed(2)}
          </span>
        </div>
      </div>
    </div>
  );
};

export default CalculatorResult;
