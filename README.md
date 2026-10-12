# FAN — Histórias que conectam 💜

Projeto Flutter do **FAN**, app de minihistórias interativas apresentadas em formato de conversa, com identidade roxa e capas originais. Esta entrega inclui o **código-fonte**, assets, estrutura Android/Web, integração Firebase, regras de segurança, dados de exemplo e um editor básico de episódios. **Não é um APK pré-compilado.**

> **Estado:** MVP funcional em código, não verificado por compilação neste ambiente (Flutter/Dart SDK não estavam instalados). Não considere pronto para a Play Store antes dos testes, integração de produção e revisão de segurança/moderação descritos abaixo.

## O que está implementado

- Início com destaques, categorias e histórias recomendadas.
- Explorar por título, autor e categoria.
- Detalhes da história, lista de episódios, classificação e autor.
- Leitor estilo chat com mensagens progressivas e respostas de múltipla escolha; avanço entre episódios.
- Conta por e-mail/senha, cadastro, recuperação de senha e logout (**Firebase Authentication**).
- Biblioteca com salvos, curtidos, leitura em andamento; acompanhamento por episódio (**Cloud Firestore**).
- Seguir autores, editar nome e biografia.
- Estúdio de criação: história, capa, sinopse, classificação, episódios, mensagens, opções e publicação.
- Galeria de capas (**Firebase Storage**) e quatro ilustrações locais incluídas.
- Denúncia de histórias gravada em coleção restrita para moderação posterior.
- Prévia offline/sem Firebase com quatro histórias e nove episódios já incluídos, modo marcado como demonstração.
- Android e Web; identidade, splash nativo mínimo, ícones e manifesto PWA.

## Requisitos

- Flutter **3.35 ou superior** (versões dos plugins dependem do SDK), Dart e Android Studio ou VS Code.
- Java 17, Android SDK 36, NDK 27.0.12077973, Android SDK mínimo 24.
- Android com Kotlin 2.3.0, AGP 8.10.1 e Gradle 8.14.3 (versões definidas nos arquivos de plataforma).
- Node.js 20+ (apenas para importar o conteúdo inicial).
- Para Web, Chrome e CLI do Firebase.

## Como abrir no Windows

1. **Extraia** o ZIP e abra a pasta `FAN` no VS Code.
2. No terminal, execute:

   ```powershell
   flutter doctor
   .\bootstrap.ps1
   flutter run -d chrome
   ```

   O `bootstrap.ps1` usa `flutter create` para gerar/completar arquivos de tooling local (como o `gradle-wrapper.jar`, ausente neste ambiente), preservando os fontes existentes por padrão, e executa `flutter pub get`. Caso o Flutter avise que algum arquivo existente seria substituído, **cancele a substituição** e preserve `lib/`, `assets/`, `pubspec.yaml` e as configurações Android. É possível usar `flutter create --platforms=android,web .` manualmente.

3. Para executar no Android, inicie um emulador ou conecte o aparelho com depuração USB e rode `flutter run -d android` (ou escolha um ID listado em `flutter devices`).
4. Sem Firebase configurado, a barra **PRÉVIA LOCAL** aparecerá. Logins e conteúdos escritos serão simulados em memória, e serão perdidos quando o app reiniciar.

## Conectando um projeto Firebase REAL

1. Acesse https://console.firebase.google.com/ e crie um novo projeto (por exemplo `fan-historias`). **Não reutilize as credenciais privadas de outro app.**
2. Ative **Authentication > Sign-in method > Email/Password**, crie o **Firestore Database** e habilite o **Cloud Storage**. Confira a região, a cobrança e o plano aplicável (o Storage pode exigir projeto com faturamento habilitado).
3. No computador, instale as CLIs:

   ```sh
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```

4. Dentro da pasta `FAN`, execute:

   ```sh
   flutterfire configure --platforms=android,web
   flutter pub get
   ```

   Selecione seu projeto Firebase. Esse comando substituirá o **placeholder** `lib/firebase_options.dart` por opções verdadeiras de cada plataforma. `Firebase.initializeApp` em `lib/main.dart` usa essas opções automaticamente. Se o projeto precisar de Google Services nativo adicional, deixe a CLI ajustar a configuração Android.

