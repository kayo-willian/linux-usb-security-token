# Método 02 — Parte 02: USB e senha no GDM

[English](part-02.md) · [Visão geral do projeto](../README.pt-BR.md)

Os exemplos usam marcadores para o número de série do dispositivo e o UUID do volume.

**Estado registrado.** O mantenedor original aplicou o método no Debian 13 de um Lenovo IdeaPad 3i e validou um novo login após reinicialização. A adaptação do guia histórico **não** representa novos testes físicos.

[Visão geral](../README.pt-BR.md) · [Parte 01 (histórica)](part-01.pt-BR.md) · [Método 01](../method-01/README.pt-BR.md) · [Desativar temporariamente a proteção USB](../DISABLE_USB_TOKEN.pt-BR.md)

## 1. Objetivo e escopo

Substituir a política de **USB ou senha** da Parte 01 pela exigência de **USB e senha** para login e desbloqueio gráficos no serviço PAM `gdm-password`.

Dois mecanismos independentes compõem a configuração registrada.

- **Método 01, parcialmente ativo.** A remoção do USB solicita o bloqueio da sessão GNOME. A regra de desbloqueio automático na reconexão está **desativada**.
- **Método 02 — Parte 02.** O serviço `gdm-password` exige o USB reconhecido (`pam_usb`) e a senha da conta (`pam_unix` via `common-auth`).

O login por TTY e o `sudo` continuam usando a senha do sistema para permitir recuperação em caso de perda ou dano do pendrive. A política não abrange todos os serviços PAM, a inicialização ou o SSD.

## 2. Ambiente registrado

| Item | Valor registrado |
| --- | --- |
| Computador | Lenovo IdeaPad 3i |
| Sistema operacional | Debian GNU/Linux 13 (Trixie) instalado no SSD físico |
| Ambiente gráfico e login | GNOME com GDM |
| Usuário cadastrado | `henrique` |
| Pendrive | SanDisk Cruzer Blade de 4 GB nominais |
| Número de série informado | `EXAMPLE_USB_SERIAL` |
| Volume USB | FAT, UUID `EXAMPLE_VOLUME_UUID`, observado como `/dev/sda1` |
| SSD | `nvme0n1`, aproximadamente 238,5 GB, raiz em ext4 |
| pam_usb | Versão 0.9.3, instalada na Parte 01 |

O projeto começou em uma VM. **Esta etapa ocorreu na instalação física principal do Debian**, após substituir o Windows 11. Caminhos de dispositivos, IDs de sessão e pontos de montagem podem variar em outra máquina. Não use um caminho observado como identificador permanente.

### Configuração anterior à Parte 02

O arquivo `/etc/pam.d/common-auth` original continha o trecho abaixo.

```text
auth sufficient pam_usb.so
auth [success=1 default=ignore] pam_unix.so nullok try_first_pass
```

O perfil `/usr/share/pam-configs/libpam-usb` usava `sufficient pam_usb.so` em `Auth` e `Auth-Initial`. O arquivo `/etc/udev/rules.d/80-usb.rules` ainda chamava `usb-lock.sh unlock` ao conectar o USB.

Exigir o USB **sem desativar o desbloqueio automático** permitiria abrir a sessão gráfica sem senha. Por isso a configuração final desativa a regra de desbloqueio na conexão e transfere o requisito USB ao **serviço PAM específico do GDM**.

## 3. Preparar um TTY de recuperação e um backup

Antes de alterar a autenticação, salve o trabalho, conecte o USB cadastrado e acesse um TTY com **Ctrl + Alt + F3** (ou **Ctrl + Alt + Fn + F3** no notebook documentado). Entre com a senha normal da conta e abra um shell administrativo.

```bash
sudo -i
```

Mantenha esse TTY disponível durante as mudanças. Os comandos históricos das seções 3 a 7 foram executados **no shell de root** e dispensam repetir `sudo`.

