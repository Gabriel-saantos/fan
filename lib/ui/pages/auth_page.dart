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
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool register = false;
  bool loading = false;
  bool hide = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final store = FanScope.of(context);
      if (register) {
        await store.register(_name.text, _email.text, _password.text);
      } else {
        await store.logIn(_email.text, _password.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted) fanMessage(context, switch (e.code) {
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'invalid-email' => 'E-mail inválido.',
        'weak-password' => 'Senha muito fraca.',
        'wrong-password' || 'invalid-credential' => 'E-mail ou senha incorretos.',
        'user-not-found' => 'Conta não encontrada.',
        _ => e.message ?? 'Não foi possível entrar.',
      });
    } catch (e) { if (mounted) fanMessage(context, 'Falha: $e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> recover() async {
    if (_email.text.trim().isEmpty) {
      fanMessage(context, 'Informe seu e-mail para recuperar a senha.'); return;
    }
    try {
      await FanScope.of(context).resetPassword(_email.text);
      if (mounted) fanMessage(context, 'Se a conta existir, você receberá instruções por e-mail.');
    } catch (e) { if (mounted) fanMessage(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    final demo = FanScope.of(context).demoMode;
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: ListView(padding: const EdgeInsets.fromLTRB(25, 16, 25, 30), children: [
        Align(alignment: Alignment.centerLeft, child: IconButton(
          onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
        const SizedBox(height: 24),
        const Center(child: FanLogo(size: 60)),
        const SizedBox(height: 12),
        const Center(child: Text('Histórias que conectam', style: TextStyle(
          color: FanColors.muted, fontSize: 12))),
        const SizedBox(height: 35),
        Text(register ? 'Crie seu universo.' : 'Que bom ter você aqui.',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.8)),
        const SizedBox(height: 9),
        Text(register ? 'Cadastre-se para publicar e acompanhar histórias.'
          : 'Entre para continuar sua história.',
          style: const TextStyle(fontSize: 12, color: FanColors.muted)),
        const SizedBox(height: 25),
        if (demo) ...[
          Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(
            color: FanColors.surface2, borderRadius: BorderRadius.circular(15)),
            child: const Text('Prévia local: este login é apenas uma simulação. Após conectar o Firebase, suas contas serão reais.',
              style: TextStyle(fontSize: 11, height: 1.5, color: FanColors.pink))),
          const SizedBox(height: 18),
        ],
        Form(key: _form, child: Column(children: [
          if (register) ...[
            TextFormField(controller: _name, maxLength: 40,
              decoration: const InputDecoration(labelText: 'Seu nome', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Digite seu nome.' : null),
            const SizedBox(height: 12),
          ],
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline_rounded)),
            validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Informe um e-mail válido.' : null),
          const SizedBox(height: 13),
          TextFormField(controller: _password, obscureText: hide,
            decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide),
                icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => (v?.length ?? 0) < 6 ? 'Use pelo menos 6 caracteres.' : null),
          if (!register) Align(alignment: Alignment.centerRight, child: TextButton(
            onPressed: recover, child: const Text('Esqueci minha senha',
              style: TextStyle(color: FanColors.orchid, fontSize: 11)))),
          const SizedBox(height: 23),
          FanButton(label: register ? 'Criar conta' : 'Entrar', loading: loading, onPressed: submit),
          const SizedBox(height: 19),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(register ? 'Já tem uma conta?' : 'Ainda não tem uma conta?',
              style: const TextStyle(fontSize: 11, color: FanColors.muted)),
            TextButton(onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Entrar' : 'Cadastre-se',
                style: const TextStyle(color: FanColors.pink, fontSize: 11, fontWeight: FontWeight.w800))),
          ]),
        ])),
      ]),
    ))));
  }
}

Future<bool> requireFanLogin(BuildContext context) async {
  final store = FanScope.of(context);
  if (store.signedIn) return true;
  final result = await Navigator.push<bool>(context,
    MaterialPageRoute(builder: (_) => const AuthPage()));
  return result == true;
}
