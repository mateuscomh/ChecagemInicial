 Checagem inicializacao

#============================================================================================
       ARQUIVO:  CheckinInicial.sh
       DESCRICAO: Script com a finalidade de checagem prévia de hardware e serviços em servidores CentOS6
       REQUISITOS: 
       - OBRIGATÓRIO Script seja colocado na inicialização do sistema em /etc/rc.d/init.d/ChekinInicial.sh
       VERSAO:  0.1
       CRIADO:  04/04/2020
	AUTOR: Matheus Martins
       REVISAO:  ---
       CHANGELOG:
       04/04/2020 18:30
       - Gerado script para checagem dos serviços basicos de sistema
       05/04/2020 10:00
       - Implementado validação do status do asterisk caso houver no servidor

#=============================================================================================
