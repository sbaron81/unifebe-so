#!/bin/bash

# Definição de cores
GREEN="\e[32m"
RED="\e[31m"
BOLD="\e[1m"
RESET="\e[0m"

NOTA=0

#sudo apt install bc network-manager -y
sudo apt install bc -y

# Função para imprimir [OK]
print_ok() {
    echo -e "  ${BOLD}[${GREEN}PASS${RESET}${BOLD}]${RESET} $1"
}

# Função para imprimir [ERROR]
print_error() {
    echo -e "  ${BOLD}[${RED}NOT${RESET}${BOLD}]${RESET} $1"
}

# Função para formatar pontuação com 2 casas decimais
format_pontuacao() {
    pontuacao=$(echo "scale=2; ($1 / 1)" | bc )
    if echo "$pontuacao" | grep ^"\." >/dev/null ; then
       echo "0${pontuacao}" 
    elif echo "$pontuacao" | grep ^0 >/dev/null ; then
       echo "0.00"
    else   
       echo "$pontuacao"
    fi
}

# Função para verificar CPU, Memória, Disco e Placa de Rede
testa_requisitos() {
    cpus=$(nproc)
    memoria=$(free -k | awk '/^Mem:/ {print $2}')
    #disco=$(df -BG / | awk 'NR==2 {print $2}' | tr -d 'G')
    disco=$(fdisk -l /dev/sda | grep ^Disk | head -1 | sed -e 's/.*: //' -e 's/,.*//' | sed -e 's/ GiB//')
    placas=$(ip -o link show | grep -v 'lo' | wc -l)
    
    pontuacao=0

    if [[ "$cpus" -eq 2 ]]; then
        pontuacao=$(echo "scale=2; $pontuacao + 0.25" | bc)
    fi

    if [[ "$memoria" -ge 4000000 ]]; then
        pontuacao=$(echo "scale=2; $pontuacao + 0.25" | bc)
    fi

    if [[ "$disco" -ge 25 ]]; then
        pontuacao=$(echo "scale=2; $pontuacao + 0.25" | bc)
    fi

    if [[ "$placas" -eq 2 ]]; then
        pontuacao=$(echo "scale=2; $pontuacao + 0.25" | bc)
    fi

    echo -e "Questao 1: $(format_pontuacao "$pontuacao") de 1.00"

    [[ "$cpus" -eq 2 ]] && print_ok "CPUs: $cpus" || print_error "CPUs: $cpus (Esperado: 2)"
    [[ "$memoria" -ge 4000000 ]] && print_ok "Memória: ${memoria}KB" || print_error "Memória: ${memoria}KB (Esperado: 4GB ou mais)"
    [[ "$disco" -ge 25 ]] && print_ok "Espaço em Disco: ${disco}GB" || print_error "Espaço em Disco: ${disco}GB (Esperado: 25GB ou mais)"
    [[ "$placas" -eq 2 ]] && print_ok "Placas de Rede: $placas" || print_error "Placas de Rede: $placas (Esperado: 2)"
    
    NOTA=$(echo "scale=2; $NOTA + $pontuacao" | bc)
}

