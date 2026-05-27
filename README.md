# New-Age Vehicle Sales 🚗

An advanced, interactive, and complete used vehicle dealership system for players on FiveM (QBox / QB-Core Frameworks).

![New-Age Vehicle Sales](https://img.shields.io/badge/FiveM-Script-blue) ![Framework](https://img.shields.io/badge/Framework-QBox%20%7C%20QBCore-green) ![License](https://img.shields.io/badge/License-Non--Commercial-red)

## 📌 About The Project

**New-Age Vehicle Sales** allows players to put their used vehicles up for sale physically on the map, creating an immersive showroom. Other players can analyze the vehicle details, engine health, body condition, and mileage before closing a deal.

This script focuses on **data stability** and **physical immersion**, including real body deformation capture and interactive purchase and sale contracts.

## 🚀 Key Features

- **Physical Vehicle Showroom**: Advertised cars spawn in the physical world (parked in designated spots).
- **Interactive Tablet (NUI)**: Manage your listings through an animated tablet, view other players' vehicles, and access your transaction history.
- **Highly Accurate Damage System**: Native compatibility with `rhd_garage` and `jg-advancedgarages`. Body deformation, dirt levels, and engine health are saved and transferred 100% identically to the buyer.
- **Offline Payments**: Sold your car at 3 AM while you were asleep? No problem! The money goes straight into the seller's bank account, even if they are offline.
- **History Integration**: Lifetime history of bought and sold cars saved in the database.
- **Advanced VIN Generation**: Native `VINBridge` integrated with the official `piotreq_gpt` generator (or a secure fallback).
- **Total Webhook Integration**: Colorful and detailed Discord notifications for Listings, Purchases, Cancellations, and History Deletions.
- **Anti-Wipe Protection (Secure Transactions)**: The system saves the vehicle to the showroom database first before deleting the original car, offering 100% protection against vehicle loss due to SQL crashes.
- **Exploit-Free (No Dupes)**: A virtual lock tied to the license plate (`busyVehicles`) prevents two players from attempting to buy the same vehicle in the same fraction of a second.

## 📋 Prerequisites (Dependencies)

- [qbx_core](https://github.com/Qbox-project/qbx_core) (or updated qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)
- **Optional**:
  - `jg-vehiclemileage` (for real mileage system)
  - `jg-advancedgarages` or `rhd_garage` (natively paired to read the super advanced damage structure)
  - `piotreq_gpt` (for VIN/chassis generation)

## ⚙️ Installation

1. Download the repository and place the `newage_vehiclesales` folder inside your `[resources]` directory.
2. The SQL tables (`newage_vehiclesales` and `newage_vehiclesales_history`) are created **automatically** by the migration routine when the script starts. (You do not need to run any `.sql` file).
3. Configure your Discord Webhooks and dealership coordinates inside the `config/config.lua` file.
4. Ensure the resource starts in your `server.cfg`:
   ```cfg
   ensure newage_vehiclesales
   ```

## 📝 Configuration (`config/config.lua`)

The configuration file is vast. Key topics you can edit:
- **Showroom Locations**: You can add multiple dealerships spread across the city.
- **Parking Spots (`vehicleSpots`)**: Where the cars will be anchored.
- **Currency**: You can change it from `$` to `€`, `R$`, etc.
- **Debug Mode**: `config.debug = true` will draw red boxes on the ground outlining where the parking spots are.

## ⚖️ License and Terms of Use

This project is under a **Modified Open Source License (Non-Commercial)**. 

⚠️ **IT IS STRICTLY PROHIBITED TO:**
- Sell this code, or any parts of it.
- Place the download of this script behind Paywalls, Patreon, Tebex, or unofficial Discord stores.
- Claim authorship over this code for profit.

This script was designed for the FiveM community in an open and collaborative manner. Please read the `LICENSE` file for more details.

---
*Developed with 💖 by New-Age Studios.*