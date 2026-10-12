# FAN 2.0 integrado

Base: `FAN_v2_chat_capitulos_flutter_firebase.zip`.

- Histórias em chat e capítulos reais, com `StoryFormat` e `FanChapter` integrados em todo o app.
- Layout responsivo, catálogo por formato, apresentação inicial e navegação por tipo de conteúdo.
- Chat com digitação animada, reprodução automática, pausa, aceleração e persistência das escolhas.
- Livros com temas, fonte persistente, posição de rolagem e progresso separado da contagem de capítulos concluídos.
- Perfil e conteúdo locais persistentes; login fictício com senha foi substituído por perfil local explícito.
- Edição de histórias, episódios e capítulos; prévias, rascunhos automáticos, publicação e retirada do catálogo.
- Transações de adição de episódios/capítulos e regras Firestore para os dois formatos e edição pelo autor.
- Dependências fixadas por lockfile; SDK e preparação da nuvem documentados em `tooling/`.
- Validação: análise sem problemas, 33 testes Flutter, 8 testes de regras no emulador e build Web.

Histórias antigas sem `format` continuam como chat. Atualize o projeto inteiro e publique as regras antes de usar os novos campos com Firebase. Android e Firebase real ainda exigem validação no seu ambiente.