```bash
backup_usb=$(mktemp -d /root/usb-token-parte02.XXXXXX)
cp -a /etc/pam.d "$backup_usb/"
cp -a /usr/share/pam-configs/libpam-usb "$backup_usb/"
cp -a /etc/udev/rules.d/80-usb.rules "$backup_usb/"
cp -a /usr/local/bin/usb-lock.sh "$backup_usb/"
cp -a /etc/security/pam_usb.conf "$backup_usb/"
printf 'Backup: %s\n' "$backup_usb"
```

**Confirme que todas as cópias foram concluídas antes de prosseguir.** O mantenedor original registrou um backup em `/root/usb-token-parte02.qz3aVC`. Em outra máquina, use **o caminho real** retornado por `mktemp`. O diretório do exemplo pode não existir. A variável `backup_usb` só existe no shell atual e se perde ao sair ou reiniciar. Os backups contêm configuração de autenticação sensível e devem permanecer privados.

### Verificar o agente e o cadastro USB

Os comandos de diagnóstico registrados foram os seguintes.

```bash
sed -n '30,115p' /etc/security/pam_usb.conf
pgrep -af '[p]amusb-agent'
```

O caminho correto é `/etc/security/pam_usb.conf`. O caminho `/etc/pamusb.conf` é incorreto. As ações de exemplo para bloqueio e desbloqueio do agente `scox`/`MyDevice` estavam dentro de comentários XML. A inspeção registrada não encontrou processos `pamusb-agent` ativos.

A configuração original tinha uma referência duplicada a `SanDisk` para `henrique`. O mantenedor editou o XML para manter apenas uma entrada de dispositivo.

```xml
<user id="henrique">
    <device>SanDisk</device>
</user>
```

**Não** substitua um XML existente por esse trecho isolado. Preserve a configuração ao redor e verifique se há ações ativas do agente em outras instalações. Mantenha privados os pads reais e o conteúdo de arquivos secretos.

## 4. Desativar somente o desbloqueio automático do udev

O procedimento registrado para a máquina cadastrada foi o seguinte.

```bash
sed -i '/^ACTION=="add".*usb-lock\.sh unlock/s/^/# Disabled in Part 02: /' \
  /etc/udev/rules.d/80-usb.rules
udevadm control --reload-rules
cat /etc/udev/rules.d/80-usb.rules
```

O bloco preserva a **estrutura das regras com comentários explicativos em inglês**. Ele não transcreve um novo teste físico.

```udev
# Disabled in Part 02: ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="EXAMPLE_USB_SERIAL", RUN+="/usr/local/bin/usb-lock.sh unlock"
ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="EXAMPLE_USB_SERIAL", RUN+="/usr/local/bin/usb-lock.sh lock"
```

O script continua instalado e aceita `lock` e `unlock`, mas **somente a regra de remoção** permanece ativa. A recarga de regras udev afeta eventos futuros. Evite `udevadm trigger` para gerar eventos USB sintéticos em todo o sistema. Cada pendrive diferente exige **seus próprios identificadores revisados**. Os valores acima pertencem ao registro histórico.

## 5. Remover o perfil USB da autenticação PAM compartilhada

O mantenedor executou os comandos abaixo no shell de root.

```bash
pam-auth-update --disable libpam-usb
cat /etc/pam.d/common-auth
```

Se surgir a interface de seleção, mantenha **Unix authentication** habilitado e **USB Authentication** desabilitado. Evite sobrescrever personalizações locais com `--force` sem antes inspecioná-las.

Depois disso, o bloco ativo observado foi o seguinte.

```text
auth [success=1 default=ignore] pam_unix.so nullok
auth requisite pam_deny.so
auth required pam_permit.so
```

O `common-auth` deve ficar **sem linhas ativas de `pam_usb.so`**. Não substitua um arquivo PAM inteiro por esse trecho. Outras instalações podem ter módulos e comentários diferentes. O Debian gerou a opção `nullok`, que não passou por auditoria separada de política. O `pam_permit.so` aparece após os controles de falha anteriores e não concede acesso isoladamente.

