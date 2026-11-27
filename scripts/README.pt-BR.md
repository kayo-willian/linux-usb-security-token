# Ferramentas interativas do projeto

[English](README.md) · [Visão geral do projeto](../README.pt-BR.md)

Os scripts atendem a um sistema já configurado conforme o [Método 02 — Parte 02](../method-02/part-02.pt-BR.md). Oferecem diagnóstico, backups, testes guiados e recuperação do GDM. **A instalação do pam_usb e a configuração completa do método são etapas separadas.**

## Abrir o menu

Na raiz do repositório, execute o comando abaixo.

```bash
bash scripts/menu.sh
```

Abra o menu com uma conta comum. As opções administrativas solicitam `sudo`. Em um TTY de root, informe a conta cadastrada de usuário comum para realizar os testes de autenticação.

| Opção do menu | Script | Efeito |
| --- | --- | --- |
| Diagnóstico | `diagnostics.sh` | Consulta o ambiente, volumes, ferramentas, configurações PAM, regras e sessões |
| Backup | `backup.sh` | Copia a configuração para um diretório privado em `/root` |
| Testes de autenticação | `test-authentication.sh` | Executa três tentativas reais e interativas com `pamtester` |
| Recuperação | `recover-access.sh` | Após confirmação e backup, comenta a regra USB obrigatória do GDM |

Também é possível executar os scripts individualmente na raiz do repositório.

```bash
bash scripts/diagnostics.sh
sudo bash scripts/backup.sh
sudo bash scripts/test-authentication.sh henrique
sudo bash scripts/recover-access.sh
```

Os scripts de entrada aceitam `--help`. Invocá-los com `bash` dispensa a permissão de execução no arquivo.

## Dependências

O ambiente registrado usa Debian 13, Bash, utilitários básicos de sistema e Python 3. Somente os testes reais de autenticação exigem `pamtester`.

```bash
sudo apt update
sudo apt install -y pamtester
```

A conta e o dispositivo USB devem estar cadastrados no `pam_usb`. Exibir a ajuda não instala dependências nem modifica a autenticação do sistema.

## Diagnóstico

`diagnostics.sh` é somente leitura. Não autentica com o USB nem renova os pads. Informa a configuração e as ferramentas disponíveis sem exibir o XML do `pam_usb` ou o conteúdo dos pads. A saída ainda pode conter nomes de contas, metadados do USB ou outras informações sensíveis. Revise antes de compartilhar.

Encontrar uma linha correspondente do PAM ou do udev não comprova o funcionamento da autenticação.

## Backup

`backup.sh` cria um diretório privado como `/root/usb-token-backup.XXXXXX` (modo `700`) e registra os arquivos copiados ou ausentes. A cópia inclui os itens abaixo.

- `/etc/pam.d/`
- `/usr/share/pam-configs/libpam-usb`, se presente
- `/etc/udev/rules.d/80-usb.rules`, se presente
- `/usr/local/bin/usb-lock.sh`, se presente
- `/etc/security/pam_usb.conf`, se presente

Pads USB, `/etc/shadow` e dados de usuário alheios ao projeto ficam fora da cópia. Mantenha o backup privado. Ele cobre só a configuração indicada e exige restauração manual.

## Testes guiados de autenticação

Use um TTY se possível (Ctrl + Alt + F3 ou, no notebook registrado, Ctrl + Alt + Fn + F3). Retirar o USB pode bloquear a sessão GNOME. O script chama `pamtester gdm-password USER authenticate` em três condições preparadas manualmente.

1. USB conectado e senha correta. Espera-se **sucesso**.
2. USB conectado e senha incorreta. Espera-se **falha**.
3. USB ausente e senha correta. Espera-se **falha**.

O `pamtester` solicita as senhas. O script não as captura. Uma autenticação real **pode renovar os pads USB**. Conclua as gravações e desmonte o pendrive com segurança antes de desconectá-lo.

O script encerra se o caso positivo falhar ou se um caso negativo tiver sucesso inesperado. Um resultado negativo também pode indicar erro do serviço. Confira a mensagem e o código de saída. Login gráfico, bloqueio na remoção, reconexão, encerramento de sessão e reinicialização continuam como verificações **manuais** da Parte 02.

## Recuperação

Use o TTY e a senha real da conta. Execute `sudo bash scripts/recover-access.sh`. O utilitário realiza as etapas abaixo.

1. Verifica se existe **exatamente uma** regra `auth required pam_usb.so` ativa em `gdm-password`.
2. Recusa outras regras ativas de autenticação USB e regras USB no `common-auth` compartilhado.
3. Exibe a alteração proposta e exige que se digite exatamente `CONFIRM`.
4. Cria um backup privado da configuração.
5. Comenta somente a regra USB obrigatória de `gdm-password`, preservando as demais linhas, a propriedade e as permissões do arquivo.

O editor Python grava em um arquivo temporário no mesmo diretório e faz a substituição atômica. Recusa links simbólicos e regras PAM ambíguas. Se a regra já estiver comentada, mantém o arquivo como está.

O utilitário **não** desbloqueia sessões, reinicia o GDM, desabilita o bloqueio udev por remoção nem restaura o sistema inteiro. Volte à interface gráfica e faça uma nova autenticação com senha. Para reativar a política final, restaure apenas a regra específica do GDM e repita os testes. **Mantenha desativado** o perfil USB global histórico da Parte 01.

## Verificações offline para desenvolvimento

```bash
python3 -m unittest discover -s tests -v
```

Os testes usam arquivos temporários para verificar o editor PAM, a recusa de regras suspeitas, a preservação de finais de linha e permissões, a execução repetida, a sintaxe Bash e a ajuda dos scripts. Não autenticam em uma pilha PAM real nem exigem USB físico.

O editor está em `scripts/lib/edit-gdm.py`. As funções comuns do shell ficam em `scripts/lib/common.sh`. Ambos são componentes internos, sem opção própria no menu.
