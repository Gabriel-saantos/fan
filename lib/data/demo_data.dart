import '../models/fan_models.dart';

const demoStories = <FanStory>[
  FanStory(
    id: 'demo_entre',
    title: 'Entre Mensagens',
    category: 'Romance',
    description:
        'Dois desconhecidos entram no mesmo grupo por engano. Uma conversa comum vira o começo de algo extraordinário.',
    authorId: 'fan_demo',
    authorName: 'Luna Stories',
    coverAsset: 'assets/covers/entre_mensagens.webp',
    episodeCount: 3,
    isDemo: true,
    contentRating: '12+',
  ),
  FanStory(
    id: 'demo_universos',
    title: 'Universos Paralelos',
    category: 'Fantasia',
    description:
        'Uma mensagem de um número impossível conecta duas pessoas em universos diferentes.',
    authorId: 'fan_demo',
    authorName: 'Nebula',
    coverAsset: 'assets/covers/universos_paralelos.webp',
    episodeCount: 2,
    format: StoryFormat.chapter,
    isDemo: true,
    contentRating: 'Livre',
  ),
  FanStory(
    id: 'demo_meianoite',
    title: 'Depois da Meia-Noite',
    category: 'Mistério',
    description:
        'Toda madrugada a mesma pessoa manda uma mensagem. O problema é que ela desapareceu há cinco anos.',
    authorId: 'fan_demo',
    authorName: 'Estrela Sombria',
    coverAsset: 'assets/covers/depois_da_meia_noite.webp',
    episodeCount: 2,
    isDemo: true,
    contentRating: '14+',
  ),
  FanStory(
    id: 'demo_cartas',
    title: 'Cartas que Ficaram',
    category: 'Drama',
    description:
        'Uma carta esquecida em um trem aproxima duas vidas que estavam prestes a seguir caminhos diferentes.',
    authorId: 'fan_demo',
    authorName: 'Sol de Papel',
    coverAsset: 'assets/covers/cartas_que_ficaram.webp',
    episodeCount: 2,
    format: StoryFormat.chapter,
    isDemo: true,
    contentRating: 'Livre',
  ),
];

ChatLine _l(
  int n,
  String who,
  String text, {
  String? choiceId,
  List<String> options = const [],
  String? requires,
}) => ChatLine(
  id: 'm$n',
  speaker: who,
  text: text,
  choiceId: choiceId,
  options: options,
  requires: requires,
);

final Map<String, List<FanEpisode>> demoEpisodes = {
  'demo_entre': [
    FanEpisode(
      id: 'e1',
      title: 'O grupo errado',
      order: 0,
      lines: [
        _l(1, 'Lívia', 'Gente... alguém sabe por que fui adicionada aqui? 😅'),
        _l(2, 'Kael', 'Eu ia perguntar exatamente a mesma coisa.'),
        _l(
          3,
          'Lívia',
          'Talvez o universo esteja tentando nos dizer alguma coisa.',
        ),
        _l(4, 'Kael', 'Ou alguém errou dois números de telefone kkk'),
        _l(5, 'Lívia', 'Você sempre estraga o clima assim?'),
        _l(6, 'Kael', 'Só quando estou nervoso.'),
        _l(
          7,
          'Lívia',
          'Nervoso? Por minha causa?',
          choiceId: 'resposta1',
          options: ['Talvez um pouquinho 😳', 'Imagina, nem te conheço!'],
        ),
        _l(8, 'Kael', 'Pelo menos agora já temos uma história para contar.'),
        _l(9, 'Lívia', 'Então me conta uma coisa: qual é o seu maior segredo?'),
      ],
    ),
    FanEpisode(
      id: 'e2',
      title: 'Três pontos',
      order: 1,
      lines: [
        _l(1, 'Kael', 'Meu segredo é que eu volto a ler suas mensagens.'),
        _l(2, 'Lívia', 'Todas?'),
        _l(
          3,
          'Kael',
          'Principalmente as que têm três pontinhos antes de chegar.',
        ),
        _l(4, 'Lívia', 'Você não faz ideia do sorriso que isso me deu.'),
        _l(5, 'Kael', 'E você não faz ideia do meu.'),
        _l(6, 'Lívia', 'A gente devia se encontrar algum dia...'),
      ],
    ),
    FanEpisode(
      id: 'e3',
      title: 'Uma conversa de verdade',
      order: 2,
      lines: [
        _l(1, 'Kael', 'Estou na cafeteria da praça. Você viria?'),
        _l(2, 'Lívia', 'Acho que já estou na porta.'),
        _l(3, 'Kael', 'É você com um livro roxo?'),
        _l(
          4,
          'Lívia',
          'Depende... você é o menino com o sorriso mais nervoso do lugar?',
        ),
        _l(5, 'Kael', 'Culpado.'),
      ],
    ),
  ],
  'demo_universos': [
    FanEpisode(
      id: 'e1',
      title: 'Sinal impossível',
      order: 0,
      lines: [
        _l(1, 'Noah', 'Alô? Quem é você?'),
        _l(
          2,
          'Astra',
          'Eu deveria te perguntar isso. Como você encontrou meu sinal?',
        ),
        _l(3, 'Noah', 'Esse número apareceu no meu sonho.'),
        _l(4, 'Astra', 'No seu céu existem duas luas?'),
        _l(5, 'Noah', 'Não. Só uma.'),
        _l(6, 'Astra', 'Então não estamos no mesmo mundo.'),
      ],
    ),
    FanEpisode(
      id: 'e2',
      title: 'A segunda lua',
      order: 1,
      lines: [
        _l(1, 'Astra', 'A segunda lua vai desaparecer em dez minutos.'),
        _l(2, 'Noah', 'E o que acontece depois?'),
        _l(
          3,
          'Astra',
          'Nossa conversa acaba... a menos que você encontre uma porta.',
        ),
      ],
    ),
  ],
  'demo_meianoite': [
    FanEpisode(
      id: 'e1',
      title: '00:01',
      order: 0,
      lines: [
        _l(1, 'Desconhecido', 'Você ainda mora naquela casa?'),
        _l(2, 'Maya', 'Quem está falando?'),
        _l(3, 'Desconhecido', 'Não acenda a luz do corredor.'),
        _l(4, 'Maya', 'Como sabe que estou no corredor?'),
        _l(5, 'Desconhecido', 'Eu morei aí. Antes de morrer.'),
      ],
    ),
    FanEpisode(
      id: 'e2',
      title: 'O retrato',
      order: 1,
      lines: [
        _l(1, 'Maya', 'Achei uma foto antiga de você.'),
        _l(2, 'Desconhecido', 'Olhe atrás da moldura.'),
        _l(3, 'Maya', 'Tem um nome escrito aqui. É o meu.'),
      ],
    ),
  ],
  'demo_cartas': [
    FanEpisode(
      id: 'e1',
      title: 'Assento 14B',
      order: 0,
      lines: [
        _l(1, 'Eva', 'Acho que você deixou uma carta no trem.'),
        _l(2, 'Theo', 'Não era para ninguém encontrar.'),
        _l(3, 'Eva', 'Então por que escreveu na capa: para quem precisar?'),
        _l(
          4,
          'Theo',
          'Porque às vezes um estranho entende o que a gente não consegue dizer.',
        ),
        _l(5, 'Eva', 'Talvez eu tenha precisado dela hoje.'),
      ],
    ),
    FanEpisode(
      id: 'e2',
      title: 'Palavras guardadas',
      order: 1,
      lines: [
        _l(1, 'Theo', 'Você guardou a carta?'),
        _l(2, 'Eva', 'Guardei. E escrevi uma resposta.'),
        _l(3, 'Theo', 'Posso ler?'),
        _l(4, 'Eva', 'Quando a gente se encontrar.'),
      ],
    ),
  ],
};

