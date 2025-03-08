
import React from 'react';
import { GasPump } from 'lucide-react';

const Header: React.FC = () => {
  return (
    <header className="mb-8 text-center animate-fade-in">
      <div className="flex items-center justify-center gap-2 mb-2">
        <GasPump className="h-8 w-8 text-primary" />
        <h1 className="text-3xl font-bold tracking-tight">Fuel Calc</h1>
      </div>
      <p className="text-muted-foreground max-w-md mx-auto">
        Calculate your fuel costs quickly and efficiently
      </p>
    </header>
  );
};

export default Header;
