# Método 02 — Parte 01: USB ou senha com pam_usb

[English](part-01.md) · [Visão geral do projeto](../README.pt-BR.md)

> **Configuração histórica.** O experimento foi validado e posteriormente substituído pela [Parte 02 — USB **e** senha](part-02.pt-BR.md). Mantenha o perfil USB global desta etapa desabilitado na configuração final.

## Ambiente e evidências

O projeto começou em uma VM Debian e depois foi testado no Debian 13 instalado diretamente no SSD de um Lenovo IdeaPad 3i. Nesta etapa, o pendrive podia substituir a senha convencional.

As [oito capturas históricas](images/) permanecem na localização relativa original. A revisão documental não produziu novas capturas nem repetiu os testes desta etapa.

## Objetivo e resultado esperado

A posse do pendrive configurado era uma forma de autenticação e a senha normal da conta continuava disponível como alternativa.

- **USB conectado** — autenticar sem digitar a senha.
- **USB ausente** — autenticar normalmente com a senha.

O USB **era opcional** nesta etapa. A [Parte 02](part-02.pt-BR.md) passa a exigir **tanto o USB quanto a senha** no fluxo GDM testado.
