import {before, beforeEach, after, test} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, updateDoc, runTransaction} from 'firebase/firestore';

let env;
const author = 'author-a';
const story = (format, published = false) => ({
  title: 'Uma nova história', description: 'Uma narrativa sobre encontros inesperados.',
  category: 'Fantasia', authorId: author, authorName: 'Autor',
  coverAsset: 'assets/covers/universos_paralelos.webp', coverUrl: '',
  contentRating: 'Livre', format, episodeCount: 0, published,
  createdAt: 1, updatedAt: 1,
});
const chapter = {title: 'O primeiro encontro', order: 0, paragraphs: ['Uma noite de aventuras.'], createdAt: 1};
const episode = {title: 'Uma conversa', order: 0, lines: [
  {id: 'm1', speaker: 'Lia', text: 'Olá'}, {id: 'm2', speaker: 'Theo', text: 'Oi'},
], createdAt: 1};
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-fan', firestore: {
    host: '127.0.0.1', port: 8085, rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
  }});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'stories/book'), story('chapter'));
    await setDoc(doc(db, 'stories/chat'), story('chat'));
    await setDoc(doc(db, 'stories/public'), story('chapter', true));
  });
});
after(async () => env?.cleanup());
const ownDb = () => env.authenticatedContext(author).firestore();

test('anonymous reads published stories but cannot read drafts', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'stories/public')));
  await assertFails(getDoc(doc(db, 'stories/book')));
});
test('author creates a chapter and its counter in one transaction', async () => {
  const db = ownDb();
  await assertSucceeds(runTransaction(db, async tx => {
    const parent = doc(db, 'stories/book'); const snapshot = await tx.get(parent);
    tx.set(doc(db, 'stories/book/chapters/c1'), chapter);
    tx.update(parent, {episodeCount: snapshot.data().episodeCount + 1});
  }));
});
test('chapter and chat content cannot be mixed', async () => {
  const db = ownDb();
  await assertFails(setDoc(doc(db, 'stories/chat/chapters/c1'), chapter));
  await assertFails(setDoc(doc(db, 'stories/book/episodes/e1'), episode));
});
test('another user cannot write or edit a chapter', async () => {
  const db = env.authenticatedContext('other-author').firestore();
  await assertFails(setDoc(doc(db, 'stories/book/chapters/c1'), chapter));
  await assertFails(updateDoc(doc(db, 'stories/book'), {title: 'Outro título'}));
});
test('author edits chapter text but cannot alter its order', async () => {
  const db = ownDb();
  await assertSucceeds(setDoc(doc(db, 'stories/book/chapters/c1'), chapter));
  await assertSucceeds(updateDoc(doc(db, 'stories/book/chapters/c1'), {paragraphs: ['Texto revisado.']}));
  await assertFails(updateDoc(doc(db, 'stories/book/chapters/c1'), {order: 7}));
});
test('published story may return to draft; format cannot change', async () => {
  const db = ownDb();
  await assertSucceeds(updateDoc(doc(db, 'stories/public'), {published: false}));
  await assertFails(updateDoc(doc(db, 'stories/book'), {format: 'chat'}));
});
test('library accepts chat and chapter progress only for its owner', async () => {
  const state = {saved: true, liked: false, started: true, completed: false,
    episodeIndex: 0, currentEpisodeId: '', visibleCount: 0, answers: {},
    chapterIndex: 0, chapterProgress: .45, updatedAt: 1};
  await assertSucceeds(setDoc(doc(ownDb(), `users/${author}/library/book`), state));
  await assertFails(setDoc(doc(env.authenticatedContext('other').firestore(), `users/${author}/library/book`), state));
  await assertFails(updateDoc(doc(ownDb(), `users/${author}/library/book`), {chapterProgress: 2}));
});
test('legacy chat stories without format remain editable', async () => {
  const data = story('chat'); delete data.format;
  await env.withSecurityRulesDisabled(context => setDoc(doc(context.firestore(), 'stories/legacy'), data));
  await assertSucceeds(updateDoc(doc(ownDb(), 'stories/legacy'), {title: 'Título revisado', format: 'chat'}));
});
