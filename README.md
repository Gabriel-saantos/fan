# FAN 2.0 · Chat e capítulos

Nova base integrada a partir de **FAN_v2_chat_capitulos_flutter_firebase.zip**. O app mantém os dois formatos do ZIP — conversas interativas e livros com capítulos reais — e acrescenta interface responsiva, persistência local, edição, prévias e testes automatizados.

## O que está integrado

- **Início:** seções separadas para chats e livros, categorias clicáveis e retomada da leitura.
- **Explorar:** busca por título/autor/assunto sem distinção de acentos, filtros por formato/categoria/classificação e ordenação.
- **Chat:** reprodução automática, indicador animado de digitação, botão para revelar imediatamente, pausa, respostas obrigatórias e mensagens condicionais. Posição por mensagem e escolhas são persistidas.
- **Livros:** capítulos nativos (`FanChapter`) com parágrafos, temas claro/escuro/sépia, fonte ajustável e posição de rolagem. Os capítulos usam a coleção `chapters`, não uma conversão de conversas em texto.
- **Biblioteca:** lendo, salvos, concluídos e curtidos; cada formato abre seu leitor correto.
- **Estúdio:** escolher formato, criar/editar detalhes e capas, criar/editar episódios ou capítulos, reordenar mensagens, configurar condições, visualizar a prévia, publicar e retirar do catálogo. Rascunhos de ambos os editores são salvos automaticamente.
- **Perfil:** nome, biografia, preferências persistentes, apresentação inicial novamente, saída e limpeza confirmada dos dados locais.
- **Primeira abertura:** apresentação em três etapas, adaptada também a telas pequenas e com opção de pular.
- **Android/Web:** configuração de plataforma e wrapper Gradle verificado por checksum. Layout com menu lateral em telas maiores e navegação inferior no celular.

As fontes Sora, Roboto, símbolos e emojis estão incluídas localmente, com suas licenças. O Web não depende do download de fontes externas.

A referência visual recebida está preservada em `design/mockup_referencia_do_usuario.png`.

## Abrir o projeto completo

Baixe a branch **`codex/fan-v2`** inteira e abra a pasta que contém `pubspec.yaml`. Evite misturar arquivos isolados da versão anterior: `StoryFormat`, `FanChapter`, os leitores e o estado foram integrados juntos.

Requisitos básicos: **Flutter 3.35.7**, Dart 3.9.2 (incluído nesse SDK) e Chrome/Chromium. O projeto aceita Flutter 3.35+, mas os testes e o lockfile desta entrega usam 3.35.7.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=2
flutter run -d chrome
```

`./bootstrap.sh` e `./bootstrap.ps1` executam instalação, análise e testes. Não usam `flutter create` sobre os fontes existentes. O `pubspec.lock` está versionado para reproduzir as dependências validadas.

Build Web com renderizador incluído nos próprios arquivos:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --directory build/web
```

Para desenvolvimento sem interface gráfica:

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

### Ambiente Codex na nuvem

Use o checkout existente `/workspace/fan`; cada tarefa já tem um ambiente isolado e não precisa de um worktree adicional.

```sh
bash tooling/setup-cloud.sh
source tooling/env.sh
flutter analyze
flutter test --concurrency=2
```

O setup instala Flutter 3.35.7 do servidor oficial com verificação SHA-256, ativa caches graváveis dentro de `/workspace`, instala pacotes Dart com lockfile e instala as dependências dos testes Firebase via `npm ci`. O script foi executado nesta máquina. `tooling/env.sh` registra as variáveis necessárias para próximas sessões, sem alterar `HOME`.

## Modo local

Sem Firebase configurado, o app utiliza um **perfil local sem e-mail nem senha**. Perfil, favoritos, progresso, respostas, histórias, episódios, capítulos, capas e rascunhos são mantidos neste dispositivo via `shared_preferences`.

Sair do perfil preserva o trabalho. A opção de apagar dados exige confirmação. Limpar o armazenamento do navegador remove esses dados; não existe sincronização entre dispositivos no modo local. Capas locais têm limite de 512 KB; na nuvem, devem ter menos de 5 MB. Há duas histórias de chat e dois livros de exemplo, com cinco episódios de chat e quatro capítulos de livro.

## Conectar Firebase

Crie um projeto próprio, registre os apps Web/Android e ative Authentication por Email/Password, Firestore e Storage. A conexão real não foi executada nesta entrega; a validação de permissões usa apenas um emulador local.

O arquivo `lib/firebase_options.dart` aceita opções públicas por `--dart-define-from-file`. Crie um arquivo local `firebase-client.json`, ignorado pelo Git:

```json
{
  "FIREBASE_API_KEY": "chave-publica-do-app",
  "FIREBASE_APP_ID": "id-do-app-da-plataforma",
  "FIREBASE_PROJECT_ID": "seu-projeto",
  "FIREBASE_MESSAGING_SENDER_ID": "numero-do-projeto",
  "FIREBASE_AUTH_DOMAIN": "seu-projeto.firebaseapp.com",
  "FIREBASE_STORAGE_BUCKET": "bucket-do-seu-projeto"
}
```

```sh
flutter run -d chrome --dart-define-from-file=firebase-client.json
flutter build web --release --no-web-resources-cdn --dart-define-from-file=firebase-client.json
```

Use o App ID correspondente à plataforma. O App ID Web difere do Android. Esse arquivo contém configuração pública do SDK cliente, não credenciais Admin. Alternativamente, `flutterfire configure --platforms=android,web` gera opções por plataforma.

**Publique as regras atualizadas antes de sincronizar os novos campos e editar conteúdo na nuvem.** Confirme seu projeto de destino:

```sh
firebase deploy --project <seu-projeto> --only firestore:rules,firestore:indexes,storage
```

### Dados e compatibilidade

```text
stories/{storyId}
  format: "chat" | "chapter"
  title, description, category, authorId, authorName
  coverAsset, coverUrl, contentRating, episodeCount, published

stories/{storyId}/episodes/{episodeId}
  title, order, lines[{id, speaker, text, choiceId?, options?, requires?}]

stories/{storyId}/chapters/{chapterId}
  title, order, paragraphs[]

users/{uid}/library/{storyId}
  saved, liked, started, completed, episodeIndex
  currentEpisodeId, visibleCount, answers
  chapterIndex, chapterProgress, updatedAt
```

Histórias antigas sem `format` continuam como chat. O formato fica fixo após criar a história. `episodeCount` conta episódios ou capítulos, de acordo com o formato. Adições na nuvem usam transações para gravar a seção e seu contador juntos. A posição atual do capítulo fica separada da contagem de partes concluídas. O progresso antigo com `chapterProgress` e `episodeIndex` é interpretado pelo novo modelo.

Condições de mensagens usam o texto de uma resposta anterior (`requires`). São ramificações simples dentro do episódio; prefira opções distintas entre perguntas diferentes para evitar condições ambíguas.

O importador opcional `firebase/seed/seed.mjs` inclui os dois formatos. Ele faz upsert e não remove conteúdo antigo. Exige credenciais Admin fora do repositório ou um emulador e não é executado automaticamente.

## Validação

- **33 testes Flutter:** modelos, formatos, cursor de chat, escolhas, persistência, edição/publicação, capítulos nativos, apresentação inicial, layouts de 390px/1440px, pausa/digitação e editor.
- **8 testes Firestore:** leitura pública/privada, autoria, transação de capítulo, separação dos formatos, edição, retirada de publicação, privacidade/progresso e histórias legadas.
- `flutter analyze`: sem problemas.
- `flutter build web --release --no-web-resources-cdn`: compilação concluída.
- Chromium: apresentação, início, filtro de livros e abertura de capítulos verificados em 1440px e 390px, sem erros de console. Capturas reais em `design/screenshots/`.

Para repetir os testes de regras, use Node.js 22+ e Java 21+:

```sh
npm ci --prefix firebase/tests --include=dev
cd firebase/tests
npm test
```

Esses testes usam o projeto fictício `demo-fan` e o emulador Firestore na porta 8085; não acessam banco de produção. Mensagens de `PERMISSION_DENIED` aparecem nos casos que verificam rejeições esperadas.

## Android

Requer Java 17+, Android SDK 36 e NDK 27.0.12077973. Gradle 8.14.3, AGP 8.10.1 e Kotlin 2.3.0 estão definidos na plataforma.

```sh
flutter doctor
flutter devices
flutter run -d <id-do-dispositivo>
flutter build apk --debug
```

O wrapper Gradle está incluído, com JAR verificado e checksum da distribuição configurado. Para distribuição, forneça `android/key.properties` com `storeFile`, `storePassword`, `keyAlias` e `keyPassword`. Esse arquivo e as chaves são ignorados pelo Git. A configuração release não reutiliza a assinatura debug.

**Build Android e integração com Firebase real ainda não foram executados.** Esta entrega contém código-fonte; não um APK validado.

## Antes de distribuir conteúdo público

Ainda são necessários moderação administrativa, fluxo de exclusão de conta/dados na nuvem e documentos de privacidade. As regras controlam autoria, formatos, campos e limites das listas, mas não substituem moderação nem validação profunda de cada mensagem/parágrafo no servidor.
