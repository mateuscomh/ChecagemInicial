#!/bin/bash

#============================================================================================
#       ARQUIVO:  CheckinInicial.sh
#       DESCRICAO: Script com a finalidade de checagem prévia de hardware e serviços em servidores CentOS6
#       REQUISITOS: 
#       - OBRIGATÓRIO Script seja colocado na inicialização do sistema em /etc/rc.d/init.d/ChekinInicial.sh
#       - OBRIGATÓRIO caminho de montagem em /mnt para discos e unidades de rede.
#       HOMOLOGADO: CENTOS6
#       VERSAO:  0.3
#       CRIADO:  04/04/2020
#	AUTOR: Matheus Martins
#       REVISAO:  ---
#       CHANGELOG:
#       04/04/2020 18:30
#       - Gerado script para checagem dos serviços basicos de sistema
#       05/04/2020 10:00
#       - Implementado validação do status do asterisk caso houver no servidor
#       - Adicionada função de validação de swap e memória livre/em uso
#       - Adicionadas condições de case e ajustes em tests if
#       - Nova branch para homologação em CENTOS6
#=============================================================================================



######################
# Verificar SERVICOS #
# Verificar = 1      #
# Não verificar = 0  #
######################

ENABLESCRIPT=1
SYSTEM=0
ASTERISK=0
POSTGRESQL=0
AUTOMACAO=0 #pendente

#VARIAVEIS
#particao="/dev/mapper/fedora_localhost--live-root" 
particao="/"
#Informar o caminho da distribuição a qual for utilizar
#Validado inicialmente no fedora 30 o caminho particao com LVM é /dev/mapper/fedora_localhost--live-root
#Em CentOS validar o caminho absoluto
#Validar em discos virtuais 

#CORES
padrao="\033[0;0m"
vermelho="\033[0;31m"
amarelo="\033[1;33m"
verde="\033[0;32m"
negrito="\033[;1m"
azul="\033[1;94m"

echo -e "ATENÇÃO!!!
￼VALIDAÇÃO INICIAL DE SISTEMA PADRONIZADA:
￼NÃO IMPLICA NA OBSERVANCIA USUAL DAS DEMAIS APLICAÇÕES E TESTES.
￼ ____  _   ___  __
￼/ ___|| \ | \ \/ /
￼\___ \|  \| |\  / 
￼ ___) | |\  |/  \ 
￼|____/|_| \_/_/\_\\
￼"

if [[ "$ENABLESCRIPT" -eq "0" ]]; then
    echo "exiting"
    exit 0
fi

