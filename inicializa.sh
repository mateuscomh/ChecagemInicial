#!/bin/bash

#============================================================================================
#       ARQUIVO:  CheckinInicial.sh
#       DESCRICAO: Script com a finalidade de checagem prévia de hardware e serviços em servidores CentOS6
#       REQUISITOS: 
#       - OBRIGATÓRIO Script seja colocado na inicialização do sistema em /etc/rc.d/init.d/ChekinInicial.sh
#       - OBRIGATÓRIO caminho de montagem em /mnt para discos e unidades de rede.
#       - Todos os ajustes de cada cliente deverão ser escritos no arquivo de variáveis PARAMETOSBKPBD.
#       VERSAO:  0.1
#       CRIADO:  04/04/2020
#	AUTOR: Matheus Martins
#       REVISAO:  ---
#       CHANGELOG:
#       04/04/2020 18:30
#       - Gerado script para checagem dos serviços basicos de sistema
#       05/04/2020 10:00
#       - Implementado validação do status do asterisk caso houver no servidor
#
#=============================================================================================



######################
# Verificar SERVICOS #
#                    #          
# Verificar = 1      #
# Não verificar = 0  #
#                    #
######################

ENABLESCRIPT=1
SYSTEM=1
ASTERISK=0
POSTGRESQL=0
AUTOMACAO=0

#CORES
padrao="\033[0m"
vermelho="\033[0;31m"
amarelo="\033[1;33m"
verde="\033[0;32m"
negrito="\033[;1m"
azul="\033[1;94m"
particao="/dev/mapper/fedora_localhost--live-root" 


#echo mensagens iniciais MOTD
#adicionar case no inicio do script ao inves de if
#https://www.dicas-l.com.br/arquivo/case_em_bash.php

if [ $ENABLESCRIPT -eq 0 ]; then
    echo "exiting"
    exit 0
fi

check_system(){

    #Monitorar memoria e swap

    if [ $SYSTEM -eq 1 ]; then
        #SISTEMA OPERACIONAL
        echo -e "VERSAO DE SISTEMA $azul$(cat /etc/os-release | grep -i pretty | cut -c13-45)""$padrao"
        #HORARIO
        echo -e "UTC:           $negrito$(date '+%Z  %Y/%m/%d  %H:%M:%S')""$padrao"
        #UPTIME
        uptime=$(uptime | awk '{print$3,$4}' |sed 's/,//g')
        echo -e "UPTIME DE SISTEMA :         $negrito$uptime""$padrao" 

        #DISCO
        disco=$(df -h $particao |sed -n '2p' | awk '{print $5}'| grep -v Use |sed 's/%//g')
        if [ -z $disco ]; then
                disco=$(df -h $particao |sed -n '3p' | awk '{print $4}'| grep -v Use |sed 's/%//g')
        fi
        if [ $disco -le 50 ]; then
                echo -e "ESPAÇO UTILIZADO $particao:            $verde$disco%""$padrao"
        elif [ $disco -ge 51 ] && [ $disco -le 74 ]; then
                echo -e "ESPAÇO UTILIZADO $particao:            $amarelo$disco%""$padrao"
        elif [ $disco -ge 76 ]; then
                echo -e "ESPAÇO UTILIZADO $particao:            $vermelho$disco%""$padrao"
        fi

        #IO wait
        wa=`top -bin 1 | grep '%wa'| awk '{print $6}' | sed 's/\%wa,//'`
        if [ -z $wa ]; then
            wa=`top -bin 1 | grep ' wa'| awk '{print $10}'`
            #Multiplo de 10 para comparação de inteiros
            wa10=`echo $wa | sed 's/\,//'`
        else
            wa10=`echo $wa | sed 's/\%wa,//' | sed 's/\.//'`
        fi
        if [ $wa10 -le 20 ]; then
            echo -e "IOWAIT (wa)           : $verde$wa""$padrao"
        elif [ $wa10 -ge 21 ] && [ $wa10 -le 49 ]; then
            echo -e "IOWAIT (wa)           : $amarelo$wa""$padrao"
        elif [ $wa10 -ge 21 ] && [ $wa10 -le 49 ]; then
            echo -e "IOWAIT (wa)           : $amarelo$wa""$padrao"
        elif [ $wa10 -ge 50 ]; then
            echo -e "IOWAIT (wa)           : $vermelho$wa""$padrao"
        fi

        #CPU
        threads=`nproc`
        load=`cat /proc/loadavg | cut -d ' ' -f 1`
        #multiplo de 100 para comparar somente inteiros
        load100=`cat /proc/loadavg | cut -d ' ' -f 1| sed 's/\.//'`
        if [ $load100 -le $(($threads*50)) ]; then
        #Ajuste de formatação da quantidade de threads quando tem 1 digito
            if [ $threads -le 9 ]; then
            echo -e "CPU LOAD 0$threads""N          : $verde$load""$padrao"
        else
        echo -e "CPU LOAD $threads""N          : $verde$load""$padrao"
        fi
        elif [ $load100 -ge $(($threads*50)) ] && [ $load100 -le $(($threads*74)) ]; then
        if [ $threads -le 9 ]; then
                echo -e "CPU LOAD 0""$threads           : $amarelo$load""$padrao"
            else
        echo -e "CPU LOAD $threads""N          : $amarelo$load""$padrao"
        fi
        elif [ $load100 -ge $(($threads*75)) ]; then
        if [ $threads -le 9 ]; then
        echo -e "CPU LOAD 0""$threads           : $vermelho$load""$padrao"
            else
        echo -e "CPU LOAD $threads""N          : $vermelho$load""$padrao"
            fi
        fi
        #echo -e "CPU THREADS           : $threads"
        
        #MEMORY
            total=$(top | free '/Men:/ { print $1 }')
            usada=$(top | free '/Men:/ { print $2 }')

         echo " $    total de uso da Men: ${usada}..."
            #(Exibe a seguinte mensagen)........................................#
            echo " dados de uso atual em tempo real" 
    fi
}

check_asterisk(){
    if [[ "$ASTERISK" = "1" ]]; then
        if [ -d "/etc/asterisk" ]; then
            if ps ax | grep -v grep | grep asterisk > /dev/null; then
                echo -e "$verde Asterisk Executando!""$padrao"
            else
                echo -e "$vermelho Asterisk Parado!!!""$padrao"
            fi
        else
            echo -e "$amarelo Serviço Asterisk não localizado!!""$padrao"
        fi
    fi
}
check_db(){
    if [ $POSTGRESQL -eq 1 ]; then
        if [ -d "/etc/postgresql/" ]; then
                if ps ax | grep -v grep | grep postgresql > /dev/null; then
                
                        echo -e "$verde postgreSQL Executando!""$padrao"
                else
                        echo -e "$vermelho PostgreSQL Parado!!!""$padrao"
                fi
        else
            echo -e "$amarelo Serviço PostgreSQL não localizado!!""$padrao"
        fi
    fi
}


###########

check_db
check_system

exit 0
