import { ContractData } from "../types/contract";

export const mockContract: ContractData = {
  id: "2024-0042",
  bizName: "MOSLEY'S CARS",
  vehicle: {
    model: "Focus 2003",
    plate: "NNND6234",
    year: "2003",
    color: "Prata",
    mileage: "125.400 km",
    fuel: "Gasolina",
    transmission: "Manual",
    description: "O vendedor não preencheu nenhuma descrição.",
    price: 1000000,
    photoUrl: "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=2070&auto=format&fit=crop"
  },
  seller: {
    firstname: "Alexandre",
    lastname: "De Moraes",
    account: "BGS253131",
    phone: "352708"
  },
  date: new Date().toLocaleString('pt-BR')
};
