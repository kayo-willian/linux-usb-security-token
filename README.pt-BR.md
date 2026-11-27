# Linux USB Security Token

[English](README.md)

Os exemplos usam marcadores para o número de série do dispositivo e o UUID do volume.

Projeto educacional sobre o uso de um pendrive comum para controle de sessões e autenticação no Linux.

**Origem do fork.** Este repositório padroniza os idiomas do projeto [rique-decoder/linux-usb-security-token](https://github.com/rique-decoder/linux-usb-security-token). O projeto original recebe os créditos pela arquitetura GDM/PAM/udev e pela validação em hardware. A tradução e a renomeação dos utilitários preservam essa arquitetura.

**Estado registrado.** O mantenedor original validou o Método 02 — Parte 02 no Debian 13 instalado em um Lenovo IdeaPad 3i, inclusive após reiniciar. O GDM exige o pendrive e a senha. Retirar o pendrive bloqueia a sessão gráfica. Reconectá-lo mantém a sessão bloqueada.

## Documentação e ordem das etapas

| Etapa | Objetivo | Estado |
| --- | --- | --- |
| [Método 1](method-01/README.pt-BR.md) | Solicitar bloqueio e desbloqueio por eventos USB com udev e loginctl | Experimento validado. Na configuração final, apenas o bloqueio na remoção permanece ativo |
| [Método 02 — Parte 01](method-02/part-01.pt-BR.md) | Autenticar com USB **ou** senha usando pam_usb | Validado. A Parte 02 substituiu essa política |
| [Método 02 — Parte 02](method-02/part-02.pt-BR.md) | Exigir USB **e** senha no GDM e preservar a recuperação por TTY | Validado no notebook, inclusive em testes físicos e após reinicialização |

Os documentos anteriores preservam o histórico. Não reaplique as regras de desbloqueio do Método 1 nem o perfil USB global da Parte 01 sobre a configuração final.

## Ambiente

| Item | Ambiente registrado |
| --- | --- |
| Notebook | Lenovo IdeaPad 3i |
| Sistema principal | Debian GNU/Linux 13 (trixie), instalado diretamente no SSD |
| Ambiente gráfico e login | GNOME / GDM. O Método 1 registrou uma sessão Wayland |
| Usuário cadastrado | `henrique` |
| Pendrive | SanDisk Cruzer Blade de 4 GB nominais. O sistema informou 3,7 GB |
| Identificadores USB | `0781:5567`, número de série `EXAMPLE_USB_SERIAL` |
| Volume USB | FAT, UUID `EXAMPLE_VOLUME_UUID` |
| Autenticação USB | pam_usb 0.9.3 |

O projeto começou em uma VM Debian no VirtualBox. Os guias do Método 1 e da Parte 01 também registram testes posteriores. A Parte 02 foi aplicada ao sistema principal. Ao reproduzir etapas, observe o ambiente de cada registro. O pendrive apareceu como `/dev/sda1` naquela ocasião. O caminho pode mudar.

## Comportamento final

| Ação | Resultado validado ou configurado |
| --- | --- |
| Login e desbloqueio gráficos pelo GDM | Exigem o USB cadastrado e a senha correta |
| Senha correta sem o USB | Autenticação gráfica recusada |
| USB presente com senha incorreta | Autenticação gráfica recusada |
| Remoção do USB durante a sessão | A regra udev solicita o bloqueio da sessão ao GNOME |
| Reconexão do USB | A sessão permanece bloqueada e exige autenticação manual |
| Login em terminal TTY | Exige apenas senha, mesmo sem o USB |
| Administração por sudo | Segue a política de senha do sistema. A configuração dispensa o USB |
| Reinicialização | A configuração persistiu nos testes confirmados pelo usuário |

O requisito USB foi inserido em `/etc/pam.d/gdm-password`, logo antes de `@include common-auth`. O perfil `libpam-usb` foi desabilitado em `pam-auth-update`, retirando o USB da autenticação compartilhada. Os serviços PAM de TTY e sudo foram preservados.

## Função de cada mecanismo

- **udev + Bash + loginctl** detectam a remoção e solicitam o bloqueio de uma sessão existente. A autenticação do usuário ocorre separadamente.
- **PAM + pam_usb + pam_unix** validam o pendrive e a senha no serviço `gdm-password`.
- **TTY + sudo** permitem recuperar o acesso administrativo e desabilitar temporariamente o requisito USB no GDM.

O script do Método 1 ainda aceita `unlock`. Nenhuma regra de conexão ativa o chama na configuração final. A inspeção também não encontrou instâncias de `pamusb-agent` em execução.

## Escopo e limitações

O pendrive funciona como fator de posse e a senha como fator de conhecimento. Um dispositivo comum de armazenamento tem garantias de proteção de chaves inferiores às de um token FIDO2/U2F. Os pads são arquivos secretos verificáveis. A identificação também depende de propriedades informadas pelo dispositivo.

A configuração protege o fluxo de login gráfico testado. O SSD, a inicialização e os demais serviços estão fora desse escopo. O projeto permite deliberadamente a recuperação por TTY por quem tem a senha e privilégios de sudo.

A etapa não validou outros usuários, login automático, impressão digital, SSH ou outros serviços PAM. Alterar `gdm-password` pode afetar outros usuários desse serviço. O guia cobre a conta cadastrada `henrique`.

Retire o pendrive depois de concluir as gravações e desmontar o volume. O `pam_usb` pode renovar os pads durante a autenticação e depende da integridade do sistema de arquivos.

## Recuperação rápida

Acesse um TTY com **Ctrl + Alt + F3** (o IdeaPad pode exigir **Ctrl + Alt + Fn + F3**), entre como `henrique` e execute o comando abaixo.

```bash
sudo nano /etc/pam.d/gdm-password
```

Comente somente a linha indicada.

```text
# auth required pam_usb.so
```

Salve o arquivo, volte à interface gráfica e inicie uma nova autenticação. O GDM voltará a aceitar a senha sem o pendrive. A alteração dispensa reiniciar o GDM. O [guia da Parte 02](method-02/part-02.pt-BR.md#9-recuperar-o-acesso-sem-o-pendrive) detalha a recuperação e a restauração do backup. Consulte também a [desativação temporária dos dois mecanismos USB](DISABLE_USB_TOKEN.pt-BR.md).

## Estrutura do projeto

* [README](README.pt-BR.md) — visão geral e estado final.
* [Método 01](method-01/README.pt-BR.md) — histórico do controle de sessões.
* [Imagens do Método 1](method-01/images/) — capturas existentes.
* [Método 02, Parte 01](method-02/part-01.pt-BR.md) — histórico da política USB ou senha.
* [Método 02, Parte 02](method-02/part-02.pt-BR.md) — implementação de USB e senha e recuperação.
* [Imagens da Parte 01](method-02/images/) — capturas existentes.
* [Revisão da documentação](DOCUMENTATION_REVIEW.pt-BR.md) — registro histórico.
* [Desativação temporária](DISABLE_USB_TOKEN.pt-BR.md) — desativação reversível da autenticação USB e do bloqueio de sessão.
* [Licença](LICENSE) — licença original do repositório.

## Ferramentas interativas

Os [scripts auxiliares](scripts/README.pt-BR.md) oferecem diagnóstico, backup, testes guiados e recuperação. Abra o menu a partir da raiz do repositório.

```bash
bash scripts/menu.sh
```

O menu solicita `sudo` nas opções administrativas. A recuperação pede confirmação e cria um backup antes de comentar a regra USB do GDM. Os guias documentam as regras udev e o script de bloqueio. Os utilitários não instalam o método automaticamente.

O diretório `scripts/` contém as ferramentas. Os testes em `tests/` usam arquivos temporários e preservam a configuração PAM do sistema.

## Referências técnicas

* [Versão utilizada do pam_usb](https://github.com/mcdope/pam_usb/tree/0.9.3)
* [Sintaxe e controles do PAM no Debian 13](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
* [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
* [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
* [udev](https://manpages.debian.org/trixie/udev/udev.7.en.html)

O usuário realizou e confirmou os testes de autenticação e reinicialização no notebook. A revisão da documentação não realizou alterações remotas na máquina.

## Idiomas deste fork

O inglês é a referência para código, nomes de arquivos, saídas das ferramentas e documentação técnica. Os guias também estão disponíveis em português brasileiro. O Git preserva os documentos históricos originais. Títulos e descrições de pull requests podem ser escritos em português brasileiro para facilitar a revisão pelo mantenedor.

Os arquivos auxiliares podem ser renomeados, mas interfaces do Linux como `gdm-password`, `pam_usb.so`, `/etc/pam.d/common-auth` e `/etc/udev/rules.d/80-usb.rules` mantêm seus nomes reais. A arquitetura educacional de GDM e TTY continua a mesma.
