@IsTest
private class PrevisaoServiceTest {

    private static final String GEO_OK = '[{"lat":"-20.3155","lon":"-40.3128","display_name":"Vitória"}]';
    private static final String PREVISAO_OK =
        '{"daily":{"time":["2026-11-06","2026-11-07"],'
        + '"temperature_2m_max":[30.4,29.1],"temperature_2m_min":[22.2,21.8],"weathercode":[1,61]}}';

    private class MockHttp implements HttpCalloutMock {
        Integer statusGeo;
        String corpoGeo;
        Integer statusPrevisao;
        Boolean falharConexao = false;
        List<HttpRequest> requisicoes = new List<HttpRequest>();

        MockHttp(Integer statusGeo, String corpoGeo, Integer statusPrevisao) {
            this.statusGeo = statusGeo;
            this.corpoGeo = corpoGeo;
            this.statusPrevisao = statusPrevisao;
        }

        public HttpResponse respond(HttpRequest req) {
            requisicoes.add(req);
            if (falharConexao) {
                throw new CalloutException('Read timed out');
            }
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().startsWith(PrevisaoService.NOMINATIM_URL)) {
                res.setStatusCode(statusGeo);
                res.setBody(corpoGeo);
            } else {
                res.setStatusCode(statusPrevisao);
                res.setBody(statusPrevisao == 200 ? PREVISAO_OK : '{"error":true}');
            }
            return res;
        }
    }

    private static Id criarConta(String cidade) {
        Account acc = new Account(Name = 'Conta Previsão', BillingCity = cidade);
        insert acc;
        return acc.Id;
    }

    private static String mensagemDeErro(Id accId) {
        try {
            PrevisaoService.getPrevisao(accId);
        } catch (AuraHandledException e) {
            return e.getMessage();
        }
        Assert.fail('Era esperada uma AuraHandledException');
        return null;
    }

    @IsTest
    static void retornaPrevisaoDaCidadeDaConta() {
        Id accId = criarConta('Vitória');
        MockHttp mock = new MockHttp(200, GEO_OK, 200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Map<String, Object> resultado = PrevisaoService.getPrevisao(accId);
        Test.stopTest();

        Assert.areEqual('Vitória', resultado.get('cidade'));
        Map<String, Object> daily = (Map<String, Object>) ((Map<String, Object>) resultado.get('dados')).get('daily');
        Assert.areEqual(2, ((List<Object>) daily.get('time')).size());

        Assert.areEqual(2, mock.requisicoes.size(), 'Deve geocodificar e depois buscar a previsão');
        HttpRequest geo = mock.requisicoes[0];
        Assert.isTrue(geo.getEndpoint().contains('q=Vit%C3%B3ria'), 'Cidade deve ir codificada na URL');
        Assert.isFalse(String.isBlank(geo.getHeader('User-Agent')), 'Nominatim exige User-Agent');
        Assert.isTrue(mock.requisicoes[1].getEndpoint().contains('latitude=-20.3155&longitude=-40.3128'));
    }

    @IsTest
    static void contaSemCidadeNaoFazCallout() {
        Id accId = criarConta(null);
        MockHttp mock = new MockHttp(200, GEO_OK, 200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.areEqual('Cidade de cobrança não informada nesta conta.', msg);
        Assert.areEqual(0, mock.requisicoes.size());
    }

    @IsTest
    static void cidadeNaoEncontrada() {
        Id accId = criarConta('Cidade Inexistente XYZ');
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, '[]', 200));

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.areEqual('Cidade não encontrada: Cidade Inexistente XYZ', msg);
    }

    @IsTest
    static void erroHttpNoGeocoding() {
        Id accId = criarConta('Vitória');
        Test.setMock(HttpCalloutMock.class, new MockHttp(403, 'Access blocked', 200));

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.areEqual('Erro ao localizar a cidade (HTTP 403).', msg);
    }

    @IsTest
    static void erroHttpNaPrevisao() {
        Id accId = criarConta('Vitória');
        Test.setMock(HttpCalloutMock.class, new MockHttp(200, GEO_OK, 500));

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.areEqual('Erro ao buscar previsão (HTTP 500).', msg);
    }

    @IsTest
    static void falhaDeConexao() {
        Id accId = criarConta('Vitória');
        MockHttp mock = new MockHttp(200, GEO_OK, 200);
        mock.falharConexao = true;
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.isTrue(msg.startsWith('Serviço de previsão indisponível'), msg);
    }

    @IsTest
    static void contaInexistente() {
        Id accId = criarConta('Vitória');
        delete [SELECT Id FROM Account WHERE Id = :accId];

        Test.startTest();
        String msg = mensagemDeErro(accId);
        Test.stopTest();

        Assert.areEqual('Conta não encontrada.', msg);
    }
}