## 6. Exigir USB no GDM

Abra a configuração do serviço PAM do GDM.

```bash
nano /etc/pam.d/gdm-password
```

Insira **uma** linha imediatamente antes de `@include common-auth`.

```text
auth required pam_usb.so
```

O início da configuração original observada tinha o conteúdo abaixo.

```text
#%PAM-1.0
auth requisite pam_nologin.so
auth required pam_succeed_if.so user != root quiet_success
auth required pam_usb.so
@include common-auth
auth optional pam_gnome_keyring.so
@include common-account
```

Preserve todas as outras linhas do PAM, especialmente os módulos de conta, sessão e senha. Verifique o início do arquivo.

```bash
head -n 8 /etc/pam.d/gdm-password
```

### Por que os dois fatores são exigidos

O `pam_usb.so` verifica o USB cadastrado e seus pads. Com o controle `required`, uma falha impede o sucesso da autenticação **como um todo**, mas outros módulos ainda podem ser processados. A solicitação de senha pode aparecer mesmo sem USB.

O `common-auth` verifica a senha via `pam_unix.so`. Uma senha incorreta chega ao `pam_deny.so`. A senha correta **não** anula uma falha anterior do USB.

O requisito se restringe ao serviço `gdm-password` e à conta testados. Outros usuários, login automático, impressão digital, SSH e demais serviços PAM exigem análise separada.

## 7. Testar a autenticação pelo TTY

```bash
apt update
apt install -y pamtester
pamtester gdm-password henrique authenticate
```

O mantenedor original forneceu uma saída de sucesso semelhante à seguinte.

```text
* Authentication request for user "henrique" (gdm-password)
* Searching for "SanDisk" in the hardware database...
* Authentication device "SanDisk" is connected.
* Performing one time pad verification...
* Access granted.
Password:
pamtester: successfully authenticated
```

`Access granted` corresponde à verificação do USB. Somente `pamtester: successfully authenticated` indica sucesso do PAM como um todo. Em `Password:`, digite a senha **da conta de usuário**. A senha de root não se aplica ali. Os caracteres não aparecem na tela.

Os testes cobrem as condições da tabela.

| USB | Senha | Resultado esperado |
| --- | --- | --- |
| Conectado | Correta | Sucesso |
| Conectado | Incorreta | Recusado |
| Ausente | Correta | Recusado |

Os logs de `pamtester` compartilhados originalmente mostraram **dois sucessos** e não continham transcrições dos casos recusados. O usuário original **relatou os logins físicos recusados separadamente**. Uma observação relatada não supre uma transcrição ausente.

Conclua as gravações e desmonte o volume antes de retirar o pendrive. A remoção pode bloquear a sessão gráfica ou apagar a tela. Execute os testes em um TTY para manter a recuperação disponível. Ver a tela bloquear confirma o caminho do udev. Para confirmar que o login sem USB foi recusado, é preciso testar a autenticação.

## 8. Validar no GDM e após reiniciar

Retorne à sessão gráfica **sem fechar o TTY de recuperação de root**. O GDM costuma estar no VT 2, mas pode usar o VT 1.

```bash
chvt 2
```

Trocar de VT **não** desbloqueia uma sessão. Reconectar o USB cadastrado também deve mantê-la bloqueada.

Em **1º de outubro de 2026**, o mantenedor original relatou os resultados abaixo.

| Teste físico | Resultado relatado |
| --- | --- |
| USB ausente e senha correta | Acesso gráfico recusado |
| USB presente e senha incorreta | Acesso recusado |
| USB presente e senha correta | Acesso permitido |
| Remoção do USB durante a sessão | Sessão bloqueada |
| Reconexão do USB | A sessão permaneceu bloqueada |
| Novo login após encerrar a sessão | Os dois requisitos permaneceram ativos |
| Reinicialização e novo login | O comportamento esperado persistiu |

