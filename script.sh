#!/bin/bash

# AVISOS DE USO
#   - o utilizador tem de alterar de forma manual o nome dos ficheiros .csv a usar [linhas 83 e 84]
#   - os ficheiros .csv tem de estar na diretoria $BASE_PATH!
#   - o tamanho dos datasets tambem não é verificado pelo script, apenas é feita a verificação de existência dos mesmos.
#   - nos testes demo.exe as capturas wireshark terão de ser geridas manualmente.

# Verifica se o script está a correr como root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Este script deve ser executado com permissões de superutilizador (sudo)."
  echo "💡 Exemplo: sudo ./psi_menu_runner.sh"
  exit 1
fi

BASE_PATH="/home/PSI-master"
LOG_PATH="$BASE_PATH/logs"
mkdir -p "$LOG_PATH"

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

  # Exit only if 'q' or 'Q' is typed
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

  echo ""
  if [[ "$test_type" == "1" ]]; then
    echo "Tamanhos disponíveis: 100, 300, 600, 1000, 1500"
  else
    echo "Número de elementos (benchmark): 5000, 10000, etc."
  fi
  read -p "Tamanho: " size

  proto_name="${protocols[$proto]}"
  timestamp=$(date +%Y%m%d_%H%M%S)
  tag=$([[ "$test_type" == "1" ]] && echo "demo" || echo "psi")
  log_client="$LOG_PATH/${tag}_proto${proto}_size${size}_client_${timestamp}.log"
  log_server="$LOG_PATH/${tag}_proto${proto}_size${size}_server_${timestamp}.log"

  echo ""
  echo "▶️ A correr $tag: Protocolo $proto ($proto_name), Tamanho: $size"
  echo "📄 Logs:"
  echo "  $log_server"
  echo "  $log_client"
  echo ""

  if [[ "$test_type" == "1" ]]; then
    file_a="$BASE_PATH/platformA_${size}.csv"
    file_b="$BASE_PATH/platformB_${size}.csv"

    if [[ ! -f "$file_a" || ! -f "$file_b" ]]; then
      echo "❌ Ficheiros CSV não encontrados."
      read -p "Pressiona Enter para continuar..."
      continue
    fi

    gnome-terminal --title="Server - $proto_name - $size" -- bash -c \
      "$BASE_PATH/demo.exe -r 0 -p $proto -f $file_b | tee $log_server; exec bash"

    sleep 1

    gnome-terminal --title="Client - $proto_name - $size" -- bash -c \
      "$BASE_PATH/demo.exe -r 1 -p $proto -f $file_a | tee $log_client; exec bash"

  else
    # Benchmarking com psi.exe (mesmo protocolo 1!)
    gnome-terminal --title="Bench Server - $proto_name - $size" -- bash -c \
      "$BASE_PATH/psi.exe -r 0 -p $proto -b 16 -n $size | tee $log_server; exec bash"

    sleep 1

    gnome-terminal --title="Bench Client - $proto_name - $size" -- bash -c \
      "$BASE_PATH/psi.exe -r 1 -p $proto -b 16 -n $size | tee $log_client; exec bash"
  fi

  echo ""
  read -p "✅ Teste iniciado. Pressiona Enter para voltar ao menu..."
done
