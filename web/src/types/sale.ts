export interface SaleVehicleData {
  model: string;
  plate: string;
  fuel: number;
  fuelType?: 'Gasolina' | 'Diesel' | 'Etanol';
  engine: number;
  body: number;
  color: string;
  colorRGB?: string;
  isExotic?: boolean;
  transmission: 'Manual' | 'Automático';
  price?: number;
  description?: string;
  photoUrl?: string;
}

export interface SaleSellerData {
  firstname: string;
  lastname: string;
  account: string;
  phone: string;
}

export interface SaleData {
  bizName: string;
  vehicleData: SaleVehicleData;
  sellerData: SaleSellerData;
  dealerFee: number;
}