check_system(){
    case $SYSTEM in
    0)
    ;;
    1)  #SISTEMA OPERACIONAL
            #echo -e "VERSAO DE SISTEMA: $azul$(cat /etc/os-release | grep -i pretty |  cut -d "=" -f2)""$padrao"
        echo -e "VERSAO DE SISTEMA: $azul$(cat /etc/redhat-release)""$padrao"
        #HORARIO
        echo -e "UTC:           $negrito$(date '+%Z  %d/%m/%Y  %H:%M:%S')""$padrao"
        #UPTIME
        uptime=$(uptime | awk '{print$3,$4}' |sed 's/,//g')
        echo -e "UPTIME DE SISTEMA :         $negrito$uptime "" $(w | grep users | awk '{print $6}') $padrao users" 

        #DISCO
        percentdisco=$(df -h "$particao" |sed -n '2p' | awk '{print $5}'| grep -v Use |sed 's/%//g')
        totaldisco=$(df -h "$particao" | sed -n '2p' | awk '{print $2}')
        usadodisco=$(df -h "$particao" | sed -n '2p' | awk '{print $3}')
        if [[ -z "$percentdisco" ]]; then
                percentdisco=$(df -h $particao |sed -n '3p' | awk '{print $4}'| grep -v Use |sed 's/%//g')
        fi
        if [[ "$percentdisco" -le "50" ]]; then
                echo -e "ESPAÇO UTILIZADO EM /: TOTAL:$verde$totaldisco$padrao USADO:$verde$usadodisco $percentdisco%""$padrao EM USO"
        elif [[ "$percentdisco" -ge "51" ]] && [ $percentdisco -le 74 ]; then
                echo -e "ESPAÇO UTILIZADO EM /: TOTAL:$amarelo$totaldisco$padrao USADO:$amarelo$usadodisco = $amarelo$percentdisco%""$padrao EM USO"
        elif [[ "$percentdisco" -ge "76" ]]; then
                echo -e "ESPAÇO UTILIZADO EM /: TOTAL:$vermelho$totaldisco$padrao USADO:$vermelho$usadodisco = $vermelho$percentdisco%""$padrao EM USO"
        fi

        #IO wait
        wa=`top -bin 1 | grep '%wa'| awk '{print $6}' | sed 's/\%wa,//'`
        if [[ -z "$wa" ]]; then
            wa=$(top -bin 1 | grep ' wa'| awk '{print $10}')
            #Multiplo de 10 para comparação de inteiros
            wa10=$(echo $wa | sed 's/\,//')
        else
            wa10=$(echo $wa | sed 's/\%wa,//' | sed 's/\.//')
        fi
        if [[ "$wa10" -le "20" ]]; then
            echo -e "IOWAIT (wa)           : $verde$wa""$padrao"
        elif [[ "$wa10" -ge "21" ]] && [[ "$wa10" -le "49" ]]; then
            echo -e "IOWAIT (wa)           : $amarelo$wa""$padrao"
        elif [[ "$wa10" -ge "50" ]]; then
                    echo -e "IOWAIT (wa)           : $vermelho$wa""$padrao"
        fi

        #CPU
        threads=$(nproc)
        load=$(cat /proc/loadavg | cut -d ' ' -f 1)
        #Multiplo de 100 para comparar somente inteiros
        load100=$(cat /proc/loadavg | cut -d ' ' -f 1| sed 's/\.//')
        if [[ "$load100" -le $(($threads*50)) ]]; then
        #Ajuste de formatação da quantidade de threads quando tem 1 digito
            if [[ "$threads" -le "9" ]]; then
            echo -e "CPU LOAD $threads"" NUCLEOS          : $verde$load""$padrao"
        else
        echo -e "CPU LOAD $threads""N          : $verde$load""$padrao"
        fi
        elif [[ "$load100" -ge $(($threads*50)) ]] && [[ "$load100" -le "$(($threads*74))" ]]; then
        if [[ "$threads" -le "9" ]]; then
                echo -e "CPU LOAD ""$threads           : $amarelo$load""$padrao"
            else
        echo -e "CPU LOAD $threads"" NUCLEOS          : $amarelo$load""$padrao"
        fi
        elif [[ "$load100" -ge $(($threads*75)) ]]; then
        if [[ "$threads" -le "9" ]]; then
        echo -e "CPU LOAD ""$threads           : $vermelho$load""$padrao"
            else
        echo -e "CPU LOAD $threads"" NUCLEOS          : $vermelho$load""$padrao"
            fi
        fi
        #echo -e "CPU THREADS           : $threads"

        #MEMORY
        totalmem="$(free -m | grep -i "mem" | awk '{print  $2}')"
        usadamem="$(free -m | grep -i "mem" | awk '{print  $3}')"
        percentmem="$(bc<<<"scale=0;$usadamem*100/$totalmem")"
        totalswap="$(free -m | grep -i "swap" | awk '{print  $2}')"
        usadaswap="$(free -m | grep -i "swap" | awk '{print  $3}')"
        percentswap="$(bc<<<"scale=0;$usadaswap*100/$totalswap")"
        
                echo -e  "MEMORIA TOTAL: $negrito$(bc<<<"scale=2;$totalmem/1000")GB" "$padrao"
            if [[ "$percentmem" -le "50" ]]; then
                echo -e "MEMÓRIA EM USO $negrito$usadamem MB $verde$percentmem%" "$padrao"
            elif [[ "$percentmem" -ge "51" ]] && [[ "$percentmem" -le "75" ]]; then
                echo -e "MEMORIA EM USO $negrito$usadamem MB $amarelo$percentmem%""$padrao"
            elif [[ "$percentmem" -ge "76" ]]; then
                echo -e "MEMORIA EM USO $negrito$usadamem MB $vermeho$percentmem%""$padrao"
            fi

        echo -e "SWAP TOTAL: $negrito$totalswap MB" "$padrao"
            if [[ "$percentswap" -le "20" ]]; then
                echo -e "SWAP EM USO $negrito$usadaswap MB $verde$percentswap%" "$padrao"
            elif [[ "$percentmem" -ge "21" ]] && [[ "$percentmem" -le "50" ]]; then
                echo -e "SWAP EM USO $negrito$usadaswap MB $amarelo$percentswap%""$padrao"
            elif [[ "$percentmem" -ge "51" ]]; then
                echo -e "SWAP EM USO $negrito$usadaswap MB $vermeho$percentswap%""$padrao"
            fi
    ;;
    *) echo -e "Opção desconhecida no script nas variáveis em SYSTEM. Utilize expressões 0 para desabilitar ou 1 para habilitar"
    ;;
    esac
}

check_asterisk(){
    case $ASTERISK in
    0)
    ;;
    1)  if [[ -f "/etc/init.d/asterisk" ]]; then
            if ps ax | grep -v grep | grep asterisk > /dev/null; then
                echo -e "$verde Asterisk Executando!""$padrao"
            else
                echo -e "$vermelho Asterisk Parado!!!""$padrao"
            fi
        else
            echo -e "$amarelo Serviço Asterisk não localizado!!""$padrao"
        fi
            ;;
    *) echo -e "Opção desconhecida no script nas variáveis em SYSTEM. Utilize expressões 0 para desabilitar ou 1 para habilitar"
    ;;
    esac
}
check_db(){
    case $POSTGRESQL in
    0)
    ;;
    1) if [ -f "/etc/init.d/postgresql" ]; then
                if ps ax | grep -v grep | grep postgres > /dev/null; then

                        echo -e "$verde postgreSQL Executando!""$padrao"
                else
                        echo -e "$vermelho PostgreSQL Parado!!!""$padrao"
                fi
        else
            echo -e "$amarelo Serviço PostgreSQL não localizado!!""$padrao"
        fi
    ;;
    *) echo -e "Opção desconhecida no script nas variáveis em SYSTEM. Utilize expressões 0 para desabilitar ou 1 para habilitar"
    ;;
    esac
}

#check_automacao(){
#em andamento
#msg para print
#echo -e "$amarelo Serviço Automacao não localizado!!""$padrao"
#}



###########

check_system
check_db
#check_automacao
check_asterisk

#Se colocar no etc/profile, exit0 não pode conter no script
#exit 0
        
