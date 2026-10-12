# FAN · Histórias que conectam

Aplicativo Flutter de histórias interativas em formato de conversa, com interface escura, catálogo responsivo e estúdio de criação. O layout usa navegação inferior no celular e menu lateral em telas maiores.

## Fluxos implementados

- **Descobrir:** destaque editorial, categorias clicáveis, busca sem distinção de acentos, classificação indicativa e ordenação por título ou quantidade de episódios.
- **Ler:** mensagens progressivas, escolhas obrigatórias, mensagens condicionais, seleção de episódios, prévia, leitura automática, reinício e ajuste do tamanho do texto.
- **Continuar:** posição por mensagem e respostas são persistidas; leituras em andamento e concluídas aparecem separadamente na biblioteca.
- **Biblioteca:** leituras, salvos, concluídos e curtidos.
- **Estúdio:** criar e editar detalhes e capas, adicionar e editar episódios, reordenar mensagens, configurar escolhas, testar a prévia, publicar e retirar do catálogo. Rascunhos do editor são salvos automaticamente neste dispositivo.
- **Perfil:** nome, biografia, preferências de leitura, saída e limpeza explícita dos dados locais.

### Local ou Firebase

Sem configuração Firebase, o app utiliza um **perfil local sem e-mail nem senha**. Perfil, histórias, episódios, biblioteca, escolhas e rascunhos são armazenados no dispositivo via `shared_preferences`. Sair do perfil preserva o trabalho; apagar dados requer confirmação. Não há sincronização entre dispositivos e limpar o armazenamento do navegador apaga esses dados. Capas enviadas no modo local têm limite de 512 KB; na nuvem, devem ter menos de 5 MB. As quatro histórias de exemplo e nove episódios já estão incluídos.

Com Firebase configurado, o app utiliza Authentication, Firestore e Storage. A interface mostra erros de conexão e não apresenta denúncias locais como se tivessem sido enviadas à moderação. Adicionar episódios na nuvem utiliza uma transação para gravar o episódio e atualizar seu contador juntos.

As condições de mensagens usam o texto de uma resposta anterior (`requires`). Elas são ramificações simples dentro do episódio, não um editor de árvores de narrativa. Prefira textos de respostas distintos entre escolhas diferentes para evitar condições ambíguas.

## Executar

Requisitos: Flutter **3.35+**, Dart **3.9+** e Chrome/Chromium para Web. Use a mesma versão do Flutter na equipe e na CI. O SDK não está incluído no repositório.

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

`./bootstrap.sh` ou `./bootstrap.ps1` executa instalação de pacotes, análise e testes. Esses scripts não usam `flutter create` sobre os fontes existentes.

Para um servidor de desenvolvimento sem interface gráfica:

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Para gerar os arquivos Web incluindo o renderizador local:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --directory build/web
```

O modo local não solicita fontes externas: usa a fonte do sistema. Na nuvem, utilize o checkout já existente em `/workspace/fan`; cada tarefa já possui um ambiente isolado e não precisa de um worktree adicional.

### Android

Requer Java 17, Android SDK 36 e NDK 27.0.12077973. Gradle 8.14.3, AGP 8.10.1 e Kotlin 2.3.0 estão definidos nos arquivos Android. O wrapper Gradle está incluído; o JAR foi conferido com o SHA-256 oficial e a distribuição tem verificação de checksum configurada.

```sh
flutter doctor
flutter devices
flutter run -d <id-do-dispositivo>
flutter build apk --debug
```

Para uma versão de distribuição, forneça `android/key.properties`, ignorado pelo Git, com `storeFile`, `storePassword`, `keyAlias` e `keyPassword`. `storeFile` é relativo a `android/` ou absoluto. O build release usa essa chave quando configurada e não reutiliza a assinatura debug. Nunca versionar chaves e senhas.

## Configurar Firebase

O modo local permite desenvolver sem conta Firebase. Para usar a nuvem, crie um projeto próprio, ative Email/Password em Authentication, Firestore e Storage, e cadastre o app Web/Android.

O arquivo `lib/firebase_options.dart` aceita a configuração pública do cliente por `--dart-define-from-file`. Crie um arquivo local `firebase-client.json` (ignorado pelo Git):

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

Use o App ID correspondente à plataforma: o App ID Web não é o mesmo do Android. Esse arquivo contém configuração pública do SDK cliente; não coloque credenciais Admin, chave privada de conta de serviço ou tokens nele. Alternativamente, use `flutterfire configure --platforms=android,web` para gerar opções por plataforma.

As regras foram atualizadas para permitir posição por mensagem, escolhas e edição de episódios pelo autor. **O projeto Firebase precisa receber as regras atualizadas antes de usar esses novos campos.**

```sh
firebase deploy --project <seu-projeto> --only firestore:rules,firestore:indexes,storage
```

O deploy e a configuração de um projeto real não são executados automaticamente. Para importar histórias iniciais, consulte `firebase/seed/seed.mjs`; ele exige uma conta de serviço externa ao repositório e escreve no projeto selecionado.

## Testes e validação

A suíte contém 19 testes:

- 3 de conteúdo e serialização, já existentes;
- 5 do cursor de leitura: escolha final, ramificações, retomada e respostas antigas;
- 7 de estado local: persistência, edição/publicação, saída, conclusão, validação, rascunhos e denúncias;
- 4 de widgets: navegação em 390px/1440px, perfil local e prévia sem gravação na biblioteca.

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

**Estado da validação nesta máquina:** a sintaxe dos arquivos Dart foi verificada com um parser; os ícones e APIs principais foram conferidos no código oficial do Flutter 3.35.7. Também foram verificados JSONs, sintaxe dos scripts e integridade do wrapper Gradle. A instalação do SDK Flutter permanece bloqueada por HTTP 403 em `storage.googleapis.com`, então a análise de tipos, os 19 testes, builds, execução visual e integração Firebase **ainda não foram executados**. Não considerar essa revisão uma compilação validada.

Para continuar no ambiente na nuvem, aplique a liberação de `storage.googleapis.com` nas configurações do ambiente, instale o SDK e execute os comandos acima. Dependências Dart usam `pub.dev` e `storage.googleapis.com`. O primeiro `flutter pub get` também gera `pubspec.lock`, que deve ser mantido no Git para builds reproduzíveis.

## Estrutura

```text
lib/
  core/                 tema e acesso ao estado
  data/                 catálogo de exemplo e estado/persistência
  models/               entidades e cursor de leitura independente da UI
  ui/pages/             catálogo, leitor, perfil, biblioteca e estúdio
  ui/widgets/           componentes visuais e estados vazios
  firebase_options.dart configuração pública por plataforma/build
  main.dart             inicialização e ciclo de vida do estado
assets/                 capas, identidade e fundo
firebase/               regras, índices e importação opcional
android/                plataforma e wrapper Gradle
web/                    inicialização Web e manifesto
test/                  modelos, leitura, estado e widgets
```

Antes de distribuir com conteúdo público, ainda são necessários moderação administrativa, fluxo de exclusão de conta/dados na nuvem, políticas de privacidade e validação das regras com emuladores/projeto de teste. As regras limitam autoria, campos e tamanho das listas, mas não fazem validação profunda de cada mensagem nem moderação automática.
