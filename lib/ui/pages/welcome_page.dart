import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';
import 'shell_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.replay = false});
  final bool replay;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final controller = PageController();
  int page = 0;
  bool leaving = false, moving = false;
  static const slides = [
    (
      'Pequenas histórias.\nGrandes emoções.',
      'Bem-vindo ao FAN. Seu lugar para descobrir histórias que ficam.',
      null,
    ),
    (
      'Descubra universos\nincríveis.',
      'Romance, fantasia, mistério e muito mais. Em chat ou em capítulos.',
      'assets/covers/universos_paralelos.webp',
    ),
    (
      'Faça parte\nda conversa.',
      'Mensagens ganham vida. Escolha suas respostas ou mergulhe em um livro, capítulo por capítulo.',
      'assets/covers/entre_mensagens.webp',
    ),
  ];
  Future<void> finish() async {
    if (leaving) return;
    setState(() => leaving = true);
    try {
      await (await SharedPreferences.getInstance()).setBool(
        'fan_intro_seen',
        true,
      );
    } catch (_) {}
    if (!mounted) return;
    if (widget.replay) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShellPage()),
    );
  }

  Future<void> next() async {
    if (leaving || moving) return;
    if (page == 2) {
      await finish();
      return;
    }
    setState(() => moving = true);
    if (FanScope.of(context).reduceMotion ||
        MediaQuery.disableAnimationsOf(context)) {
      controller.jumpToPage(page + 1);
    } else {
      await controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
    if (mounted) setState(() => moving = false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/backgrounds/stars.webp',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FanColors.background.withValues(alpha: .4),
                  FanColors.background,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      children: [
                        const FanLogo(),
                        const Spacer(),
                        TextButton(
                          onPressed: leaving ? null : finish,
                          child: const Text('Pular'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => page = i),
                      itemBuilder: (context, i) => LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: (box.maxHeight * .45)
                                        .clamp(180, 300)
                                        .toDouble(),
                                    child: slides[i].$3 == null
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 72,
                                                color: FanColors.orchid,
                                              ),
                                              SizedBox(height: 18),
                                              FanLogo(size: 52),
                                            ],
                                          )
                                        : Center(
                                            child: AspectRatio(
                                              aspectRatio: .82,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: Image.asset(
                                                  slides[i].$3!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    slides[i].$1,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      letterSpacing: -.8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    slides[i].$2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: FanColors.muted,
                                      fontSize: 14,
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Semantics(
                        label: 'Etapa ${i + 1} de 3',
                        selected: i == page,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 7,
                          width: i == page ? 24 : 7,
                          decoration: BoxDecoration(
                            color: i == page
                                ? FanColors.orchid
                                : FanColors.line,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: FanButton(
                      label: page == 2 ? 'Começar agora' : 'Próximo',
                      loading: leaving,
                      onPressed: moving ? null : next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
