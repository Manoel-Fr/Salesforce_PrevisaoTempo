public with sharing class PrevisaoService {

    @TestVisible private static final String NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
    @TestVisible private static final String OPEN_METEO_URL = 'https://api.open-meteo.com/v1/forecast';
    // A política de uso do Nominatim exige um User-Agent que identifique a aplicação.
    private static final String USER_AGENT = 'Salesforce-PrevisaoTempo/1.0';
    private static final Integer TIMEOUT_MS = 10000;

    @AuraEnabled
    public static Map<String, Object> getPrevisao(Id accId) {
        List<Account> contas = [
            SELECT Id, BillingCity
            FROM Account
            WHERE Id = :accId
            WITH USER_MODE
            LIMIT 1
        ];
        if (contas.isEmpty()) {
            throw erro('Conta não encontrada.');
        }

        String cidade = contas[0].BillingCity;
        if (String.isBlank(cidade)) {
            throw erro('Cidade de cobrança não informada nesta conta.');
        }

        Map<String, Object> latLong = getLatLong(cidade);
        if (latLong == null) {
            throw erro('Cidade não encontrada: ' + cidade);
        }

        String lat = String.valueOf(latLong.get('lat'));
        String lon = String.valueOf(latLong.get('lon'));

        HttpResponse res = enviar(
            OPEN_METEO_URL + '?latitude=' + lat + '&longitude=' + lon
            + '&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto&forecast_days=7'
        );
        if (res.getStatusCode() != 200) {
            throw erro('Erro ao buscar previsão (HTTP ' + res.getStatusCode() + ').');
        }

        return new Map<String, Object>{
            'cidade' => cidade,
            'dados' => JSON.deserializeUntyped(res.getBody())
        };
    }

    @TestVisible
    private static Map<String, Object> getLatLong(String cidade) {
        HttpResponse res = enviar(
            NOMINATIM_URL + '?q=' + EncodingUtil.urlEncode(cidade, 'UTF-8') + '&format=json&limit=1'
        );
        if (res.getStatusCode() != 200) {
            throw erro('Erro ao localizar a cidade (HTTP ' + res.getStatusCode() + ').');
        }

        List<Object> resultados = (List<Object>) JSON.deserializeUntyped(res.getBody());
        return resultados.isEmpty() ? null : (Map<String, Object>) resultados[0];
    }

    private static HttpResponse enviar(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('User-Agent', USER_AGENT);
        req.setHeader('Accept', 'application/json');
        req.setTimeout(TIMEOUT_MS);
        try {
            return new Http().send(req);
        } catch (CalloutException e) {
            throw erro('Serviço de previsão indisponível: ' + e.getMessage());
        }
    }

    // AuraHandledException só expõe a mensagem ao LWC (e aos testes) com setMessage.
    private static AuraHandledException erro(String mensagem) {
        AuraHandledException e = new AuraHandledException(mensagem);
        e.setMessage(mensagem);
        return e;
    }
}
