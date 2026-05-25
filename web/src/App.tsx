import React, { useState, useEffect } from 'react';
import { VehicleContract } from './components/contract/VehicleContract';
import { VehicleSaleTablet } from './components/sale/VehicleSaleTablet';
import { MainMenu } from './components/mainMenu/MainMenu';
import { ContractData } from './types/contract';
import { SaleData } from './types/sale';
import { mockContract } from './data/mockContract';

const App: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [mode, setMode] = useState<'buy' | 'sell' | 'menu'>('buy');
  const [contractData, setContractData] = useState<ContractData | null>(null);
  const [saleData, setSaleData] = useState<SaleData | null>(null);
  const [menuData, setMenuData] = useState<any | null>(null);

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
      } else if (data.action === "mainMenu") {
        setMode('menu');
        setMenuData({
          bizName: data.bizName || "CONCESSIONÁRIA",
          enableSellBack: data.enableSellBack !== false,
          options: data.options
        });
        setVisible(true);
      } else if (data.action === "close") {
        setVisible(false);
      }
    };

    window.addEventListener("message", handleMessage);
    
    // For development testing
    if (import.meta.env.DEV) {
      // Dev testing blocks can go here
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

  useEffect(() => {
    const forceTransparency = () => {
      const rootEl = document.getElementById('root');
      if (rootEl) {
        rootEl.style.setProperty('background', 'transparent', 'important');
        rootEl.style.setProperty('background-color', 'transparent', 'important');
      }
      document.body.style.setProperty('background', 'transparent', 'important');
      document.body.style.setProperty('background-color', 'transparent', 'important');
      document.documentElement.style.setProperty('background', 'transparent', 'important');
      document.documentElement.style.setProperty('background-color', 'transparent', 'important');
    };
    forceTransparency();
    if (visible) {
      setTimeout(forceTransparency, 0);
      setTimeout(forceTransparency, 100);
      setTimeout(forceTransparency, 500);
    }
  }, [visible]);

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

  const handleSelectSell = () => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/selectSell`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    setVisible(false);
  };

  const handleSelectSellBack = () => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/selectSellBack`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div 
      className="w-screen h-screen flex items-center justify-center overflow-hidden bg-transparent"
      style={{ backgroundColor: 'transparent', background: 'transparent' }}
    >
      <main 
        className="relative w-full h-full flex items-center justify-center animate-in fade-in zoom-in duration-500 py-8"
        style={{ backgroundColor: 'transparent', background: 'transparent' }}
      >
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
        {mode === 'menu' && menuData && (
          <MainMenu 
            data={menuData}
            onSelectSell={handleSelectSell}
            onSelectSellBack={handleSelectSellBack}
            onCancel={handleClose}
          />
        )}
      </main>
    </div>
  );
};

export default App;