O **usuário original relatou** os testes da Parte 02. Não foram fornecidas capturas adicionais dessa etapa. As imagens da Parte 01 documentam a política **anterior** de USB ou senha. Elas não demonstram o comportamento com USB e senha.

Antes de reiniciar, salve o trabalho e encerre normalmente o shell de root e a sessão TTY. Ao terminar, não deixe uma sessão administrativa aberta sem supervisão.

## 9. Recuperar o acesso sem o pendrive

### Abrir uma sessão TTY separada

1. Pressione **Ctrl + Alt + F3**, ou **Ctrl + Alt + Fn + F3** no notebook documentado.
2. No prompt de login do console, informe o nome da conta cadastrada.
3. Digite a senha normal dessa conta.

Se o atalho falhar, experimente outro TTY disponível, como F4. O TTY **não** desbloqueia a sessão gráfica. Na configuração documentada, o login por TTY dispensa USB. A recuperação pressupõe que o administrador ainda tenha a senha e acesso a `sudo`.

### Suspender temporariamente o requisito USB no GDM

```bash
sudo nano /etc/pam.d/gdm-password
```

Comente **somente** a regra USB obrigatória correspondente.

```text
# auth required pam_usb.so
```

Salve e retorne ao GDM usando o VT correto para a máquina.

```bash
sudo chvt 2
```

Cancele qualquer tentativa anterior e inicie **uma nova**. Ela deve aceitar a senha da conta sem o pendrive desde que nenhuma outra política a rejeite. **Não reinicie o GDM** só para aplicar a alteração. Isso encerraria a sessão gráfica.

A mudança desativa temporariamente o requisito USB **somente no GDM**. O bloqueio udev na remoção e o `common-auth` permanecem como estavam. O projeto prevê TTY e administração por senha para recuperação.

Quando a instalação corresponde às precondições, o [utilitário interativo de recuperação](../scripts/README.pt-BR.md) pode comentar exclusivamente essa regra do GDM após backup e confirmação.

### Reativar a política final

Verifique o USB cadastrado ou substituto e os pads. Retire o comentário de **uma** linha `auth required pam_usb.so` imediatamente antes de `@include common-auth`. Repita os testes positivos e negativos antes de considerar a proteção restaurada. **Não reative** o perfil global obsoleto `libpam-usb` da Parte 01.

### Reversão completa para a configuração *anterior* de USB ou senha

O guia anterior também registrou uma **reversão mais ampla e independente** para o estado salvo antes da Parte 02. Ela reativa o modelo **histórico** de USB ou senha e pode restaurar a regra de desbloqueio automático original. **Não restaura a política final da Parte 02.**

Os comandos abaixo se destinam apenas ao administrador que decidiu retornar à configuração anterior a partir de um TTY de recuperação de root.

```bash
sudo -i
backup_usb=/root/usb-token-parte02.qz3aVC
ls -la "$backup_usb"
```

**Substitua o caminho de backup do exemplo** pelo caminho real que verificou. Compare primeiro seu conteúdo com os arquivos em uso. Uma cópia integral de um backup antigo pode sobrescrever mudanças PAM legítimas posteriores.

```bash
cp -a "$backup_usb/libpam-usb" /usr/share/pam-configs/libpam-usb
pam-auth-update --enable libpam-usb
cp -a "$backup_usb/pam.d/." /etc/pam.d/
cp -a "$backup_usb/pam_usb.conf" /etc/security/pam_usb.conf
cp -a "$backup_usb/80-usb.rules" /etc/udev/rules.d/80-usb.rules
cp -a "$backup_usb/usb-lock.sh" /usr/local/bin/usb-lock.sh
udevadm control --reload-rules
```

