# Método 01 — Controle da sessão gráfica com USB

[English](README.md) · [Visão geral do projeto](../README.pt-BR.md)

O número de série do dispositivo aparece como marcador.

Este método histórico explora o bloqueio e a solicitação de desbloqueio de uma sessão gráfica no Debian 13 com `udev`, Bash e `loginctl`.

**Estado registrado.** O teste ocorreu no Debian instalado no SSD físico e incluiu uma reinicialização. O **Método 02 — Parte 02 desativa a regra de conexão que solicitava o desbloqueio automático**. Só o bloqueio na remoção permanece ativo. Mantenha a regra antiga de desbloqueio desabilitada na configuração final de USB e senha.

Isoladamente, o Método 01 controla uma sessão existente. O primeiro login e o desbloqueio manual continuam possíveis com senha, sem exigir USB.

## Ambiente registrado

| Item | Ambiente |
| --- | --- |
| Sistema | Debian GNU/Linux 13 (Trixie) instalado diretamente no SSD |
| Ambiente gráfico e sessão | GNOME, Wayland |
| Gerenciador de login | GDM |
| Conta cadastrada | `henrique` |
| Pendrive | SanDisk Cruzer Blade |
| Identificadores do fabricante e do produto USB | `0781:5567` |
| Número de série informado pelo USB | `EXAMPLE_USB_SERIAL` |

## Comportamento do experimento histórico

| Evento | Comportamento esperado na época |
| --- | --- |
| Remoção do USB cadastrado | Bloquear a sessão gráfica de `henrique` |
| Conexão do USB cadastrado | Solicitar o desbloqueio (comportamento histórico desativado na configuração final) |
| Inicialização sem USB | O login convencional por senha continua disponível |

A regra udev detecta o evento USB e chama um script de propriedade do root. O script localiza a sessão gráfica do usuário e chama `loginctl`. A execução do pedido de bloqueio ou desbloqueio depende do ambiente gráfico. A regra não define sozinha a política de login.

**Comportamento atual.** A regra de desbloqueio na conexão está desativada e a de bloqueio na remoção permanece ativa. O [Método 02 — Parte 02](../method-02/part-02.pt-BR.md) documenta a política de autenticação com USB e senha.

Consulte as [17 capturas históricas](images/) do Método 01. Elas preservam a evidência visual do projeto original e documentam somente os testes relatados na época.