// Amostras em prosa para experimentar o leitor estilo Wattpad.
final Map<String, List<FanChapter>> demoChapters = {
  'demo_universos': [
    const FanChapter(
      id: 'c1',
      order: 0,
      title: 'A cidade com duas luas',
      paragraphs: [
        'Noah sabia que aquela noite não era como as outras. Sobre os telhados da cidade, a lua parecia ter ganhado uma irmã: duas esferas prateadas flutuavam no céu de outono.',
        'O relógio marcava onze e cinquenta e nove quando o telefone vibrou em sua mão. Não havia sinal, não havia operadora, mas uma mensagem esperava para ser aberta.',
        '“Se você consegue ler isto, os nossos mundos estão mais próximos do que deveriam.” A mensagem não tinha remetente. Tinha apenas um pequeno símbolo de estrela.',
        'Ele olhou novamente para o horizonte. Entre os prédios, o reflexo de uma segunda lua começava a se formar nas janelas.',
        'Noah nunca acreditara em destinos escritos nas estrelas. Mas naquela noite, pela primeira vez, teve a sensação de que alguma coisa o estava procurando.',
      ],
    ),
    const FanChapter(
      id: 'c2',
      order: 1,
      title: 'A porta no céu',
      paragraphs: [
        'A porta apareceu onde antes havia apenas uma parede de tijolos. Era estreita, alta e feita de uma madeira que parecia conter pequenos pontos de luz.',
        'Do outro lado, a voz de Astra atravessou o silêncio: “Você chegou. Mas precisa decidir se quer conhecer a verdade.”',
        'Noah tocou a maçaneta. Estava morna, como se alguém segurasse sua mão do outro lado.',
        'Quando abriu a porta, o vento trouxe o cheiro do mar e a certeza de que jamais poderia contar aquela história de uma forma simples.',
      ],
    ),
  ],
  'demo_cartas': [
    const FanChapter(
      id: 'c1',
      order: 0,
      title: 'Assento 14B',
      paragraphs: [
        'O trem partiu no instante em que Eva percebeu o envelope sobre o assento vazio. Não havia nome, endereço nem selo, apenas uma frase escrita à mão: Para quem precisar.',
        'Ela hesitou. Não costumava ler coisas que não lhe pertenciam. Mas era uma tarde em que as palavras pareciam ter decidido encontrá-la.',
        'Dentro, a carta falava sobre despedidas que nunca foram ditas e sobre a coragem necessária para começar outra vez.',
        'Eva apertou o papel contra o peito. Pela janela, a cidade se desfazia em manchas de luz dourada.',
        'No verso do envelope, havia um contato e uma pergunta: Você também guardou alguma palavra?',
      ],
    ),
    const FanChapter(
      id: 'c2',
      order: 1,
      title: 'Palavras guardadas',
      paragraphs: [
        'Theo não esperava receber uma resposta. Muito menos uma tão honesta.',
        'A mensagem de Eva não pedia explicações. Contava apenas que certas frases chegam no momento exato em que precisamos delas.',
        'Encontraram-se no café da estação, numa manhã de chuva fina. Não havia música de fundo, nenhuma cena ensaiada.',
        'Só duas pessoas, duas xícaras e a sensação de que uma história podia começar com aquilo que alguém tinha deixado para trás.',
      ],
    ),
  ],
};
