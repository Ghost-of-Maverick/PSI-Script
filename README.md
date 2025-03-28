# Projeto 2 - Segurança e Privacidade (2024/25)

Este repositório contém um script desenvolvido para o Projeto 2 da disciplina de Segurança e Privacidade do Mestrado em Segurança Informática da Universidade de Coimbra para o ano letivo 2024/25.

## Descrição

O script `psi_menu_runner.sh` foi criado para facilitar a execução e testes dos protocolos de Private Set Intersection (PSI) abordados no projeto. O mesmo permite a realização de dois tipos de testes:

- **Teste funcional com CSVs (demo.exe):** Pede os ficheiros CSV para realizar o teste.
- **Benchmark sintético (psi.exe):** Gera internamente os dados de entrada com base no número de elementos especificados através da opção `-n`, permitindo a medição do tempo de execução e do volume de dados trocados.

Adicionalmente, o script integra a captura de pacotes via Wireshark (utilizando `tshark`), armazenando as capturas na pasta `BASE_PATH/Wireshark`. Além disso é criada uma pasta `BASE_PATH/Wireshark` onde são guardados os outputs de cada execução. 

## Funcionalidades

- **Seleção de protocolo PSI:** Suporta os seguintes protocolos:
  - 0 – Naive Hash
  - 1 – Server-aided
  - 2 – Diffie-Hellman
  - 3 – OT-based
- **Dois tipos de testes:**
  - **Teste funcional (demo.exe):** O utilizador fornece os ficheiros CSV de entrada (por defeito, `platformA.csv` e `platformB.csv`), que devem estar na pasta `BASE_PATH/Datasets`.
  - **Benchmark sintético (psi.exe):** Os dados são gerados automaticamente com base no número de elementos (opção `-n`).
- **Captura de pacotes com Wireshark:** O script inicia automaticamente uma captura de pacotes (via `tshark`) durante os testes funcionais, guardando o ficheiro de captura em `BASE_PATH/Wireshark`.
- **Logs de execução:** São gerados e armazenados logs individuais para o cliente e o servidor na pasta `BASE_PATH/logs`.

## Requisitos

- **Sistema Operativo:** Linux (testado na distribuição Ubuntu 18.04 com `gnome-terminal`).
- **Permissões:** O script deve ser executado com privilégios de superutilizador (sudo).
- **Dependências:**
  - `tshark` (necessário para a captura de pacotes via Wireshark)
  - `gnome-terminal` (para a abertura de múltiplas janelas de terminal)
  - Os executáveis `demo.exe` e `psi.exe` devem estar disponíveis no diretório base (`BASE_PATH`).

## Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/Ghost-of-Maverick/PSI-Script/
2. Mudar permissões do script:
    ```bash
    chmod +x psi_menu_runner.sh
3. Executar o script:
   ```bash
   sudo ./psi_menu_runner.sh
