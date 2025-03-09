
import React from 'react';
import { PurchaseHistoryItem, getPurchaseHistory } from './PurchaseCalculator';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Trash2, FileCheck, AlertCircle } from 'lucide-react';
import { getFuelUnit } from '@/lib/calculate';
import { toast } from 'sonner';

interface PurchaseHistoryProps {
  history: PurchaseHistoryItem[];
  onHistoryUpdate: (history: PurchaseHistoryItem[]) => void;
}

const PurchaseHistory: React.FC<PurchaseHistoryProps> = ({ 
  history,
  onHistoryUpdate
}) => {
  const clearHistory = () => {
    localStorage.removeItem('purchaseHistory');
    onHistoryUpdate([]);
    toast.success('Purchase history cleared');
  };

  const deleteHistoryItem = (id: string) => {
    const updatedHistory = history.filter(item => item.id !== id);
    localStorage.setItem('purchaseHistory', JSON.stringify(updatedHistory));
    onHistoryUpdate(updatedHistory);
    toast.success('Item removed from history');
  };

  if (history.length === 0) {
    return (
      <div className="text-center p-4">
        <p className="text-muted-foreground">No purchase history available</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button 
          variant="destructive" 
          size="sm" 
          onClick={clearHistory}
          className="flex items-center gap-1"
        >
          <Trash2 className="h-4 w-4" />
          Clear All
        </Button>
      </div>
      
      <div className="space-y-4 mt-2">
        {history.map((item) => {
          const fuelUnit = getFuelUnit(item.fuelType);
          const date = new Date(item.date);
          const formattedDate = date.toLocaleDateString('en-IN', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
          });
          const formattedTime = date.toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit',
          });
          
          return (
            <div 
              key={item.id} 
              className="bg-secondary/20 p-4 rounded-lg border border-border/50 relative"
            >
              <div className="absolute right-3 top-3">
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-6 w-6"
                  onClick={() => deleteHistoryItem(item.id)}
                >
                  <Trash2 className="h-4 w-4 text-muted-foreground hover:text-destructive" />
                </Button>
              </div>
              
              <div className="flex items-center gap-2 mb-2">
                <div className={`w-4 h-4 rounded-full ${
                  item.verified ? 'bg-green-500' : 'bg-red-500'
                }`} />
                <span className="text-sm font-medium">
                  {item.verified ? 'Verified' : 'Verification Failed'}
                </span>
              </div>
              
              <div className="grid grid-cols-2 gap-2 text-sm mb-2">
                <div>
                  <span className="text-muted-foreground">Date:</span>
                  <div className="font-medium">{formattedDate}</div>
                  <div className="text-xs text-muted-foreground">{formattedTime}</div>
                </div>
                <div>
                  <span className="text-muted-foreground">Fuel Type:</span>
                  <div className="font-medium capitalize">{item.fuelType}</div>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-muted-foreground">Amount:</span>
                  <div className="font-semibold text-lg">₹{item.amountPaid.toFixed(2)}</div>
                </div>
                <div>
                  <span className="text-muted-foreground">Quantity:</span>
                  <div className="font-semibold text-lg">{item.fuelQuantity} {fuelUnit}</div>
                </div>
              </div>
              
              <div className="mt-2 pt-2 border-t border-border/50 flex items-center">
                {item.verified ? (
                  <>
                    <FileCheck className="h-4 w-4 text-green-500 mr-2" />
                    <span className="text-xs text-green-600">Bill verified successfully</span>
                  </>
                ) : (
                  <>
                    <AlertCircle className="h-4 w-4 text-red-500 mr-2" />
                    <span className="text-xs text-red-600">Bill verification failed</span>
                  </>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default PurchaseHistory;
