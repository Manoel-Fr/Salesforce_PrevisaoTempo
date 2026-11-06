# Salesforce Previsão do Tempo

Lightning Web Component que exibe a previsão do tempo de 7 dias na página de registro de uma **Account**, com base na cidade de cobrança (`BillingCity`). Funciona no desktop e no app mobile.

## Como funciona

1. `lwcPrevisao` chama `PrevisaoService.getPrevisao(accId)`.
2. A classe busca latitude/longitude da cidade no [Nominatim (OpenStreetMap)](https://nominatim.openstreetmap.org).
3. Com as coordenadas, consulta a previsão diária no [Open-Meteo](https://open-meteo.com) (máx/mín e código do clima).
4. O componente mostra um card por dia com ícone, descrição e temperaturas.

## Metadados

| Tipo | Nome |
| --- | --- |
| LWC | `lwcPrevisao` |
| Apex | `PrevisaoService` |
| Remote Site Setting | `nominatim_openstreetmap`, `previsao` (api.open-meteo.com) |

## Deploy

```bash
sf project deploy start -o <alias> -d force-app
```

Depois, adicione o componente **Previsão do Tempo** à página de registro de Account no Lightning App Builder.
