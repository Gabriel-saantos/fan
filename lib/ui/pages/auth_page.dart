import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false, loading = false, hide = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading || !form.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final store = FanScope.of(context);
      if (store.demoMode) {
        await store.enterLocal(name.text);
      } else if (register) {
        await store.register(name.text, email.text, password.text);
      } else {
        await store.logIn(email.text, password.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => error = switch (e.code) {
            'email-already-in-use' =>
              'Este e-mail já tem uma conta. Tente entrar.',
            'invalid-email' => 'Confira o endereço de e-mail.',
            'weak-password' => 'Escolha uma senha mais forte.',
            'wrong-password' ||
            'invalid-credential' ||
            'user-not-found' => 'Confira seu e-mail e sua senha.',
            'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos.',
            'network-request-failed' =>
              'Verifique sua conexão e tente novamente.',
            _ => 'Não foi possível entrar. Tente novamente.',
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = fanError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> recover() async {
    if (loading) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      setState(
        () => error = 'Informe um e-mail válido para recuperar a senha.',
      );
      return;
    }
    setState(() => loading = true);
    try {
      await FanScope.of(context).resetPassword(email.text);
      if (mounted) {
        fanMessage(
          context,
          'Se houver uma conta, enviaremos as instruções por e-mail.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = fanError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = FanScope.of(context).demoMode;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                const FanLogo(size: 42),
                const SizedBox(height: 40),
                Text(
                  local
                      ? 'Seu espaço no FAN.'
                      : register
                      ? 'Comece sua história.'
                      : 'Bem-vindo de volta.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  local
                      ? 'Um perfil para suas leituras e criações. Sem e-mail ou senha: os dados ficam apenas neste dispositivo.'
                      : register
                      ? 'Leia, salve e escreva histórias com a sua conta.'
                      : 'Entre para encontrar suas histórias e continuar a leitura.',
                  style: const TextStyle(color: FanColors.muted, height: 1.7),
                ),
                const SizedBox(height: 28),
                Form(
                  key: form,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        if (local || register) ...[
                          TextFormField(
                            controller: name,
                            enabled: !loading,
                            maxLength: 40,
                            textInputAction: local
                                ? TextInputAction.done
                                : TextInputAction.next,
                            onFieldSubmitted: local ? (_) => submit() : null,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Como podemos chamar você?',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v?.trim().length ?? 0) < 2
                                ? 'Use pelo menos 2 caracteres.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (!local) ...[
                          TextFormField(
                            controller: email,
                            enabled: !loading,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (v) =>
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v?.trim() ?? '')
                                ? null
                                : 'Informe um e-mail válido.',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: password,
                            enabled: !loading,
                            obscureText: hide,
                            autofillHints: [
                              register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: hide
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: () => setState(() => hide = !hide),
                                icon: Icon(
                                  hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => (v?.length ?? 0) < 6
                                ? 'Use pelo menos 6 caracteres.'
                                : null,
                          ),
                          if (!register)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: loading ? null : recover,
                                child: const Text('Esqueci minha senha'),
                              ),
                            ),
                        ],
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              error!,
                              style: const TextStyle(color: FanColors.pink),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FanButton(
                          label: local
                              ? 'Começar a explorar'
                              : register
                              ? 'Criar conta'
                              : 'Entrar',
                          loading: loading,
                          onPressed: submit,
                        ),
                        if (!local) ...[
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => setState(() {
                                    register = !register;
                                    error = null;
                                  }),
                            child: Text(
                              register
                                  ? 'Já tenho uma conta'
                                  : 'Ainda não tenho conta · Criar conta',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> requireFanLogin(BuildContext context) async {
  if (FanScope.of(context).signedIn) return true;
  return await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      ) ==
      true;
}
