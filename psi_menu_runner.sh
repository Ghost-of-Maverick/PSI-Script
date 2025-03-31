#!/bin/bash

# =========================================================
#     Gestor de Testes para Protocolos PSI (Private Set Intersection)
# =========================================================

# Antes de iniciar, verifique o caminho BASE_PATH abaixo.
BASE_PATH="/home/PSI-master"
DATASETS_PATH="$BASE_PATH/Datasets"
LOG_PATH="$BASE_PATH/logs"
WIRESHARK_PATH="$BASE_PATH/Wireshark"

# Cores para mensagens no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sem cor

# Verifica permissões
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}Este script deve ser executado com permissões de superutilizador (sudo).${NC}"
  echo "Exemplo: sudo ./psi_menu_runner.sh"
  exit 1
fi

# Criação de diretorias necessários
mkdir -p "$LOG_PATH" "$WIRESHARK_PATH"

# Verifica se tshark está instalado
if ! command -v tshark >/dev/null 2>&1; then
  echo -e "${RED}Erro: tshark não encontrado.${NC}"
  echo "Instale o pacote tshark antes de continuar."
  exit 1
fi

# Mapeamento dos protocolos
declare -A protocols
protocols[0]="Naive Hash"
protocols[1]="Server-aided"
protocols[2]="Diffie-Hellman"
protocols[3]="OT-based"

