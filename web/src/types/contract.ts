export interface VehicleData {
  model: string;
  plate: string;
  year?: string;
  color?: string;
  mileage?: string;
  fuel?: string;
  transmission?: string;
  description: string;
  photoUrl?: string;
  price: number;
  fuelType?: string;
  colorRGB?: string;
  isExotic?: boolean;
}

export interface SellerData {
  firstname: string;
  lastname: string;
  account: string;
  phone: string;
}

export interface ContractData {
  id: string;
  bizName: string;
  vehicle: VehicleData;
  seller: SellerData;
  buyer?: {
    firstname: string;
    lastname: string;
  };
  date: string;
}
