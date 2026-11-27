# Diretrizes de contribuição para este fork

[English](CONTRIBUTING.md) · [Visão geral do projeto](README.pt-BR.md)

O fork preserva a arquitetura educacional original com GNOME/GDM, PAM com pam_usb, bloqueio de sessão pelo udev e scripts Bash e Python. O código não foi copiado de outro projeto de segurança USB nem depende de um projeto desse tipo.

## Política de idiomas

- Use **inglês** em código-fonte, identificadores, comentários, nomes de arquivos, mensagens de terminal, testes, README principal, guias técnicos de referência e commits.
- **Títulos e descrições de pull requests podem ser escritos em português brasileiro** para facilitar a revisão humana.
- Instruções a assistentes de IA podem ser escritas em português. Aplique a política de idiomas ao código e à documentação produzidos.
- Mantenha as traduções em português brasileiro alinhadas às referências técnicas em inglês.
- Preserve os nomes fixos das interfaces Linux, como `gdm-password`, `pam_usb.so`, `common-auth` e `/etc/udev/rules.d/80-usb.rules`.

## Segurança e validação

Mudanças na autenticação podem bloquear usuários. Para validar uma contribuição, evite alterar a pilha PAM em uso ou bloquear uma sessão real. Prefira testes reproduzíveis com arquivos temporários, verificação de sintaxe Bash e inspeção somente leitura. Os scripts de recuperação exigem deliberadamente terminal interativo real e confirmação explícita.

Antes de abrir um PR, execute o comando abaixo.

```bash
python3 -m unittest discover -s tests -v
```

Os testes offline não comprovam o comportamento do USB em hardware físico. Novos testes reais exigem acesso de recuperação independente por TTY ou console, backups e autorização humana explícita.

Mantenha contribuições ao projeto original focadas. Apresente grandes alterações de estilo específicas do fork separadamente das correções pontuais destinadas ao mantenedor original.
