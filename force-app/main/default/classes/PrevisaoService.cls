public with sharing class PrevisaoService {

    public static Map<String,Object> getLatLong(Id accId) {
        Account acc = [
            SELECT Id,
        	BillingCity
            FROM Account
            WHERE Id =: accId
        ];
    
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String cidadeCodificada = EncodingUtil.urlEncode(acc.BillingCity, 'UTF-8');
        req.setEndpoint('https://nominatim.openstreetmap.org/search?q=' + cidadeCodificada + '&format=json&limit=1');
        req.setMethod('GET');
        HttpResponse res = http.send(req);
        
        List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
        

        System.debug(results);  
        if (!results.isEmpty()) {
            return (Map<String,Object>) results[0];
        }
        
        return null; 
    }



    @AuraEnabled
    public static Map<String,Object> getPrevisao(Id accId){

        Account acc = [
           SELECT Id,
            BillingCity
            FROM Account
            WHERE Id =: accId
        ];

        Map<String,Object> latLong = getLatLong(accId);
        
        // Verifica se a cidade foi encontrada
        if (latLong == null) {
            throw new AuraHandledException('Cidade não encontrada: ' + acc.BillingCity);
        }
        
        String lat = (String) latLong.get('lat');
        String lon = (String) latLong.get('lon');


        String urlForecast = 'https://api.open-meteo.com/v1/forecast?latitude=' + lat +'&longitude=' + lon +'&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto&forecast_days=7';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(urlForecast);
    req.setMethod('GET');

    Http http = new Http();
    HTTPResponse res = http.send(req);

    if (res.getStatusCode() != 200) {
        throw new AuraHandledException('Erro ao buscar previsão: ' + res.getBody());
    }

    Map<String, Object> forecast = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

    Map<String, Object> result = new Map<String, Object>();
    result.put('cidade', acc.BillingCity);
    result.put('dados', forecast);
    System.debug(result);
    return result;
    }
}