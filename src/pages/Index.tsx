
import React from 'react';
import Header from '@/components/Header';
import Calculator from '@/components/Calculator';
import { Separator } from "@/components/ui/separator";

const Index: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background to-secondary/30 px-4 py-12">
      <div className="container max-w-md mx-auto">
        <Header />
        <Separator className="my-8 bg-border/50" />
        <Calculator />
        
        <footer className="text-center text-xs text-muted-foreground mt-12 animate-fade-in">
          <p>© {new Date().getFullYear()} Fuel Calculator • Designed with ♥</p>
        </footer>
      </div>
    </div>
  );
};

export default Index;