Este é um **registro histórico de reversão**. Executá-lo como script automático é desaconselhado. O backup XML pode restaurar a duplicação do dispositivo corrigida na Parte 02. A restauração ampla exige revisão das diferenças e não se destina a máquinas alheias ao registro.

## 10. Diagnóstico e manutenção

| Sintoma | O que inspecionar |
| --- | --- |
| USB autentica sem senha | Confira se a regra `sufficient pam_usb.so` reapareceu no `common-auth` compartilhado |
| Senha correta funciona sem USB no GDM | Verifique se a regra obrigatória está ativa no serviço `gdm-password` efetivo e se algum outro fluxo de login dispensa esse requisito |
| Reconectar o USB desbloqueia a sessão | Inspecione regras de conexão udev e ações do agente. Mantenha `unlock` desabilitado |
| `Pad checking failed!` | Confira identidade do dispositivo, UUID e montagem do volume, integridade do sistema de arquivos e acesso aos pads. Consulte as notas históricas da Parte 01 |
| Remover o USB não bloqueia a sessão | Examine a regra de remoção udev, o script de bloqueio e a detecção da sessão gráfica |
| TTY funciona mas GDM continua bloqueado | São sessões independentes. Faça nova tentativa gráfica ou siga a recuperação documentada |
| GNOME Keyring solicita outra senha | Confira se a senha do chaveiro coincide com a do login. O USB não decifra o chaveiro |

Para diagnosticar o sistema, examine `/etc/pam.d/common-auth`, o início de `/etc/pam.d/gdm-password` e as mensagens recentes do journal.

```bash
cat /etc/pam.d/common-auth
head -n 8 /etc/pam.d/gdm-password
sudo journalctl -b --no-pager -n 100
```

Atualizações de pacotes ou a reinstalação de `pam_usb` podem alterar perfis PAM. Repita as verificações manuais após mudanças importantes de configuração. Nunca publique senhas ou conteúdo dos pads. Remova dados sensíveis dos logs antes de compartilhá-los.

## 11. Limitações de segurança

- Os arquivos de pad contêm segredos. **Não** publique arquivos `.pad` nem compartilhe seu conteúdo.
- A renovação dos pads de `pam_usb` não é um código TOTP nem criptografia do SSD. Consulte o método original da Parte 01.
- Pendrives comuns oferecem menor proteção ao material secreto que tokens de segurança dedicados. Números de série informados pelo USB e UUIDs de sistemas de arquivos, isoladamente, **não provam identidade criptográfica**.
- Desconectar durante gravações pode danificar o FAT. Desmonte o volume com segurança antes de removê-lo.
- O udev solicita o bloqueio de sessão **ao receber o evento**. Não há monitoramento contínuo da ausência do USB.
- A exigência de USB vale para o fluxo GDM testado. TTY e `sudo` continuam aceitando senha para recuperação. Administradores podem mudar as políticas.
- O projeto não cifra o armazenamento nem aplica controles USB à inicialização, ao SSH ou a todos os serviços.

## Ferramentas auxiliares e referências

O [menu e os scripts opcionais](../scripts/README.pt-BR.md) oferecem diagnóstico, backups de configuração, testes guiados e recuperação restrita ao GDM.

```bash
bash scripts/menu.sh
```

Eles não instalam a política inteira. Manter a configuração já validada dispensa executá-los novamente.

Referências do projeto original:

- [pam_usb 0.9.3](https://github.com/mcdope/pam_usb/tree/0.9.3)
- [Código da configuração](https://github.com/mcdope/pam_usb/blob/0.9.3/src/conf.h)
- [Implementação dos pads USB](https://github.com/mcdope/pam_usb/blob/0.9.3/src/pad.c)
- [Sintaxe e controles PAM no Debian](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
- [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
- [pamtester](https://manpages.debian.org/trixie/pamtester/pamtester.1.en.html)
- [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
- [chvt](https://manpages.debian.org/trixie/kbd/chvt.1.en.html)
