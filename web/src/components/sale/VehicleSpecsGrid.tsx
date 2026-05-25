import { CustomSelect } from '../ui/CustomSelect';
import { useState } from 'react';
import { Hash, Palette, Fuel, Gauge, Settings2 } from 'lucide-react';
import { SaleVehicleData } from '../../types/sale';
import { cn } from '@/lib/utils';
import { useLocale } from '../../context/LocaleContext';

interface VehicleSpecsGridProps {
  vehicle: SaleVehicleData;
  onUpdate: (data: Partial<SaleVehicleData>) => void;
  onOpenColorPicker: () => void;
}

export const VehicleSpecsGrid: React.FC<VehicleSpecsGridProps> = ({ vehicle, onUpdate, onOpenColorPicker }) => {
  const t = useLocale();

  return (
    <div className="flex flex-col h-full space-y-2 pb-2">
      <div className="grid grid-cols-2 gap-2">
        {/* Modelo - Read Only */}
        <div className="bg-zinc-900/50 border border-zinc-800 p-2 rounded-xl flex items-center space-x-2 opacity-80 h-[48px]">
          <div className="bg-zinc-800 p-1.5 rounded-lg text-zinc-400">
            <Settings2 size={14} />
          </div>
          <div className="flex flex-col min-w-0">
            <span className="text-[7px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.model}</span>
            <span className="text-[10px] font-black text-zinc-200 uppercase truncate">{vehicle.model}</span>
          </div>
        </div>

        {/* Placa - Read Only */}
        <div className="bg-zinc-900/50 border border-zinc-800 p-2 rounded-xl flex items-center space-x-2 opacity-80 h-[48px]">
          <div className="bg-zinc-800 p-1.5 rounded-lg text-zinc-400">
            <Hash size={14} />
          </div>
          <div className="flex flex-col">
            <span className="text-[7px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.plate}</span>
            <span className="text-[10px] font-black text-zinc-200 uppercase">{vehicle.plate}</span>
          </div>
        </div>

        {/* Quilometragem - Read Only */}
        <div className="bg-zinc-900/50 border border-zinc-800 p-2 rounded-xl flex items-center space-x-2 opacity-80 h-[48px]">
          <div className="bg-zinc-800 p-1.5 rounded-lg text-zinc-400">
            <Gauge size={14} />
          </div>
          <div className="flex flex-col">
            <span className="text-[7px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.mileage}</span>
            <span className="text-[10px] font-black text-zinc-200 uppercase">{vehicle.body * 123} km</span>
          </div>
        </div>

        {/* Combustível - Selectable */}
        <div className="bg-zinc-900 border border-zinc-800 p-2 rounded-xl flex flex-col justify-center h-[48px]">
          <div className="flex items-center space-x-2 mb-0.5">
            <Fuel size={10} className="text-zinc-500" />
            <span className="text-[7px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.fuel}</span>
          </div>
          <CustomSelect 
            value={vehicle.fuelType || t.vehicleSpecsGrid.fuelOptions[0]} 
            options={t.vehicleSpecsGrid.fuelOptions}
            onChange={(val) => onUpdate({ fuelType: val as any })}
          />
        </div>

        {/* Câmbio - Selectable */}
        <div className="bg-zinc-900 border border-zinc-800 p-2 rounded-xl flex flex-col justify-center h-[48px] col-span-2">
          <div className="flex items-center space-x-2 mb-0.5">
            <Settings2 size={10} className="text-zinc-500" />
            <span className="text-[7px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.transmission}</span>
          </div>
          <CustomSelect 
            value={vehicle.transmission || t.vehicleSpecsGrid.transmissionOptions[1]} 
            options={t.vehicleSpecsGrid.transmissionOptions}
            onChange={(val) => onUpdate({ transmission: val as any })}
          />
        </div>
      </div>

      {/* Cor do Veículo - Aligned to bottom with mt-auto */}
      <div 
        className="mt-auto bg-zinc-900 border border-zinc-800 p-3 rounded-xl space-y-2 transition-colors group"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Palette size={14} className="text-zinc-500" />
            <span className="text-[8px] font-bold text-zinc-500 uppercase tracking-tighter">{t.vehicleSpecsGrid.paintCustomization}</span>
          </div>
          
          {/* Manual Exotic Toggle */}
          <div className="flex items-center space-x-2">
             <span className="text-[7px] font-black text-zinc-600 uppercase tracking-widest">{t.vehicleSpecsGrid.exoticPaint}</span>
             <button 
                onClick={(e) => {
                  e.stopPropagation();
                  onUpdate({ isExotic: !vehicle.isExotic });
                }}
                className={cn(
                  "w-7 h-3.5 rounded-full relative transition-colors duration-300 border border-zinc-800",
                  vehicle.isExotic ? "bg-concessionaire" : "bg-zinc-950"
                )}
             >
                <div className={cn(
                  "absolute top-0.5 w-2 h-2 rounded-full bg-white transition-all duration-300 shadow-sm",
                  vehicle.isExotic ? "left-[16px]" : "left-[3px]"
                )} />
             </button>
          </div>
        </div>

        <div 
          onClick={onOpenColorPicker}
          className="flex items-center justify-between bg-zinc-950 p-2 rounded-lg border border-zinc-800/50 hover:bg-zinc-900 cursor-pointer transition-colors group/inner"
        >
          <div className="flex items-center space-x-2">
            <div 
              className="w-7 h-7 rounded-full border-2 border-zinc-800 shadow-[inset_0_2px_4px_rgba(0,0,0,0.3)]" 
              style={{ backgroundColor: vehicle.colorRGB || '#FFFFFF' }}
            />
            <div className="flex flex-col">
              <span className="text-[10px] font-black text-zinc-200 uppercase tracking-tighter leading-tight">
                {vehicle.colorRGB || '#FFFFFF'}
              </span>
              <span className="text-[7px] font-bold text-zinc-600 uppercase tracking-widest">{t.vehicleSpecsGrid.rgbDetected}</span>
            </div>
          </div>
          
          <div className="flex items-center space-x-2 bg-zinc-900 px-2 py-1 rounded-md border border-zinc-800 group-hover/inner:border-concessionaire/50 transition-all">
            <span className="text-[7px] font-black text-zinc-400 group-hover/inner:text-concessionaire uppercase tracking-widest">{t.vehicleSpecsGrid.changePaint}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