5. Publique as regras de proteção **antes de distribuir o app**:

   ```sh
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

6. Rode `flutter run -d chrome` ou `flutter run -d android`. A barra de demonstração deixará de aparecer quando a conexão Firebase inicializar corretamente.

### Carregar histórias iniciais no banco

As ilustrações e histórias de demonstração já existem dentro do app. Se desejar popular o banco Firestore com quatro histórias públicas:

```sh
cd firebase/seed
npm install
# Configure GOOGLE_APPLICATION_CREDENTIALS para o caminho EXTERNO da sua conta de serviço.
# Exemplo PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="C:\\local-seguro\\fan-admin.json"
# Exemplo bash: export GOOGLE_APPLICATION_CREDENTIALS="$HOME/segredos/fan-admin.json"
npm run seed
```

O script faz um **upsert** dos documentos `stories/demo_*` e episódios. Credenciais de conta de serviço devem permanecer fora do projeto, do ZIP e do Git. Ele usa Firebase Admin SDK e não deve ser executado em clientes Flutter.

## Estrutura

```text
FAN/
  assets/
    backgrounds/        fundo estrelado
    branding/           ícone original 1024px
    covers/             quatro capas originais WebP
  lib/
    core/               tema e acesso ao estado
    data/               repositório Firebase e conteúdo demo
    models/             Story, Episode, ChatLine, LibraryState
    ui/pages/           Início, Explorar, Estúdio, Leitor, Perfil, etc.
    ui/widgets/         componentes reutilizáveis
    firebase_options.dart  <-- substituído pelo FlutterFire
    main.dart
  android/               configuração Android, ícones, Kotlin
  web/                   página inicial e PWA
  firebase/              Firestore, Storage, importação de exemplo
  bootstrap.ps1/.sh
  pubspec.yaml
  firebase.json
```

### Modelo de dados Firestore

```text
stories/{storyId}
  title, description, category, authorId, authorName,
  coverUrl, coverAsset, contentRating, episodeCount, published,
  createdAt, updatedAt
stories/{storyId}/episodes/{episodeId}
  title, order, lines[{id,speaker,text,choiceId?,options?,requires?}], createdAt
users/{uid}
  displayName, bio, createdAt
users/{uid}/library/{storyId}
  saved, liked, episodeIndex, updatedAt
users/{uid}/following/{authorId}
  createdAt
reports/{reportId}
  storyId, reporterId, reason, status, createdAt
```

### Segurança e decisões de arquitetura

- Leitura de histórias publicadas é pública; rascunhos são visíveis somente ao autor. Histórias e episódios só podem ser criados pelo autor autenticado.
- Biblioteca e seguidores são privados por usuário. Denúncias são gravadas sem leitura pública; o painel de moderação precisa ser desenvolvido com acesso administrativo seguro.
- Capas do Storage: leitura pública, upload apenas pelo titular da pasta, máximo 5 MB e tipo de imagem permitido.
- Escolhas do leitor aparecem como respostas e podem habilitar mensagens condicionais (`requires`). **Não há motor completo de ramificações, sincronização de escolhas nem editor de árvores de decisão**, que são extensões futuras.
- Login demonstrativo e histórias criadas na prévia são **temporários**, não um banco de dados de produção.
- A publicação pública por qualquer usuário autenticado requer uma camada adicional de **moderação preventiva**, classificação, filtro de conteúdo, limites de taxa, validação robusta e políticas de direitos autorais antes de distribuição pública.
- `episodeCount` é um contador informado pelo cliente; antes de produção, migre a publicação/contagem para uma Cloud Function ou transação validada pelo servidor. A aplicação também não oferece exclusão de conta/dados, denúncia com bloqueio automático ou fluxo de revisão por administradores.
- Fontes Google são solicitadas pelo `google_fonts` quando necessárias; para uso 100% offline, inclua os arquivos licenciados adequados e configure fontes locais.

## Como gerar versão de teste

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build apk --debug
flutter build web --release
```

Para Play Store, **não use a assinatura debug** declarada temporariamente no `android/app/build.gradle.kts`. Configure sua própria chave de assinatura e gere um AAB. Antes de publicar, prepare política de privacidade, Termos de Uso, exclusão de conta, conformidade LGPD, medidas para conteúdo gerado por usuários, revisão de denúncias, classificação indicativa e testes de diferentes tamanhos de tela.

## Identidade visual

- Nome: **FAN**
- Slogan: *Histórias que conectam.*
- Fundo: `#0E0B18`; roxo: `#9B5CF7`; lilás: `#D78BFA`; rosa: `#FFA1DE`.
- As quatro capas e o símbolo orbital incluídos em `assets/` foram produzidos exclusivamente para esta proposta.

**Licença:** código disponibilizado como protótipo para personalização e uso do proprietário. Avalie licenças de dependências antes da distribuição.
