import React from 'react';
import { SaleVehicleData } from '../../types/sale';
import { Hash, Palette, Fuel, Gauge, Activity, Settings2 } from 'lucide-react';
import { useLocale } from '../../context/LocaleContext';

interface VehicleReadOnlyInfoProps {
  vehicle: SaleVehicleData;
}

export const VehicleReadOnlyInfo: React.FC<VehicleReadOnlyInfoProps> = ({ vehicle }) => {
  const t = useLocale();
  const items = [
    { label: t.vehicleReadOnly.model, value: vehicle.model, icon: Settings2 },
    { label: t.vehicleReadOnly.plate, value: vehicle.plate, icon: Hash },
    { label: t.vehicleReadOnly.fuel, value: `${vehicle.fuel}%`, icon: Fuel },
    { label: t.vehicleReadOnly.engine, value: `${vehicle.engine}%`, icon: Activity },
    { label: t.vehicleReadOnly.body, value: `${vehicle.body}%`, icon: Gauge },
    { label: t.vehicleReadOnly.color, value: vehicle.color, icon: Palette },
  ];

  return (
    <div className="grid grid-cols-2 gap-3">
      {items.map((item, idx) => (
        <div key={idx} className="bg-zinc-900/50 border border-zinc-800 p-3 rounded-xl flex items-center space-x-3">
          <div className="bg-zinc-800 p-2 rounded-lg text-zinc-400">
            <item.icon size={16} />
          </div>
          <div className="flex flex-col">
            <span className="text-[8px] font-bold text-zinc-500 uppercase tracking-tighter">{item.label}</span>
            <span className="text-[11px] font-black text-zinc-200 uppercase truncate">{item.value}</span>
          </div>
        </div>
      ))}
    </div>
  );
};
