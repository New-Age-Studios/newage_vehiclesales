export interface ActiveListing {
  oid: string;
  plate: string;
  model: string;
  price: number;
  description: string;
  mods: string;
  fuelType?: string;
  colorRGB?: string;
  isExotic?: boolean;
  transmission?: string;
  photoUrl?: string;
}

export interface SoldVehicle {
  id: number;
  buyerName: string;
  buyerCitizenId: string;
  plate: string;
  model: string;
  price: number;
  description: string;
  mods: string;
  fuelType?: string;
  colorRGB?: string;
  isExotic?: boolean;
  transmission?: string;
  photoUrl?: string;
  date: string;
}
