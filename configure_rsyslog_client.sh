#!/bin/bash
# auto_rsyslog.sh - Configuração automática de cliente Rsyslog

# Configurações editáveis (ajuste conforme necessário)
RSYSLOG_SERVER="seu_servidor_rsyslog.com"
RSYSLOG_PORT="514"
PROTOCOL="udp"  # udp ou tcp
LOG_FILES=(
    "/var/log/syslog"
    "/var/log/auth.log"
    "/var/log/kern.log"
)
TAG="myhost"    # Tag para identificar os logs

# Cores para feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica se é root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Erro: Este script deve ser executado como root!${NC}" >&2
        exit 1
    fi
}

# Verifica dependências
check_dependencies() {
    if ! command -v rsyslogd &> /dev/null; then
        echo -e "${YELLOW}Rsyslog não encontrado. Instalando...${NC}"
        apt-get update
        apt-get install -y rsyslog
        systemctl enable rsyslog
    fi
}

# Configura o cliente
configure_client() {
    local config_file="/etc/rsyslog.d/99-remote.conf"
    
    echo -e "${GREEN}Configurando envio de logs para ${YELLOW}$RSYSLOG_SERVER:$RSYSLOG_PORT${NC}"
    
    # Limpa configurações anteriores
> "$config_file"
    
    # Configura protocolo
    local protocol_char="@"
    if [ "$PROTOCOL" = "tcp" ]; then
        protocol_char="@@"
    fi

    # Configuração geral
    cat << EOF >> "$config_file"
# Configuração automática gerada em $(date)
module(load="imfile")

# Template para formatação das mensagens
template(name="RemoteFormat" type="string" string="<%PRI%>%TIMESTAMP% $TAG %syslogtag%%msg%")

# Regras de envio
*.* $protocol_char$RSYSLOG_SERVER:$RSYSLOG_PORT;RemoteFormat
EOF

    # Configura monitoramento de arquivos específicos
    for log_file in "${LOG_FILES[@]}"; do
        local file_id=$(echo "$log_file" | tr -d '/.' | cut -c-32)
        
        cat << EOF >> "$config_file"

# Monitoramento de: $log_file
input(type="imfile"
      File="$log_file"
      Tag="$TAG"
      StateFile="state_$file_id"
      Severity="info"
      Facility="local7")
EOF
    done
}

# Reinicia serviços
restart_services() {
    echo -e "${YELLOW}Reiniciando serviço Rsyslog...${NC}"
    systemctl restart rsyslog
    
    if systemctl is-active --quiet rsyslog; then
        echo -e "${GREEN}Rsyslog reiniciado com sucesso!${NC}"
        echo -e "\nStatus de envio de logs:"
        grep -i "$RSYSLOG_SERVER" /var/log/syslog | tail -n 3
    else
        echo -e "${RED}Falha ao reiniciar Rsyslog! Verifique com:${NC}"
        echo "journalctl -xe -u rsyslog"
        exit 1
    fi
}

# Testa conexão com servidor
test_connection() {
    echo -e "${YELLOW}Testando conectividade com $RSYSLOG_SERVER:$RSYSLOG_PORT...${NC}"
    
    if nc -zv -w 5 "$RSYSLOG_SERVER" "$RSYSLOG_PORT" &> /dev/null; then
        echo -e "${GREEN}Conexão bem sucedida via $PROTOCOL${NC}"
    else
        echo -e "${RED}Não foi possível conectar ao servidor Rsyslog!${NC}"
        echo "Verifique:"
        echo "1. Conectividade de rede"
        echo "2. Configurações de firewall"
        echo "3. Se o servidor Rsyslog está ouvindo na porta $RSYSLOG_PORT"
        exit 1
    fi
}

# Menu principal
main() {
    check_root
    check_dependencies
    test_connection
    configure_client
    restart_services
    
    echo -e "\n${GREEN}Configuração concluída com sucesso!${NC}"
    echo -e "Logs sendo enviados para: ${YELLOW}$RSYSLOG_SERVER:$RSYSLOG_PORT${NC}"
    echo -e "Arquivos monitorados:"
    printf " - %s\n" "${LOG_FILES[@]}"
}

main "$@"
