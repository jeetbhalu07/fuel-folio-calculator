
import React from 'react';
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface CalculatorInputProps {
  id: string;
  label: string;
  value: number;
  onChange: (value: number) => void;
  unit?: string;
  min?: number;
  max?: number;
  step?: number;
  placeholder?: string;
  className?: string;
  animationDelay?: string;
}

const CalculatorInput: React.FC<CalculatorInputProps> = ({
  id,
  label,
  value,
  onChange,
  unit,
  min = 0,
  max,
  step = 0.01,
  placeholder,
  className = "",
  animationDelay = ""
}) => {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = parseFloat(e.target.value);
    if (!isNaN(newValue)) {
      onChange(newValue);
    } else if (e.target.value === '') {
      onChange(0);
    }
  };

  return (
    <div className={`relative mb-6 animate-slide-up opacity-0 ${animationDelay} ${className}`}>
      <div className="flex justify-between items-center mb-2">
        <Label 
          htmlFor={id} 
          className="text-sm font-medium text-foreground/80"
        >
          {label}
        </Label>
        {unit && (
          <span className="text-xs text-muted-foreground font-medium">
            {unit}
          </span>
        )}
      </div>
      <Input
        id={id}
        type="number"
        value={value || ''}
        onChange={handleChange}
        min={min}
        max={max}
        step={step}
        placeholder={placeholder}
        className="w-full h-12 px-4 bg-secondary/50 border-secondary-foreground/10 rounded-xl input-transition focus:ring-2 focus:ring-primary/20 focus:border-primary/30"
      />
    </div>
  );
};

export default CalculatorInput;
