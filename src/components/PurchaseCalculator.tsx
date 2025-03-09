
import React, { useState, useEffect } from 'react';
import CalculatorInput from '@/components/CalculatorInput';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { FuelType, getCompanyFuelPrice, getFuelUnit } from '@/lib/calculate';
import { Upload, FileCheck, AlertCircle } from 'lucide-react';

interface PurchaseCalculatorProps {
  selectedFuelType: FuelType;
  fuelPrice: number;
}

const PurchaseCalculator: React.FC<PurchaseCalculatorProps> = ({
  selectedFuelType,
  fuelPrice,
}) => {
  const [amountPaid, setAmountPaid] = useState(200);
  const [fuelQuantity, setFuelQuantity] = useState(0);
  const [billQuantity, setBillQuantity] = useState(0);
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null);
  const fuelUnit = getFuelUnit(selectedFuelType);

  useEffect(() => {
    if (fuelPrice > 0) {
      setFuelQuantity(Number((amountPaid / fuelPrice).toFixed(2)));
    }
  }, [amountPaid, fuelPrice]);

  const handleVerifyBill = () => {
    if (billQuantity <= 0) {
      toast.error("Please enter the fuel quantity from your bill");
      return;
    }

    const expectedAmount = billQuantity * fuelPrice;
    const expectedRounded = Number(expectedAmount.toFixed(2));
    const amountRounded = Number(amountPaid.toFixed(2));
    
    // Allow a small tolerance for rounding errors
    const isValid = Math.abs(expectedRounded - amountRounded) <= 0.05;
    
    setVerificationResult(isValid);
    
    if (isValid) {
      toast.success("Bill verification successful! The amount matches the fuel quantity.");
    } else {
      toast.error("Bill verification failed! There's a discrepancy between the amount and fuel quantity.");
    }
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    // This is a mock implementation. In a real app, you would use OCR to extract 
    // values from the uploaded bill images
    toast.info("Bill uploaded! This is a simulation. In a real app, OCR would extract values from your bill.", {
      duration: 5000,
    });
    
    // Simulate extracting data from the bill
    setTimeout(() => {
      // Generate a slightly different quantity to simulate real-world scenarios
      // Sometimes correct, sometimes incorrect
      const randomOffset = Math.random() > 0.5 ? 0 : (Math.random() * 0.5) - 0.25;
      const extractedQuantity = Number((amountPaid / fuelPrice + randomOffset).toFixed(2));
      
      setBillQuantity(extractedQuantity);
      toast.success(`Extracted fuel quantity: ${extractedQuantity} ${fuelUnit}`);
    }, 1500);
  };

  return (
    <div className="glass-card rounded-2xl p-6 my-6 animate-scale-in opacity-0">
      <h3 className="text-lg font-medium text-center mb-4">Purchase Calculator</h3>
      <Separator className="mb-4 bg-border/50" />
      
      <CalculatorInput
        id="amount-paid"
        label="Amount Paid"
        value={amountPaid}
        onChange={setAmountPaid}
        unit="$"
        placeholder="Enter amount paid"
        animationDelay="animate-delay-100"
      />
      
      <div className="flex justify-between items-center mb-4 p-3 bg-secondary/30 rounded-xl">
        <span className="text-sm text-muted-foreground">Fuel Quantity:</span>
        <span className="text-lg font-semibold">
          {fuelQuantity} {fuelUnit}
        </span>
      </div>
      
      <Separator className="my-4 bg-border/50" />
      
      <h4 className="text-md font-medium mb-2">Verify Your Bill</h4>
      
      <div className="flex items-center gap-2 mb-4">
        <Button
          variant="outline"
          className="flex-1 h-12 relative"
          onClick={() => document.getElementById('bill-upload')?.click()}
        >
          <input
            id="bill-upload"
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileUpload}
          />
          <Upload className="mr-2 h-4 w-4" />
          Upload Bill
        </Button>
        
        <CalculatorInput
          id="bill-quantity"
          label="Quantity on Bill"
          value={billQuantity}
          onChange={setBillQuantity}
          unit={fuelUnit}
          placeholder="Enter quantity from bill"
          className="flex-1"
        />
      </div>
      
      <Button 
        onClick={handleVerifyBill}
        className="w-full h-12 mb-2"
      >
        Verify Bill
      </Button>
      
      {verificationResult !== null && (
        <div className={`mt-4 p-3 rounded-xl flex items-center ${
          verificationResult ? 'bg-green-500/10 text-green-600' : 'bg-red-500/10 text-red-600'
        }`}>
          {verificationResult ? (
            <>
              <FileCheck className="h-5 w-5 mr-2" />
              <span>Bill is correct! The fuel quantity matches the amount paid.</span>
            </>
          ) : (
            <>
              <AlertCircle className="h-5 w-5 mr-2" />
              <span>Bill may be incorrect! The fuel quantity does not match the amount paid.</span>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default PurchaseCalculator;
