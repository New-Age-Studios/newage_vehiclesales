# New-Age Vehicle Sales 🚗

Um sistema avançado, interativo e completo de venda de veículos usados entre jogadores para FiveM (Frameworks QBox / QB-Core).

![New-Age Vehicle Sales](https://img.shields.io/badge/FiveM-Script-blue) ![Framework](https://img.shields.io/badge/Framework-QBox%20%7C%20QBCore-green) ![License](https://img.shields.io/badge/License-Non--Commercial-red)

## 📌 Sobre o Projeto

O **New-Age Vehicle Sales** permite que os jogadores anunciem seus veículos usados de forma totalmente física no mapa, gerando uma vitrine imersiva. Outros jogadores podem analisar os detalhes, estado do motor, lataria e quilometragem antes de fechar negócio.

O script foca na **estabilidade de dados** e na **imersão física**, incluindo captura de deformação de lataria real e contratos de compra e venda interativos.

## 🚀 Principais Funcionalidades

- **Vitrine Física de Veículos**: Os carros anunciados aparecem no mundo real (estacionados nas vagas designadas).
- **Tablet Interativo (NUI)**: Gerencie seus anúncios através de um tablet animado, veja veículos de outros jogadores e acesse o histórico de negociações.
- **Sistema de Danos Altamente Preciso**: Compatibilidade nativa com o `rhd_garage`. A lataria, sujeira e estado do motor são salvos e passados 100% como estão para o comprador.
- **Pagamento Offline**: Vendeu o carro de madrugada enquanto dormia? Sem problemas! O dinheiro cai direto na conta bancária do vendedor, mesmo que ele esteja offline.
- **Integração de Histórico**: Histórico vitalício de carros comprados e vendidos salvo na base de dados.
- **Geração de VIN Avançada**: Ponte nativa `VINBridge` integrada com o gerador oficial `piotreq_gpt` (ou fallback seguro).
- **Integração Webhook Total**: Notificações coloridas e detalhadas via Discord para Anúncios, Compras, Cancelamentos e Exclusão de Histórico.
- **Proteção Anti-Wipe (Transações Seguras)**: O sistema salva a venda na vitrine primeiro antes de deletar o carro original, protegendo 100% contra perda de veículos por *crashes* de SQL.
- **Sem Exploit (Duplicação)**: Lock virtual atrelado a placa (`busyVehicles`) que proíbe dois jogadores de tentarem comprar o mesmo veículo na mesma fração de segundo.

## 📋 Pré-Requisitos (Dependências)

- [qbx_core](https://github.com/Qbox-project/qbx_core) (ou qb-core atualizado)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)
- **Opcionais**:
  - `jg-vehiclemileage` (para sistema real de quilometragem)
  - `rhd_garage` (nativamente pareado para danos super avançados)
  - `piotreq_gpt` (para geração de chassi/VIN)

## ⚙️ Instalação

1. Baixe o repositório e coloque a pasta `newage_vehiclesales` na sua pasta `[resources]`.
2. As tabelas SQL (`newage_vehiclesales` e `newage_vehiclesales_history`) são criadas de forma **automática** pela rotina de migração no momento em que o script é iniciado. (Você não precisa rodar arquivo `.sql`).
3. Configure os Webhooks do seu Discord e as coordenadas da sua concessionária dentro do arquivo `config/config.lua`.
4. Garanta que o resource inicie no seu `server.cfg`:
   ```cfg
   ensure newage_vehiclesales
   ```

## 📝 Configuração (`config/config.lua`)

O arquivo de configuração é vasto. Principais tópicos que você pode editar:
- **Locais das vitrines**: Pode-se adicionar múltiplas concessionárias separadas pela cidade.
- **Vagas (`vehicleSpots`)**: Onde os carros ficarão ancorados.
- **Moeda**: Pode mudar de `$` para `R$`.
- **Modo Debug**: `config.debug = true` irá desenhar as caixas vermelhas no chão demarcando onde as vagas existem.

## ⚖️ Licença e Termos de Uso

Este projeto está sob uma **Licença Modificada de Código Aberto (Non-Commercial)**. 

⚠️ **É ESTRITAMENTE PROIBIDO:**
- Vender este código, ou partes dele.
- Colocar o download deste script atrás de Paywalls, Patreon, Tebex, ou lojas não oficiais do Discord.
- Reivindicar autoria sobre este código para fins lucrativos.

O script foi projetado para a comunidade FiveM de forma aberta e colaborativa. Leia o arquivo `LICENSE` para mais detalhes.

---
*Desenvolvido com 💖 por New-Age Studios.*