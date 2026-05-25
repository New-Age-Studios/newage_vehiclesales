CREATE TABLE IF NOT EXISTS `newage_vehiclesales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `mods` text DEFAULT NULL,
  `occasionid` varchar(50) DEFAULT NULL,
  `fuel_type` varchar(50) DEFAULT 'Gasolina',
  `color_rgb` varchar(50) DEFAULT '#FFFFFF',
  `is_exotic` tinyint(1) DEFAULT 0,
  `transmission` varchar(50) DEFAULT 'Automático',
  PRIMARY KEY (`id`),
  KEY `occasionId` (`occasionid`)
) ENGINE=InnoDB AUTO_INCREMENT=325 DEFAULT CHARSET=utf8mb4;