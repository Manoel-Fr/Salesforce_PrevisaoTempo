import { LightningElement, api, track } from 'lwc';
import getPrevisao from '@salesforce/apex/PrevisaoService.getPrevisao';

export default class PrevisaoLwc extends LightningElement {

    @api recordId;
    @track cidade = '';
    @track previsoes = [];
    @track isLoading = true;
    @track error;

    connectedCallback() {
        this.carregarPrevisao();
    }
    
    
    async carregarPrevisao() {
        try {
            this.isLoading = true;
            const result = await getPrevisao({ accId: this.recordId });
            
            this.cidade = result.cidade || 'Cidade não informada';
            
           
            const dadosDiarios = result.dados.daily;
            const datas = dadosDiarios.time;
            const tempMax = dadosDiarios.temperature_2m_max;
            const tempMin = dadosDiarios.temperature_2m_min;
            const codigosClima = dadosDiarios.weathercode;
            
           
            this.previsoes = datas.map((data, index) => {
                return {
                    id: index,
                    data: this.formatarData(data),
                    diaSemana: this.obterDiaSemana(data),
                    temperaturaMax: Math.round(tempMax[index]),
                    temperaturaMin: Math.round(tempMin[index]),
                    codigoClima: codigosClima[index],
                    iconeClima: this.obterIconeClima(codigosClima[index]),
                    descricaoClima: this.obterDescricaoClima(codigosClima[index])
                };
            });
            
            this.error = undefined;
        } catch (error) {
            this.error = 'Erro ao carregar previsão: ' + (error.body?.message || error.message);
            this.previsoes = [];
        } finally {
            this.isLoading = false;
        }
    }
    
    formatarData(dataStr) {
        const data = new Date(dataStr + 'T00:00:00');
        const dia = data.getDate().toString().padStart(2, '0');
        const mes = (data.getMonth() + 1).toString().padStart(2, '0');
        return `${dia}/${mes}`;
    }
    
    obterDiaSemana(dataStr) {
        const data = new Date(dataStr + 'T00:00:00');
        const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
        return dias[data.getDay()];
    }


    get isMobile() {
        return /SalesforceMobile/i.test(window.navigator.userAgent);
    }
    
  
    obterIconeClima(codigo) {
        const mapaIcones = {
            0: '☀️',    // Céu limpo
            1: '🌤️',   // Principalmente limpo
            2: '⛅',   // Parcialmente nublado
            3: '☁️',   // Nublado
            45: '😶‍🌫️',  // Névoa
            48: '😶‍🌫️',  // Névoa depositando geada
            51: '🌦️',  // Garoa leve
            53: '🌦️',  // Garoa moderada
            55: '🌧️',  // Garoa densa
            61: '🌧️',  // Chuva leve
            63: '🌧️',  // Chuva moderada
            65: '⛈️',  // Chuva forte
            71: '🌨️',  // Neve leve
            73: '🌨️',  // Neve moderada
            75: '❄️',   // Neve forte
            77: '🌨️',  // Grãos de neve
            80: '🌦️',  // Pancadas de chuva leve
            81: '⛈️',  // Pancadas de chuva moderada
            82: '⛈️',  // Pancadas de chuva forte
            85: '🌨️',  // Pancadas de neve leve
            86: '❄️',   // Pancadas de neve forte
            95: '⛈️',  // Tempestade
            96: '⛈️',  // Tempestade com granizo leve
            99: '⛈️'   // Tempestade com granizo forte
        };
        return mapaIcones[codigo] || '🌡️';
    }
    
    obterDescricaoClima(codigo) {
        const mapaDescricoes = {
            0: 'Céu limpo',
            1: 'Principalmente limpo',
            2: 'Parcialmente nublado',
            3: 'Nublado',
            45: 'Névoa',
            48: 'Névoa com geada',
            51: 'Garoa leve',
            53: 'Garoa moderada',
            55: 'Garoa densa',
            61: 'Chuva leve',
            63: 'Chuva moderada',
            65: 'Chuva forte',
            71: 'Neve leve',
            73: 'Neve moderada',
            75: 'Neve forte',
            77: 'Grãos de neve',
            80: 'Pancadas leves',
            81: 'Pancadas moderadas',
            82: 'Pancadas fortes',
            85: 'Pancadas de neve',
            86: 'Neve forte',
            95: 'Tempestade',
            96: 'Tempestade c/ granizo',
            99: 'Tempestade forte'
        };
        return mapaDescricoes[codigo] || 'Clima indefinido';
    }
}