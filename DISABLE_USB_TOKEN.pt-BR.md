# Desativar temporariamente a autenticação USB preservando a configuração

[English](DISABLE_USB_TOKEN.md) · [Visão geral do projeto](README.pt-BR.md)

Este guia cobre os dois mecanismos do **Linux USB Security Token** no ambiente Debian 13, GNOME e GDM registrado. Uma regra bloqueia a sessão gráfica ao remover o USB, e o **GDM** exige `pam_usb.so` somente no seu próprio fluxo. O procedimento mantém os arquivos para que o administrador possa restaurar a configuração anterior.

> **Importante.** Leia o [Método 02 — Parte 02](method-02/part-02.pt-BR.md) e confirme que tem acesso a um TTY, uma senha que funcione e um **backup verificado** antes de alterar o PAM. Os procedimentos administrativos correspondem à máquina documentada e não foram validados em todas as configurações PAM. A restauração da Parte 02 deve manter desativado o *perfil de autenticação USB global* da Parte 01.

## 1. Acessar um TTY e copiar a configuração

Pressione **Ctrl + Alt + F3** (no IdeaPad documentado, pode ser necessário **Ctrl + Alt + Fn + F3**), entre com a senha da conta e mantenha essa sessão de recuperação aberta. Antes de alterar a configuração, crie uma cópia privada.

```bash
sudo -i
backup_dir=$(mktemp -d /root/usb-token-disabled.XXXXXX)
cp -a /etc/pam.d "$backup_dir/"
cp -a /etc/security/pam_usb.conf "$backup_dir/" 2>/dev/null || true
cp -a /etc/udev/rules.d/80-usb.rules "$backup_dir/" 2>/dev/null || true
cp -a /usr/share/pam-configs/libpam-usb "$backup_dir/" 2>/dev/null || true
cp -a /usr/local/bin/usb-lock.sh "$backup_dir/" 2>/dev/null || true
printf 'Backup: %s\n' "$backup_dir"
```

Confira as cópias e guarde o caminho gerado. Itens opcionais podem faltar. **A ausência da cópia obrigatória do PAM indica falha**. Os backups podem conter configuração sensível. Mantenha-os privados e fora do Git.

## 2. Desativar a exigência de USB no GDM (Método 02)

Em `/etc/pam.d/gdm-password`, localize a **única** linha ativa indicada abaixo.

```text
auth required pam_usb.so
```

Comente apenas essa linha.

```text
# auth required pam_usb.so
```

Use `nano /etc/pam.d/gdm-password` no shell de root (ou `sudo nano` fora dele). Salve com Ctrl + O, Enter, Ctrl + X. Preserve as demais linhas do PAM. Uma nova tentativa gráfica deve aceitar a senha sem USB **desde que nenhuma outra política exija o dispositivo**. A alteração dispensa reinicialização do GDM.

**Não execute `pam-auth-update --enable libpam-usb` indiscriminadamente** ao restaurar o método. A configuração final mantém o perfil global histórico desabilitado e exige USB somente em `gdm-password`.

## 3. Desativar o bloqueio por remoção do USB (Método 01)

Inspecione a regra local antes de editar.

```bash
nano /etc/udev/rules.d/80-usb.rules
```

Localize **a regra específica** `ACTION=="remove"` que chama `/usr/local/bin/usb-lock.sh lock`. Comente essa linha e preserve o restante do arquivo. Exemplo ilustrativo abaixo.

```udev
# ACTION=="remove", ... RUN+="/usr/local/bin/usb-lock.sh lock"
```

As reticências `...` são **ilustrativas e não formam uma regra udev executável**. Preserve os atributos reais do dispositivo e toda a linha depois de `#`. Mantenha as regras alheias e recarregue as regras modificadas.

```bash
udevadm control --reload-rules
```

A alteração impede novos pedidos de bloqueio em eventos **futuros** de remoção. Uma sessão já bloqueada continua bloqueada e uma falha de autenticação PAM anterior continua registrada. A regra histórica `unlock` do Método 01 já deve estar desabilitada ao final da Parte 02. Mantenha o desbloqueio automático desativado.

## 4. Conferir a configuração resultante

```bash
grep -n 'pam_usb.so' /etc/pam.d/gdm-password || true
grep -n 'usb-lock.sh' /etc/udev/rules.d/80-usb.rules || true
```

As linhas pertinentes de `pam_usb.so` e `usb-lock.sh lock` devem ser **comentários**. Leia por inteiro cada linha encontrada. Esses comandos não verificam se outros serviços ou regras ainda exigem USB.

Retorne ao GDM usando o VT adequado para a máquina (muitas vezes VT 2, às vezes VT 1). No shell de root, `chvt 2` permite alternar para o VT 2. Inicie uma **nova** tentativa de login ou desbloqueio gráfico com a senha e sem USB. Preserve acesso ao TTY até confirmar o resultado.

## 5. Reativar a política final de USB e senha

Restaure **apenas** a linha do GDM desativada anteriormente, mantendo uma única linha ativa `auth required pam_usb.so` imediatamente antes de `@include common-auth`. Se desejar, restaure a linha de bloqueio por remoção do `udev` que estava ativa e recarregue as regras.

```bash
udevadm control --reload-rules
```

Reativar a exigência de USB sem verificar o funcionamento do token cadastrado pode impedir o login. Repita os testes positivos e negativos do [Método 02 — Parte 02](method-02/part-02.pt-BR.md) e confira que o TTY ainda aceita a senha. **Não habilite** o perfil global obsoleto `libpam-usb` da Parte 01. Ele configuraria outra política de autenticação.

## 6. Escopo e observações de recuperação

- O requisito do GDM e a regra udev que bloqueia a sessão são **independentes**. Desativar um preserva o outro.
- As alterações desativam regras específicas. Preservam a instalação do `pam_usb`, os pads e os dados do dispositivo cadastrado.
- O [script interativo de recuperação](scripts/README.pt-BR.md) pode comentar somente a regra USB do GDM após confirmação e backup. A regra udev de remoção e a restauração completa ficam fora desse procedimento.
- Se a configuração for diferente da registrada no Método 02 — Parte 02, pare e examine a pilha PAM antes de prosseguir. A aplicação de métodos históricos a um sistema em uso exige revisão.
