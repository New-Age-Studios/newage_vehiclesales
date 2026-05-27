import React, { useState, useEffect } from 'react';
import { VehicleContract } from './components/contract/VehicleContract';
import { VehicleSaleTablet } from './components/sale/VehicleSaleTablet';
import { MainMenu } from './components/mainMenu/MainMenu';
import { VehicleHistoryTablet, HistoryTabletData } from './components/sale/VehicleHistoryTablet';
import { CameraOverlay } from './components/sale/CameraOverlay';
import { ActiveListing, SoldVehicle } from './types/history';
import { ContractData } from './types/contract';
import { SaleData, SaleVehicleData } from './types/sale';
import { mockContract } from './data/mockContract';
import { CurrencyProvider } from './context/CurrencyContext';
import { LocaleProvider } from './context/LocaleContext';

const App: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [mode, setMode] = useState<'buy' | 'sell' | 'menu' | 'history' | 'camera'>('buy');
  const [contractData, setContractData] = useState<ContractData | null>(null);
  const [saleData, setSaleData] = useState<SaleData | null>(null);
  const [salePrice, setSalePrice] = useState<string>('');
  const [saleDescription, setSaleDescription] = useState<string>('');
  const [saleVehicleState, setSaleVehicleState] = useState<SaleVehicleData | null>(null);
  const [menuData, setMenuData] = useState<any | null>(null);
  const [historyData, setHistoryData] = useState<HistoryTabletData | null>(null);

  const [currencySymbol, setCurrencySymbol] = useState<string>('R$');
  const [currencyCode, setCurrencyCode] = useState<string>('BRL');
  const [translations, setTranslations] = useState<Record<string, string>>({});

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      if (data.currencySymbol) setCurrencySymbol(data.currencySymbol);
      if (data.currencyCode) setCurrencyCode(data.currencyCode);
      if (data.uiTranslations) setTranslations(data.uiTranslations);

      if (data.action === "buyVehicle") {
        const formattedData: ContractData = {
          id: `2024-${Math.floor(Math.random() * 9000) + 1000}`,
          bizName: data.bizName || "CONCESSIONÁRIA",
          vehicle: {
            model: data.model ? (data.model.charAt(0).toUpperCase() + data.model.slice(1)) : "Veículo Desconhecido",
            plate: data.plate || "SEM PLACA",
            description: data.vehicleData?.desc || "O vendedor não preencheu nenhuma descrição.",
            price: data.vehicleData?.price || 0,
            photoUrl: data.vehicleData?.photoUrl || `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${data.model?.toLowerCase()}.jpg` || mockContract.vehicle.photoUrl,
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
        setSalePrice('');
        setSaleDescription('');
        setSaleVehicleState(data.vehicleData);
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
          options: data.options,
          vehicleData: data.vehicleData
        });
        setVisible(true);
      } else if (data.action === "openHistoryTablet") {
        setMode('history');
        setHistoryData({
          bizName: data.bizName || "Concessionária de Usados",
          active: data.active || [],
          sold: data.sold || [],
          sellerData: data.sellerData
        });
        setVisible(true);
      } else if (data.action === "openCameraOverlay") {
        setMode('camera');
        setVisible(true);
      } else if (data.action === "showTabletAfterPhoto") {
        setMode('sell');
        if (data.url) {
          setSaleVehicleState(prev => {
            if (!prev) return null;
            return {
              ...prev,
              photoUrl: data.url
            };
          });
          setSaleData(prev => {
            if (!prev) return null;
            return {
              ...prev,
              vehicleData: {
                ...prev.vehicleData,
                photoUrl: data.url
              }
            };
          });
        }
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
    if (mode === 'buy' && contractData?.id.startsWith('HIST-')) {
      setMode('history');
      return;
    }
    setVisible(false);
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  };

  const handleConfirmPurchase = (paymentMethod?: string) => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/buyVehicle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ paymentMethod: paymentMethod || 'bank' })
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

  const handleCancelSale = (listing: ActiveListing) => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/cancelSale`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        plate: listing.plate,
        oid: listing.oid,
        model: listing.model,
        mods: listing.mods
      })
    });
    setVisible(false);
  };

  const handleOpenContract = (sold: SoldVehicle) => {
    const formattedData: ContractData = {
      id: `HIST-${sold.id}`,
      bizName: historyData?.bizName || "CONCESSIONÁRIA",
      vehicle: {
        model: sold.model ? (sold.model.charAt(0).toUpperCase() + sold.model.slice(1)) : "Veículo Desconhecido",
        plate: sold.plate || "SEM PLACA",
        description: sold.description || "Sem observações do vendedor.",
        price: sold.price || 0,
        photoUrl: sold.photoUrl || `https://raw.githubusercontent.com/mriqbox/ui-kit/main/assets/vehicles/${sold.model?.toLowerCase()}.jpg` || mockContract.vehicle.photoUrl,
        fuelType: sold.fuelType,
        colorRGB: sold.colorRGB,
        isExotic: sold.isExotic,
        transmission: sold.transmission
      },
      seller: {
        firstname: historyData?.sellerData.firstname || "Vendedor",
        lastname: historyData?.sellerData.lastname || "Anônimo",
        account: historyData?.sellerData.account || "N/A",
        phone: historyData?.sellerData.phone || "N/A"
      },
      buyer: {
        firstname: sold.buyerName.split(' ')[0] || "Comprador",
        lastname: sold.buyerName.split(' ').slice(1).join(' ') || "Autorizado"
      },
      date: new Date(sold.date).toLocaleString('pt-BR')
    };

    setContractData(formattedData);
    setMode('buy');
  };

  const handleDeleteHistoryRecord = (id: number) => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/deleteHistoryRecord`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id })
    });
    
    setHistoryData(prev => {
      if (!prev) return null;
      return {
        ...prev,
        sold: prev.sold.filter(item => item.id !== id)
      };
    });
  };

  if (!visible) return null;

  return (
    <LocaleProvider translations={translations}>
      <CurrencyProvider symbol={currencySymbol} code={currencyCode}>
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
              readOnly={contractData.id.startsWith('HIST-')}
            />
          )}
          {mode === 'sell' && saleData && saleVehicleState && (
            <VehicleSaleTablet 
              data={saleData}
              price={salePrice}
              setPrice={setSalePrice}
              description={saleDescription}
              setDescription={setSaleDescription}
              vehicleState={saleVehicleState}
              setVehicleState={setSaleVehicleState}
              onConfirm={handleConfirmSale}
              onCancel={handleClose}
            />
          )}
          {mode === 'menu' && menuData && (
            <MainMenu 
              data={menuData}
              onSelectSell={handleSelectSell}
              onSelectSellBack={handleSelectSellBack}
              onSelectHistory={() => {
                fetch(`https://${(window as any).GetParentResourceName?.() || 'qbx_vehiclesales'}/selectHistory`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({})
                });
                setVisible(false);
              }}
              onCancel={handleClose}
            />
          )}
          {mode === 'history' && historyData && (
            <VehicleHistoryTablet 
              data={historyData}
              onCancelSale={handleCancelSale}
              onCancel={handleClose}
              onOpenContract={handleOpenContract}
              onDeleteHistoryRecord={handleDeleteHistoryRecord}
            />
          )}
          {mode === 'camera' && (
            <CameraOverlay />
          )}
        </main>
      </div>
    </CurrencyProvider>
  </LocaleProvider>
  );
};

export default App;