# Função para verificar idioma, teclado, DHCP, usuário, hostname e OpenSSH
testa_sistema() {
    idioma=$(locale | grep LANG= | cut -d= -f2)
    teclado=$(localectl status | grep "X11 Layout" | awk '{print $3}')
    #dhcp_count=$(nmcli device show | grep 'IP4.DHCP4' | wc -l)
    dhcp_count=$(ip ad  | grep dynamic | wc -l)
    usuario=$(grep ubuntu /etc/passwd | cut -d':' -f1 )
    hostname=$(hostname)
    openssh_instalado=$(dpkg -l | grep -q '^ii  openssh-server' && echo 1 || echo 0)
    
    pontuacao=0

    [[ "$idioma" == "C.UTF-8" ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)
    [[ "$teclado" == "br" ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)
    [[ "$dhcp_count" -ge 2 ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)
    [[ "$usuario" == "ubuntu" ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)
    [[ "$hostname" == "ubuntu" ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)
    [[ "$openssh_instalado" -eq 1 ]] && pontuacao=$(echo "scale=2; $pontuacao + 0.1667" | bc)

    echo -e "Questao 2: $(format_pontuacao $pontuacao) de 1.00"

    #[[ "$idioma" == "en_US.UTF-8" ]] && print_ok "Idioma: $idioma" || print_error "Idioma: $idioma (Esperado: en_US.UTF-8)"
    [[ "$idioma" == "C.UTF-8" ]] && print_ok "Idioma: $idioma" || print_error "Idioma: $idioma (Esperado: en_US.UTF-8)"
    [[ "$teclado" == "br" ]] && print_ok "Layout do Teclado: $teclado" || print_error "Layout do Teclado: $teclado (Esperado: br)"
    [[ "$dhcp_count" -ge 2 ]] && print_ok "DHCP Configurado para ambas placas de rede" || print_error "DHCP não configurado corretamente (Esperado: 2 interfaces com DHCP)"
    [[ "$usuario" == "ubuntu" ]] && print_ok "Usuário: $usuario" || print_error "Usuário: $usuario (Esperado: ubuntu)"
    [[ "$hostname" == "ubuntu" ]] && print_ok "Hostname: $hostname" || print_error "Hostname: $hostname (Esperado: ubuntu)"
    [[ "$openssh_instalado" -eq 1 ]] && print_ok "OpenSSH instalado" || print_error "OpenSSH não instalado"

    NOTA=$(echo "scale=2; $NOTA + $pontuacao" | bc)
}

# Função para verificar conexões SSH
testa_ssh() {
    ssh_logins=$(last -i | grep -i "pts" | wc -l)
    pontuacao=0
    [[ "$ssh_logins" -gt 0 ]] && pontuacao=1
    
    echo -e "Questao 3: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "scale=2; $NOTA + $pontuacao" | bc)

    if [[ "$ssh_logins" -gt 0 ]]; then
        pontuacao=1.00
        print_ok "Acesso via SSH."
    else
        print_error "Nenhuma conexão SSH detectada."
    fi
}

# Função para verificar se o usuário é root
testa_usuario_root() {
    user_cur=$(whoami)
    pontuacao=0
    [[ "$user_cur" == "root" ]] && pontuacao=1    
    echo -e "Questao 4: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "scale=2; $NOTA + $pontuacao" | bc)
    if [[ "$user_cur" == "root" ]] ; then
        print_ok "Usuário root identificado."
    else
        print_error "Usuário não é root."
    fi
    
}

# Função para verificar pacotes essenciais
testa_pacotes() {
    pacotes=(wget git vim cowsay)
    pontuacao=0
    for pacote in "${pacotes[@]}"; do
        dpkg -l | grep -q "^ii  $pacote" && pontuacao=$(echo "$pontuacao + 0.25" | bc); 
    done
    echo -e "Questao 5: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "$NOTA + $pontuacao" | bc)

    for pacote in "${pacotes[@]}"; do
        dpkg -l | grep -q "^ii  $pacote" && print_ok "$pacote instalado" || { print_error "$pacote não instalado"; pontuacao=$(echo "$pontuacao - 0.25" | bc); }
    done
}

# Função para verificar arquivo
testa_arquivo() {
    arquivo="/root/alunos.txt"
    pontuacao=0
    qtd=0
    [[ -f "$arquivo" ]] && qtd=$(cat $arquivo | wc -l) 
    [[ $qtd -ge 1 ]] && pontuacao=1
    
    echo -e "Questao 6: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "$NOTA + $pontuacao" | bc)

    if [[ $qtd -ge 1 ]]; then
        print_ok "Arquivo $arquivo existente" 
        echo "   Quantidade de alunos: $qtd"
        echo "-[Alunos]-----8<-----------"
        cat $arquivo
        echo "-------->8-----------------"
    else
        print_error "Arquivo $arquivo nao encontrado" 
    fi
}

# Função para verificar se foi baixado o arquivo
testa_download() {
    arquivo="run-me.sh"
    pontuacao=0
    qtd=$(find / -name $arquivo 2>/dev/null | wc -l)
    [[ $qtd -ge 1 ]] && pontuacao=1
    
    echo -e "Questao 7: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "$NOTA + $pontuacao" | bc)

    if [[ $pontuacao -eq 1 ]]; then
        print_ok "Arquivo $arquivo existente" 
    else
        print_error "Arquivo $arquivo nao encontrado" 
    fi
}

# Função para verificar criacao pasta e permissao arquivo
testa_pasta() {
    pasta="/opt/unifebe"
    arquivo="run-me.sh"
    pontuacao=0
    p=0
    a=0
    au=0
    ag=0
    ao=0
    PERMISSOES=$(stat -c "%A" "$pasta/$arquivo" 2>/dev/null)

    [[ -d "$pasta" ]] && p=1 && pontuacao=$(echo "$pontuacao + 0.2" | bc)
    [[ -f "$pasta/$arquivo" ]] && a=1 && pontuacao=$(echo "$pontuacao + 0.2" | bc)
    [[ ${PERMISSOES:1:3} == "rwx" ]] && au=1 && pontuacao=$(echo "$pontuacao + 0.2" | bc)
    [[ ${PERMISSOES:4:1} == "r" ]] && ag=1 && pontuacao=$(echo "$pontuacao + 0.2" | bc)
    [[ ${PERMISSOES:7:3} == "---" ]] && ao=1 && pontuacao=$(echo "$pontuacao + 0.2" | bc)
    
    echo -e "Questao 8: $(format_pontuacao $pontuacao) de 1.00"
    NOTA=$(echo "$NOTA + $pontuacao" | bc)

    [[ $p -eq 1 ]] && print_ok "Diretorio $pasta criado" || print_error "Diretorio $pasta nao criado" 
    [[ $a -eq 1 ]] && print_ok "Arquivo $pasta/$arquivo existente" || print_error "Arquivo $pasta/$arquivo nao encontrado" 
    [[ $au -eq 1 ]] && print_ok "Permissao correta de RWX para o usuario no arquivo $pasta/$arquivo" || print_error "Permissao nao esta correta de RWX para o usuario no arquivo $pasta/$arquivo"
    [[ $ag -eq 1 ]] && print_ok "Permissao correta de R-- para o grupo no arquivo $pasta/$arquivo" || print_error "Permissao nao esta correta de R-- para o grupo no arquivo $pasta/$arquivo"
    [[ $ao -eq 1 ]] && print_ok "Permissao correta de --- para o outros no arquivo $pasta/$arquivo" || print_error "Permissao nao esta correta de --- para o outros no arquivo $pasta/$arquivo"

}

# Função para testa execucao
testa_execucao() {
    pontuacao=1
    NOTA=$(echo "$NOTA + $pontuacao" | bc)
    echo -e "Questao 9: $(format_pontuacao $pontuacao) de 1.00"
    print_ok "Essa execucao aqui" 
    
}

# Função final
testa_final() {
    pontuacao=1
    NOTA=$(echo "$NOTA + $pontuacao" | bc)
    echo -e "Questao 10: $(format_pontuacao $pontuacao) de 1.00"
    print_ok "Pronto! Agora so tirar um printscreen, anexar no documento e postar o documento" 
    
}

# Chamando as funções
testa_requisitos
testa_sistema
testa_ssh
testa_usuario_root
testa_pacotes
testa_arquivo
testa_download
testa_pasta
testa_execucao
testa_final

# Exibição da pontuação final
echo -e "${BOLD}Nota Final: $(format_pontuacao "$NOTA") de 10.00${RESET}"
