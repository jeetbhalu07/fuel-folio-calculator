
import React, { useState, useEffect } from 'react';
import CalculatorInput from '@/components/CalculatorInput';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { FuelType, getCompanyFuelPrice, getFuelUnit } from '@/lib/calculate';
import { Upload, FileCheck, AlertCircle, Save, History } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import PurchaseHistory from '@/components/PurchaseHistory';

interface PurchaseCalculatorProps {
  selectedFuelType: FuelType;
  fuelPrice: number;
}

// Define a purchase history item interface
export interface PurchaseHistoryItem {
  id: string;
  date: Date;
  amountPaid: number;
  fuelQuantity: number;
  fuelType: FuelType;
  verified: boolean;
}

// For simplicity, we're storing history items in localStorage
const savePurchaseToHistory = (item: Omit<PurchaseHistoryItem, 'id' | 'date'>) => {
  const id = Date.now().toString();
  const historyItem: PurchaseHistoryItem = {
    ...item,
    id,
    date: new Date()
  };
  
  const history = getPurchaseHistory();
  localStorage.setItem('purchaseHistory', JSON.stringify([historyItem, ...history]));
  
  return historyItem;
};

export const getPurchaseHistory = (): PurchaseHistoryItem[] => {
  const historyData = localStorage.getItem('purchaseHistory');
  if (!historyData) return [];
  
  try {
    const parsedData = JSON.parse(historyData);
    return parsedData.map((item: any) => ({
      ...item,
      date: new Date(item.date)
    }));
  } catch (error) {
    console.error('Failed to parse purchase history', error);
    return [];
  }
};

const PurchaseCalculator: React.FC<PurchaseCalculatorProps> = ({
  selectedFuelType,
  fuelPrice,
}) => {
  const [amountPaid, setAmountPaid] = useState(200);
  const [fuelQuantity, setFuelQuantity] = useState(0);
  const [billQuantity, setBillQuantity] = useState(0);
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [history, setHistory] = useState<PurchaseHistoryItem[]>([]);
  const fuelUnit = getFuelUnit(selectedFuelType);

  useEffect(() => {
    if (fuelPrice > 0) {
      setFuelQuantity(Number((amountPaid / fuelPrice).toFixed(2)));
    }
  }, [amountPaid, fuelPrice]);

  useEffect(() => {
    // Load purchase history when component mounts
    setHistory(getPurchaseHistory());
  }, []);

  const verifyBill = (quantity: number) => {
    if (quantity <= 0) {
      toast.error("Invalid fuel quantity detected");
      return false;
    }

    const expectedAmount = quantity * fuelPrice;
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
    
    return isValid;
  };

  const saveToHistory = (isVerified: boolean) => {
    const newHistoryItem = savePurchaseToHistory({
      amountPaid,
      fuelQuantity: billQuantity > 0 ? billQuantity : fuelQuantity,
      fuelType: selectedFuelType,
      verified: isVerified
    });
    
    // Update local state with the new item
    setHistory(prev => [newHistoryItem, ...prev]);
    
    toast.success("Purchase calculation saved to history!", {
      description: `Amount: ₹${amountPaid.toFixed(2)}, Quantity: ${fuelQuantity} ${fuelUnit}`,
      duration: 4000,
    });
  };

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    toast.info("Processing bill...", {
      duration: 2000,
    });
    
    // Simulate extracting data from the bill
    setTimeout(() => {
      // Simulate extracting an amount from the bill
      // In a real app, OCR would extract the actual amount from the bill image
      const extractedAmount = Math.floor(Math.random() * 1000) + 100; // Random amount between 100-1100
      setAmountPaid(extractedAmount);
      
      toast.success(`Extracted amount: ₹${extractedAmount.toFixed(2)}`);
      
      // Calculate fuel quantity based on the extracted amount
      const extractedQuantity = Number((extractedAmount / fuelPrice).toFixed(2));
      setBillQuantity(extractedQuantity);
      
      toast.success(`Calculated fuel quantity: ${extractedQuantity} ${fuelUnit}`);
      
      // Automatically verify the bill after a short delay
      setTimeout(() => {
        const isValid = verifyBill(extractedQuantity);
        
        // Automatically save to history
        setTimeout(() => {
          saveToHistory(isValid);
        }, 1000);
      }, 1500);
    }, 1500);
  };

  return (
    <div className="glass-card rounded-2xl p-6 my-6 animate-scale-in opacity-0">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-medium">Purchase Calculator</h3>
        <Button 
          variant="outline" 
          size="sm"
          onClick={() => setIsHistoryOpen(true)}
          className="flex items-center gap-1"
        >
          <History className="h-4 w-4" />
          History
        </Button>
      </div>
      <Separator className="mb-4 bg-border/50" />
      
      <CalculatorInput
        id="amount-paid"
        label="Amount Paid"
        value={amountPaid}
        onChange={setAmountPaid}
        unit="₹"
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
      
      <div className="flex gap-2 mb-2">
        <Button 
          onClick={() => verifyBill(billQuantity)}
          className="flex-1 h-12"
        >
          <FileCheck className="mr-2 h-4 w-4" />
          Verify Manually
        </Button>
        
        <Button
          onClick={() => saveToHistory(verificationResult === true)}
          variant="secondary"
          className="flex-1 h-12"
          disabled={verificationResult === null}
        >
          <Save className="mr-2 h-4 w-4" />
          Save to History
        </Button>
      </div>
      
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

      {/* Purchase History Dialog */}
      <Dialog open={isHistoryOpen} onOpenChange={setIsHistoryOpen}>
        <DialogContent className="sm:max-w-[500px] max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Purchase History</DialogTitle>
          </DialogHeader>
          <PurchaseHistory 
            history={history} 
            onHistoryUpdate={setHistory} 
          />
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default PurchaseCalculator;
