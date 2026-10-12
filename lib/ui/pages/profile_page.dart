import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'publish_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> edit(BuildContext context) async {
    final store = FanScope.of(context);
    final name = TextEditingController(text: store.displayName);
    final bio = TextEditingController(text: store.bio);
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Editar perfil'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nome de exibição')),
        const SizedBox(height: 12),
        TextField(controller: bio, maxLength: 160, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Biografia')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
      ],
    ));
    if (result == true && context.mounted) {
      try {
        if (name.text.trim().length < 2) throw StateError('Informe pelo menos 2 letras.');
        await store.editProfile(name.text, bio.text);
        if (context.mounted) fanMessage(context, 'Perfil atualizado!');
      } catch (e) { if (context.mounted) fanMessage(context, '$e'); }
    }
    name.dispose(); bio.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
      Row(children: [
        const Text('Meu perfil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        const Spacer(),
        IconButton(onPressed: () => fanMessage(context,
          'Notificações e privacidade avançada serão configuradas antes do lançamento.'),
          icon: const Icon(Icons.settings_outlined)),
      ]),
      const SizedBox(height: 23),
      if (!store.signedIn) ...[
        const Center(child: CircleAvatar(radius: 49,
          backgroundColor: FanColors.surface2,
          child: Icon(Icons.person_outline_rounded, size: 42, color: FanColors.orchid))),
        const SizedBox(height: 20),
        const Center(child: Text('Sua história começa aqui.',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19))),
        const SizedBox(height: 10),
        const Center(child: Text('Crie uma conta e faça parte do FAN.',
          style: TextStyle(color: FanColors.muted, fontSize: 12))),
        const SizedBox(height: 25),
        FanButton(label: 'Entrar ou criar conta', onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AuthPage()))),
      ] else ...[
        Center(child: Container(
          width: 99, height: 99, decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: FanColors.gradient),
          child: Center(child: Text(store.displayName.isEmpty ? 'F' : store.displayName[0].toUpperCase(),
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900,
              color: FanColors.background))))),
        const SizedBox(height: 15),
        Center(child: Text(store.displayName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        const SizedBox(height: 6),
        Center(child: Text(store.email, style: const TextStyle(fontSize: 10.5, color: FanColors.muted))),
        const SizedBox(height: 15),
        Center(child: Text(store.bio, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, color: FanColors.muted, height: 1.6))),
        const SizedBox(height: 19),
        OutlinedButton.icon(onPressed: () => edit(context),
          icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar perfil'),
          style: OutlinedButton.styleFrom(foregroundColor: FanColors.orchid,
            side: const BorderSide(color: FanColors.line),
            padding: const EdgeInsets.symmetric(vertical: 13))),
        const SizedBox(height: 27),
        Container(padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: FanColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            _Metric('${store.myStories.length}', 'Histórias'),
            Container(height: 30, width: 1, color: FanColors.line),
            _Metric('${store.savedStories.length}', 'Salvas'),
            Container(height: 30, width: 1, color: FanColors.line),
            _Metric('${store.readingStories.length}', 'Lendo'),
          ])),
        const SizedBox(height: 23),
        const FanSectionHeading(title: 'Meu espaço'),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_note_rounded, color: FanColors.orchid),
          title: const Text('Minhas histórias', style: TextStyle(fontSize: 12.5)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const Scaffold(appBar: _SimpleAppBar(), body: PublishPage())))),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.favorite_border_rounded, color: FanColors.pink),
          title: const Text('Histórias curtidas', style: TextStyle(fontSize: 12.5)),
          subtitle: const Text('Disponíveis na Biblioteca', style: TextStyle(fontSize: 10, color: FanColors.muted))),
        const SizedBox(height: 18),
        OutlinedButton.icon(onPressed: () async {
          await store.logOut();
          if (context.mounted) fanMessage(context, 'Você saiu da conta.');
        }, icon: const Icon(Icons.logout_rounded), label: const Text('Sair da conta'),
          style: OutlinedButton.styleFrom(foregroundColor: FanColors.pink,
            side: const BorderSide(color: FanColors.line),
            padding: const EdgeInsets.symmetric(vertical: 14))),
      ],
      const SizedBox(height: 35),
      const Center(child: Text('FAN · Histórias que conectam · v1.0.0',
        style: TextStyle(fontSize: 10, color: FanColors.muted))),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.caption);
  final String value;
  final String caption;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const SizedBox(height: 7),
    Text(caption, style: const TextStyle(fontSize: 10, color: FanColors.muted)),
  ]));
}

class _SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SimpleAppBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Estúdio FAN'));
}
