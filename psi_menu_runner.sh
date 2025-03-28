#!/bin/bash

# AVISOS DE USO:
#   - Para os testes funcionais (demo.exe), o utilizador deve indicar os ficheiros .csv para as plataformas A e B.
#   - Os ficheiros .csv devem estar na diretoria $BASE_PATH/Datasets ou ser indicado o caminho completo.
#   - Nos testes demo.exe, a captura Wireshark é gerida automaticamente: é criada uma pasta "Wireshark" onde se guarda a captura da transação.

# AVISO importante: antes de utilizar o script verificar a diretoria BASE_PATH ⚠️

# Verifica se o script está a correr como root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Este script deve ser executado com permissões de superutilizador (sudo)."
  echo "💡 Exemplo: sudo ./psi_menu_runner.sh"
  exit 1
fi

BASE_PATH="/home/PSI-master"
DATASETS_PATH="$BASE_PATH/Datasets"
LOG_PATH="$BASE_PATH/logs"
WIRESHARK_PATH="$BASE_PATH/Wireshark"
mkdir -p "$LOG_PATH"
mkdir -p "$WIRESHARK_PATH"

# Verifica se tshark está instalado (necessário para captura Wireshark)
if ! command -v tshark >/dev/null 2>&1; then
  echo "❌ tshark não encontrado. Instale tshark para capturar pacotes Wireshark."
  exit 1
fi

declare -A protocols
protocols[0]="Naive Hash"
protocols[1]="Server-aided"
protocols[2]="Diffie-Hellman"
protocols[3]="OT-based"

while true; do
  clear
  echo "============================="
  echo "   PSI Protocol Test Runner"
  echo "============================="
  echo ""
  echo "Select protocol to test:"
  echo "  0 - Naive Hash"
  echo "  1 - Server-aided"
  echo "  2 - Diffie-Hellman"
  echo "  3 - OT-based"
  echo "  q - Quit"
  read -p "Protocol: " proto

  # Sai se for 'q' ou 'Q'
  if [[ "$proto" == "q" || "$proto" == "Q" ]]; then
    echo "👋 A sair..."
    break
  fi

  if [[ ! ${protocols[$proto]+_} ]]; then
    echo "❌ Protocolo inválido."
    read -p "Pressiona Enter para continuar..."
    continue
  fi

  echo ""
  echo "Tipo de teste:"
  echo "  1 - Teste funcional com CSVs (demo.exe)"
  echo "  2 - Benchmark sintético (psi.exe)"
  read -p "Tipo de teste: " test_type

  if [[ "$test_type" != "1" && "$test_type" != "2" ]]; then
    echo "❌ Tipo de teste inválido."
    read -p "Pressiona Enter para continuar..."
    continue
  fi

  proto_name="${protocols[$proto]}"
  timestamp=$(date +%Y%m%d_%H%M%S)
  
  if [[ "$test_type" == "1" ]]; then
    tag="demo"
    # Para teste funcional com CSV, solicita-se os ficheiros CSV para plataformas A e B.
    read -p "Ficheiro CSV para plataforma A (default: platformA.csv): " csv_a
    csv_a=${csv_a:-platformA.csv}
    read -p "Ficheiro CSV para plataforma B (default: platformB.csv): " csv_b
    csv_b=${csv_b:-platformB.csv}

    file_a="$DATASETS_PATH/$csv_a"
    file_b="$DATASETS_PATH/$csv_b"

    if [[ ! -f "$file_a" || ! -f "$file_b" ]]; then
      echo "❌ Ficheiros CSV não encontrados em $DATASETS_PATH."
      read -p "Pressiona Enter para continuar..."
      continue
    fi

    # Exibe o número de linhas de cada ficheiro para informação do utilizador
    lines_a=$(wc -l < "$file_a")
    lines_b=$(wc -l < "$file_b")
    echo "ℹ️  $csv_a: $lines_a linhas"
    echo "ℹ️  $csv_b: $lines_b linhas"

    log_client="$LOG_PATH/${tag}_proto${proto}_client_${timestamp}.log"
    log_server="$LOG_PATH/${tag}_proto${proto}_server_${timestamp}.log"

    # Solicita a interface de rede para a captura Wireshark (padrão: any)
    read -p "Interface para captura Wireshark (default: any): " wireshark_interface
    wireshark_interface=${wireshark_interface:-any}
    cap_file="$WIRESHARK_PATH/${tag}_proto${proto}_${timestamp}.pcap"

    echo ""
    echo "🔍 Iniciando captura Wireshark na interface '$wireshark_interface'..."
    tshark -i "$wireshark_interface" -w "$cap_file" > /dev/null 2>&1 &
    tshark_pid=$!
    echo "📂 Captura a guardar em: $cap_file"

    gnome-terminal --title="Server - $proto_name" -- bash -c \
      "$BASE_PATH/demo.exe -r 0 -p $proto -f $file_b | tee $log_server; exec bash"
    sleep 1
    gnome-terminal --title="Client - $proto_name" -- bash -c \
      "$BASE_PATH/demo.exe -r 1 -p $proto -f $file_a | tee $log_client; exec bash"

    echo ""
    read -p "✅ Teste iniciado. Pressiona Enter para terminar a captura Wireshark e voltar ao menu..."
    kill "$tshark_pid" 2>/dev/null
    echo "🛑 Captura Wireshark terminada."

  else
    # Para benchmark com psi.exe, solicita o número de elementos.
    tag="psi"
    read -p "Número de elementos (benchmark): " size
    log_client="$LOG_PATH/${tag}_proto${proto}_size${size}_client_${timestamp}.log"
    log_server="$LOG_PATH/${tag}_proto${proto}_size${size}_server_${timestamp}.log"

    gnome-terminal --title="Bench Server - $proto_name" -- bash -c \
      "$BASE_PATH/psi.exe -r 0 -p $proto -b 16 -n $size | tee $log_server; exec bash"
    sleep 1
    gnome-terminal --title="Bench Client - $proto_name" -- bash -c \
      "$BASE_PATH/psi.exe -r 1 -p $proto -b 16 -n $size | tee $log_client; exec bash"

    echo ""
    read -p "✅ Teste iniciado. Pressiona Enter para voltar ao menu..."
  fi

done
