#!/bin/bash
# connect_shellhub.sh - Conexão automática ao ShellHub, vou alterar o resto.

# Configurações editáveis
SHELLHUB_SERVER="your-shellhub-server.com"
SHELLHUB_PORT="22"
SHELLHUB_USERNAME="your-username"
SHELLHUB_DEVICE="your-device-name"
SSH_KEY_PATH="$HOME/.ssh/id_rsa_shellhub"  # Chave SSH específica para ShellHub

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica dependências
check_dependencies() {
    local missing=()
    for cmd in ssh; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Erro: Dependências ausentes!${NC}"
        echo "Instale os seguintes pacotes: ${missing[*]}"
        exit 1
    fi
}

# Testa conexão com o servidor
test_connection() {
    echo -e "${YELLOW}Testando conexão com $SHELLHUB_SERVER...${NC}"
    if ! nc -z -w 5 "$SHELLHUB_SERVER" "$SHELLHUB_PORT"; then
        echo -e "${RED}Erro: Não foi possível conectar ao servidor ShellHub${NC}"
        echo "Verifique:"
        echo "1. Conectividade de rede"
        echo "2. Configurações de firewall"
        echo "3. Endereço do servidor: $SHELLHUB_SERVER"
        exit 1
    fi
}

# Conexão principal
connect() {
    local connection_string="$SHELLHUB_USERNAME@$SHELLHUB_SERVER"
    
    echo -e "${GREEN}Conectando a $SHELLHUB_DEVICE via ShellHub...${NC}"
    echo -e "Servidor: ${YELLOW}$connection_string${NC}"
    echo -e "Dispositivo: ${YELLOW}$SHELLHUB_DEVICE${NC}"
    echo -e "Utilizando chave SSH: ${YELLOW}$SSH_KEY_PATH${NC}"
    echo "----------------------------------------------"

    ssh -i "$SSH_KEY_PATH" \
        -p "$SHELLHUB_PORT" \
        -t "$connection_string" \
        "connect $SHELLHUB_DEVICE"
}

# Fluxo principal
main() {
    check_dependencies
    test_connection
    connect
}

main "$@"
