# Revisão da documentação de 1º de outubro de 2026 (registro histórico)

[English](DOCUMENTATION_REVIEW.md) · [Visão geral do projeto](README.pt-BR.md)

Este registro descreve a documentação original anterior à revisão em inglês do fork. Baseia-se nos arquivos existentes e nos comandos e resultados relatados pelo mantenedor original. É uma **nota histórica**. O fork em inglês não repetiu os testes físicos originais.

## Escopo original

| Documento | Revisão original |
| --- | --- |
| `README.md` | Esclareceu o hardware real com Debian 13, a estrutura do repositório, o estado dos métodos, os limites do GDM e do TTY e a recuperação |
| `method-01/README.md` | Preservou o experimento de bloqueio de sessão e as capturas, distinguindo o desbloqueio automático histórico da configuração final |
| `method-02/part-01.md` | Identificou a política USB ou senha como histórica e explicou o escopo do PAM compartilhado, os pads, cuidados com FAT e UUID e a transição à Parte 02 |
| `method-02/part-02.md` | Documentou a política final de USB e senha, backups, regra PAM exclusiva do GDM, bloqueio na remoção, recuperação por TTY, testes e reversão |

## Limites de precisão da revisão original

- Os logs registraram mudanças em udev, `common-auth` e `gdm-password` e autenticações bem-sucedidas com `pamtester`.
- O usuário original relatou logins recusados, comportamento físico e persistência após reinicialização. A revisão **não inventou** transcrições negativas de `pamtester` ou capturas ausentes.
- A revisão preservou o erro de verificação dos pads como resultado histórico. Ele não comprova que a remoção causou corrupção.
- O desbloqueio automático do Método 01 consta somente no histórico. A Parte 02 o mantém desabilitado.
- Outros usuários, serviços, login automático, impressão digital e SSH ficaram **fora da validação** original.

## Entrega inicial e scripts auxiliares posteriores

A documentação original foi entregue como pacote de arquivos independente, sem modificar diretamente o sistema em operação do projeto original. Os testes físicos de autenticação fazem parte das evidências do mantenedor original.

Posteriormente o projeto acrescentou menu, scripts auxiliares e testes offline. O utilitário de recuperação desativa apenas a regra USB obrigatória do GDM após confirmação e backup. A restauração integral da pilha PAM permanece manual.

A tradução posterior do fork para o inglês atualizou nomes e referências cruzadas. Preservou o desenho de autenticação do método original e **não acrescentou** novas evidências em hardware.
