import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'library_page.dart';
import 'publish_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  void open(BuildContext context, String title, Widget child) => Navigator.push(context,
    MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: child)));
  Future<void> edit(BuildContext context) async {
    final store = FanScope.of(context);
    final name = TextEditingController(text: store.displayName), bio = TextEditingController(text: store.bio);
    final form = GlobalKey<FormState>();
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Seu perfil'), content: SizedBox(width: 420, child: SingleChildScrollView(
        child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: name, maxLength: 40, decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Use pelo menos 2 caracteres.' : null),
          const SizedBox(height: 16), TextFormField(controller: bio, maxLength: 160, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Sobre você')),
        ])))), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('Salvar'))]));
    if (result == true) {
      try { await store.editProfile(name.text, bio.text); if (context.mounted) fanMessage(context, 'Perfil atualizado.'); }
      catch (e) { if (context.mounted) fanMessage(context, fanError(e)); }
    }
    // Controllers are disposed after the closing route animation completes.
    await Future<void>.delayed(const Duration(milliseconds: 300)); name.dispose(); bio.dispose();
  }
  Future<void> clear(BuildContext context) async {
    final store = FanScope.of(context);
    final result = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Apagar dados locais?'),
      content: const Text('Seu perfil, histórias, rascunhos, favoritos e progresso deste dispositivo serão apagados. Esta ação não pode ser desfeita.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar dados'))]));
    if (result != true) return;
    try { await store.clearLocalData(); if (context.mounted) fanMessage(context, 'Dados locais apagados.'); }
    catch (e) { if (context.mounted) fanMessage(context, fanError(e)); }
  }
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    return ListView(padding: fanPagePadding(context), children: [
      const FanPageHeader(eyebrow: 'Sua identidade', title: 'Um espaço com a sua cara.',
        subtitle: 'Cuide do perfil e escolha como prefere viver suas histórias.'),
      if (!store.signedIn) FanEmptyState(icon: Icons.person_outline_rounded,
        title: 'Faça parte da história.', message: store.demoMode
          ? 'Crie um perfil local para salvar leituras e escrever suas próprias conversas.'
          : 'Entre na sua conta para levar suas histórias com você.',
        actionLabel: store.demoMode ? 'Criar perfil local' : 'Entrar ou criar conta',
        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())))
      else ...[
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          CircleAvatar(radius: 38, backgroundColor: FanColors.purple,
            child: Text(store.displayName.isEmpty ? 'F' : store.displayName[0].toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: FanColors.background))),
          const SizedBox(height: 18), Text(store.displayName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6), Text(store.email, style: const TextStyle(color: FanColors.muted, fontSize: 12)),
          if (store.bio.isNotEmpty) ...[const SizedBox(height: 16), Text(store.bio, textAlign: TextAlign.center,
            style: const TextStyle(color: FanColors.muted, height: 1.7))],
          const SizedBox(height: 18), OutlinedButton.icon(onPressed: () => edit(context),
            icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar perfil')),
          const SizedBox(height: 24), Wrap(spacing: 28, runSpacing: 16, alignment: WrapAlignment.center, children: [
            _Metric('${store.myStories.length}', 'Histórias'), _Metric('${store.savedStories.length}', 'Salvas'),
            _Metric('${store.completedStories.length}', 'Concluídas'), _Metric('${store.followingCount}', 'Seguindo'),
          ]),
        ]))),
        const SizedBox(height: 24),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.edit_note_rounded, color: FanColors.orchid),
            title: const Text('Meu estúdio'), subtitle: const Text('Histórias e episódios que você criou'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => open(context, 'Estúdio', const PublishPage())),
          const Divider(height: 1), ListTile(leading: const Icon(Icons.favorite_outline_rounded, color: FanColors.pink),
            title: const Text('Minhas curtidas'), trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => open(context, 'Biblioteca', const LibraryPage(initialTab: 3))),
        ])),
      ],
      const SizedBox(height: 28), const FanSectionHeading(title: 'Preferências de leitura'),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tamanho das mensagens · ${store.readerFontSize.round()}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(value: store.readerFontSize, min: 14, max: 22, divisions: 4,
          label: '${store.readerFontSize.round()}', onChanged: (v) => store.setReadingPreferences(fontSize: v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Reduzir animações'),
          subtitle: const Text('Evita movimentos automáticos na conversa.'), value: store.reduceMotion,
          onChanged: (v) => store.setReadingPreferences(reducedMotion: v)),
      ]))),
      const SizedBox(height: 28), Card(child: ListTile(leading: Icon(store.demoMode ? Icons.devices_rounded : Icons.cloud_done_outlined),
        title: Text(store.demoMode ? 'Dados neste dispositivo' : 'Sincronização com Firebase'),
        subtitle: Text(store.demoMode ? 'Não há sincronização entre dispositivos. Limpar os dados do navegador remove suas histórias.'
          : 'Favoritos, perfil e histórias são associados à sua conta.'), isThreeLine: true)),
      if (store.signedIn) ...[const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: () async {
          try { await store.logOut(); if (context.mounted) fanMessage(context, 'Você saiu do perfil.'); }
          catch (e) { if (context.mounted) fanMessage(context, fanError(e)); }
        }, icon: const Icon(Icons.logout_rounded), label: const Text('Sair do perfil'))],
      if (store.demoMode) ...[const SizedBox(height: 14), TextButton(onPressed: () => clear(context),
        child: const Text('Apagar dados deste dispositivo', style: TextStyle(color: FanColors.pink)))],
      const SizedBox(height: 28), const Center(child: Text('fan · Histórias que conectam', style: TextStyle(color: FanColors.muted, fontSize: 12))),
    ]);
  }
}
class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [Text(value,
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: FanColors.orchid)),
    const SizedBox(height: 6), Text(label, style: const TextStyle(color: FanColors.muted, fontSize: 12))]);
}
