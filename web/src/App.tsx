import React, { useState, useEffect } from 'react';
import { VehicleContract } from './components/contract/VehicleContract';
import { VehicleSaleTablet } from './components/sale/VehicleSaleTablet';
import { ContractData } from './types/contract';
import { SaleData } from './types/sale';
import { mockContract } from './data/mockContract';
import { mockSaleVehicle } from './data/mockSaleVehicle';

const App: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [mode, setMode] = useState<'buy' | 'sell'>('buy');
  const [contractData, setContractData] = useState<ContractData | null>(null);
  const [saleData, setSaleData] = useState<SaleData | null>(null);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      if (data.action === "buyVehicle") {
        const formattedData: ContractData = {
          id: `2024-${Math.floor(Math.random() * 9000) + 1000}`,
          bizName: data.bizName || "CONCESSIONÁRIA",
          vehicle: {
            model: data.model ? (data.model.charAt(0).toUpperCase() + data.model.slice(1)) : "Veículo Desconhecido",
            plate: data.plate || "SEM PLACA",
            description: data.vehicleData?.desc || "O vendedor não preencheu nenhuma descrição.",
            price: data.vehicleData?.price || 0,
            photoUrl: `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${data.model?.toLowerCase()}.jpg` || mockContract.vehicle.photoUrl,
            fuelType: data.vehicleData?.fuelType,
            colorRGB: data.vehicleData?.colorRGB,
            isExotic: data.vehicleData?.isExotic,
            transmission: data.vehicleData?.transmission
          },
          seller: {
            firstname: data.sellerData?.firstname || "Vendedor",
            lastname: data.sellerData?.lastname || "Anônimo",
            account: data.sellerData?.account || "N/A",
            phone: data.sellerData?.phone || "N/A"
          },
          buyer: data.buyerData ? {
            firstname: data.buyerData.firstname,
            lastname: data.buyerData.lastname,
          } : undefined,
          date: new Date().toLocaleString('pt-BR')
        };
        
        setMode('buy');
        setContractData(formattedData);
        setVisible(true);
      } else if (data.action === "sellVehicle") {
        setMode('sell');
        setSaleData({
          bizName: data.bizName || "CONCESSIONÁRIA",
          sellerData: data.sellerData,
          vehicleData: data.vehicleData,
          dealerFee: data.dealerFee || 0
        });
        setVisible(true);
      } else if (data.action === "close") {
        setVisible(false);
      }
    };

    window.addEventListener("message", handleMessage);
    
    // For development testing
    if (import.meta.env.DEV) {
      // setTimeout(() => {
      //   setMode('sell');
      //   setSaleData(mockSaleVehicle);
      //   setVisible(true);
      // }, 1000);
    }

    return () => window.removeEventListener("message", handleMessage);
  }, []);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        handleClose();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const handleClose = () => {
    setVisible(false);
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  };

  const handleConfirmPurchase = () => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/buyVehicle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    setVisible(false);
  };

  const handleConfirmSale = (price: number, description: string, vehicleUpdates: any) => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/sellVehicle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ price, desc: description, vehicleData: vehicleUpdates })
    });
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div className="w-screen h-screen flex items-center justify-center overflow-hidden bg-transparent">
      <main className="relative w-full h-full flex items-center justify-center animate-in fade-in zoom-in duration-500 py-8">
        {mode === 'buy' && contractData && (
          <VehicleContract 
            data={contractData} 
            onConfirm={handleConfirmPurchase}
            onCancel={handleClose}
          />
        )}
        {mode === 'sell' && saleData && (
          <VehicleSaleTablet 
            data={saleData}
            onConfirm={handleConfirmSale}
            onCancel={handleClose}
          />
        )}
      </main>
    </div>
  );
};

export default App;
