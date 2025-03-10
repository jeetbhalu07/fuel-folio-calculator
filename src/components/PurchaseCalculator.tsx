
import React, { useState, useEffect } from 'react';
import CalculatorInput from '@/components/CalculatorInput';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { FuelType, getCompanyFuelPrice, getFuelUnit } from '@/lib/calculate';
import { Upload, FileCheck, AlertCircle, Save, History, RefreshCw } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
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

// Bill data extraction interface
interface ExtractedBillData {
  amountPaid: number;
  fuelQuantity: number;
  fuelPrice: number;
}

const PurchaseCalculator: React.FC<PurchaseCalculatorProps> = ({
  selectedFuelType,
  fuelPrice,
}) => {
  const [amountPaid, setAmountPaid] = useState(200);
  const [fuelQuantity, setFuelQuantity] = useState(0);
  const [billQuantity, setBillQuantity] = useState(0);
  const [billFuelPrice, setBillFuelPrice] = useState(0);
  const [verificationResult, setVerificationResult] = useState<boolean | null>(null);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [history, setHistory] = useState<PurchaseHistoryItem[]>([]);
  const [processingBill, setProcessingBill] = useState(false);
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

  const verifyBill = (quantity: number, extractedFuelPrice?: number) => {
    if (quantity <= 0) {
      toast.error("Invalid fuel quantity detected");
      return false;
    }

    // If we have extracted fuel price from the bill, use it, otherwise use the current fuel price
    const priceToUse = extractedFuelPrice && extractedFuelPrice > 0 ? extractedFuelPrice : fuelPrice;
    
    const expectedAmount = quantity * priceToUse;
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
      description: `Amount: ₹${amountPaid.toFixed(2)}, Quantity: ${billQuantity > 0 ? billQuantity : fuelQuantity} ${fuelUnit}`,
      duration: 4000,
    });
  };

  const extractBillData = (file: File): Promise<ExtractedBillData> => {
    return new Promise((resolve) => {
      // In a real implementation, this would call an OCR service to extract data from the bill
      // For demonstration, we'll simulate the extraction with random values
      setTimeout(() => {
        // Extract the amount paid from the bill
        const extractedAmount = Math.floor(Math.random() * 1000) + 100; // Random amount between 100-1100
        
        // Extract the fuel price from the bill (simulate extraction from receipt)
        // In a real implementation, this would come from the actual OCR of the bill
        const extractedFuelPrice = fuelPrice * (0.9 + Math.random() * 0.2); // Simulate a price within ±10% of current price
        
        // Calculate quantity based on extracted values
        const extractedQuantity = Number((extractedAmount / extractedFuelPrice).toFixed(2));
        
        resolve({
          amountPaid: extractedAmount,
          fuelQuantity: extractedQuantity,
          fuelPrice: extractedFuelPrice
        });
      }, 1500);
    });
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    setProcessingBill(true);
    
    toast.info("Processing bill...", {
      duration: 2000,
    });
    
    try {
      // Extract data from bill
      const extractedData = await extractBillData(file);
      
      // Update state with extracted values
      setAmountPaid(extractedData.amountPaid);
      setBillQuantity(extractedData.fuelQuantity);
      setBillFuelPrice(extractedData.fuelPrice);
      
      toast.success(`Extracted amount: ₹${extractedData.amountPaid.toFixed(2)}`);
      toast.success(`Extracted fuel price: ₹${extractedData.fuelPrice.toFixed(2)} per ${fuelUnit}`);
      toast.success(`Calculated fuel quantity: ${extractedData.fuelQuantity} ${fuelUnit}`);
      
      // Automatically verify using extracted fuel price
      setTimeout(() => {
        const isValid = verifyBill(extractedData.fuelQuantity, extractedData.fuelPrice);
        
        // Automatically save to history
        setTimeout(() => {
          saveToHistory(isValid);
        }, 500);
        
        // Show verification result popup
        toast(isValid ? "Bill Verified Successfully" : "Bill Verification Failed", {
          description: isValid 
            ? "The fuel quantity matches the amount paid based on the extracted fuel price." 
            : "The fuel quantity doesn't match the amount paid based on the extracted fuel price.",
          icon: isValid ? <FileCheck className="h-4 w-4 text-green-500" /> : <AlertCircle className="h-4 w-4 text-red-500" />,
          duration: 5000,
        });
        
        // Automatically open history after saving
        setTimeout(() => {
          setIsHistoryOpen(true);
        }, 1000);
      }, 1000);
    } catch (error) {
      toast.error("Failed to process bill. Please try again.");
      console.error("Bill processing error:", error);
    } finally {
      setProcessingBill(false);
    }
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
      
      {billFuelPrice > 0 && (
        <div className="flex justify-between items-center mb-4 p-3 bg-primary/10 rounded-xl">
          <span className="text-sm text-muted-foreground">Bill Fuel Price:</span>
          <span className="text-lg font-semibold text-primary">
            ₹{billFuelPrice.toFixed(2)} per {fuelUnit}
          </span>
        </div>
      )}
      
      <Separator className="my-4 bg-border/50" />
      
      <h4 className="text-md font-medium mb-2">Verify Your Bill</h4>
      
      <div className="flex items-center gap-2 mb-4">
        <Button
          variant="outline"
          className="flex-1 h-12 relative"
          onClick={() => document.getElementById('bill-upload')?.click()}
          disabled={processingBill}
        >
          <input
            id="bill-upload"
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileUpload}
            disabled={processingBill}
          />
          {processingBill ? (
            <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <Upload className="mr-2 h-4 w-4" />
          )}
          {processingBill ? "Processing..." : "Upload Bill"}
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
          disabled={processingBill}
        >
          <FileCheck className="mr-2 h-4 w-4" />
          Verify Manually
        </Button>
        
        <Button
          onClick={() => saveToHistory(verificationResult === true)}
          variant="secondary"
          className="flex-1 h-12"
          disabled={verificationResult === null || processingBill}
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
            <DialogDescription>Your recent fuel purchase records</DialogDescription>
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