# Menu principal
while true; do
  clear
  echo -e "${BLUE}===================================="
  echo "       Gestor de Testes PSI         "
  echo -e "====================================${NC}"
  echo ""
  echo "Selecione o protocolo a testar:"
  echo "  0 - Naive Hash"
  echo "  1 - Server-aided"
  echo "  2 - Diffie-Hellman"
  echo "  3 - OT-based"
  echo "  q - Sair"
  echo ""
  read -p "Opção: " proto

  if [[ "$proto" == "q" || "$proto" == "Q" ]]; then
    echo -e "${YELLOW}A encerrar...${NC}"
    break
  fi

  if [[ ! ${protocols[$proto]+_} ]]; then
    echo -e "${RED}Opção inválida.${NC}"
    read -p "Prima Enter para continuar..."
    continue
  fi

  echo ""
  echo "Escolha o tipo de teste:"
  echo "  1 - Teste funcional com ficheiros CSV (demo.exe)"
  echo "  2 - Benchmark sintético (psi.exe)"
  echo ""
  read -p "Opção: " test_type

  if [[ "$test_type" != "1" && "$test_type" != "2" ]]; then
    echo -e "${RED}Tipo de teste inválido.${NC}"
    read -p "Prima Enter para continuar..."
    continue
  fi

  proto_name="${protocols[$proto]}"
  timestamp=$(date +%Y%m%d_%H%M%S)

  if [[ "$test_type" == "1" ]]; then
    tag="demo"

    read -p "Ficheiro CSV para a plataforma A (default: datasetA.csv): " csv_a
    csv_a=${csv_a:-datasetA.csv}
    read -p "Ficheiro CSV para a plataforma B (default: datasetB.csv): " csv_b
    csv_b=${csv_b:-datasetB.csv}

    file_a="$DATASETS_PATH/$csv_a"
    file_b="$DATASETS_PATH/$csv_b"

    if [[ ! -f "$file_a" || ! -f "$file_b" ]]; then
      echo -e "${RED}Ficheiros CSV não encontrados em $DATASETS_PATH.${NC}"
      read -p "Prima Enter para continuar..."
      continue
    fi

    lines_a=$(wc -l < "$file_a")
    lines_b=$(wc -l < "$file_b")
    echo ""
    echo -e "${YELLOW}Resumo dos ficheiros:${NC}"
    echo " - $csv_a: $lines_a linhas"
    echo " - $csv_b: $lines_b linhas"

    log_server="$LOG_PATH/${tag}_proto${proto}_server_${timestamp}.log"
    log_client1="$LOG_PATH/${tag}_proto${proto}_client1_${timestamp}.log"
    log_client2="$LOG_PATH/${tag}_proto${proto}_client2_${timestamp}.log"
    cap_file="$WIRESHARK_PATH/${tag}_proto${proto}_${timestamp}.pcap"

    read -p "Interface de rede para captura Wireshark (default: any): " wireshark_interface
    wireshark_interface=${wireshark_interface:-any}

    echo ""
    echo -e "${BLUE}A iniciar captura Wireshark na interface '$wireshark_interface'...${NC}"
    echo "Ficheiro de destino: $cap_file"
    tshark -i "$wireshark_interface" -w "$cap_file" > "$WIRESHARK_PATH/tshark_debug.log" 2>&1 &
    tshark_pid=$!

    sleep 2
    if ps -p $tshark_pid > /dev/null; then
      echo -e "${GREEN}tshark iniciado com sucesso (PID: $tshark_pid)${NC}"
    else
      echo -e "${RED}Erro: tshark não iniciou corretamente.${NC}"
      echo "Consulte o log: $WIRESHARK_PATH/tshark_debug.log"
      read -p "Prima Enter para continuar..."
      continue
    fi

    echo ""
    echo -e "${BLUE}A iniciar execução dos binários...${NC}"

    if [[ "$proto" == "1" ]]; then
    # Run server (requires a file, even though it doesn't use it)
    "$BASE_PATH/demo.exe" -r 0 -p 1 -f "$BASE_PATH/README.md" | tee "$log_server" &
    server_pid=$! 

    # Run both clients with -r 1
    "$BASE_PATH/demo.exe" -r 1 -p 1 -f "$file_a" | tee "$log_client1" &
    client1_pid=$!

    "$BASE_PATH/demo.exe" -r 1 -p 1 -f "$file_b" | tee "$log_client2" &
    client2_pid=$!

    echo "A aguardar conclusão..."

    wait $client1_pid
    wait $client2_pid
    kill "$server_pid" 2>/dev/null
    wait "$server_pid" 2>/dev/null
    else
    # Default: 1 server, 1 client
    log_client="$LOG_PATH/${tag}_proto${proto}_client_${timestamp}.log"

    "$BASE_PATH/demo.exe" -r 0 -p "$proto" -f "$file_b" | tee "$log_server" &
    server_pid=$!

    "$BASE_PATH/demo.exe" -r 1 -p "$proto" -f "$file_a" | tee "$log_client" &
    client_pid=$!

    echo "A aguardar conclusão..."

    wait $client_pid
    wait $server_pid
    fi

    echo ""
    echo -e "${YELLOW}A encerrar captura Wireshark...${NC}"
    kill "$tshark_pid" 2>/dev/null
    wait "$tshark_pid" 2>/dev/null

    if [[ -f "$cap_file" && -s "$cap_file" ]]; then
      echo -e "${GREEN}Captura concluída com sucesso!${NC}"
      echo "Ficheiro guardado em: $cap_file"
    else
      echo -e "${RED}A captura falhou ou está vazia.${NC}"
      echo "Consulte o log: $WIRESHARK_PATH/tshark_debug.log"
    fi

    read -p "Prima Enter para regressar ao menu..."

  else
    tag="psi"
    read -p "Número de elementos para o benchmark: " size

    log_client="$LOG_PATH/${tag}_proto${proto}_size${size}_client_${timestamp}.log"
    log_server="$LOG_PATH/${tag}_proto${proto}_size${size}_server_${timestamp}.log"

    gnome-terminal --title="Servidor - $proto_name" -- bash -c \
      "$BASE_PATH/psi.exe -r 0 -p $proto -b 16 -n $size | tee $log_server; exec bash"
    sleep 1
    gnome-terminal --title="Cliente - $proto_name" -- bash -c \
      "$BASE_PATH/psi.exe -r 1 -p $proto -b 16 -n $size | tee $log_client; exec bash"

    echo ""
    read -p "Benchmark iniciado. Prima Enter para regressar ao menu..."
  fi

done
