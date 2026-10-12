/**
 * Seed four sample stories. Set GOOGLE_APPLICATION_CREDENTIALS to a private
 * service-account JSON outside this project, or use Firestore Emulator.
 * NOTE: This is an upsert and does not delete old episodes/chapters.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const dirname = path.dirname(fileURLToPath(import.meta.url));
const file = path.join(dirname, 'demo.json');
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS with the private service account path.');
  process.exit(1);
}
admin.initializeApp({credential: admin.credential.applicationDefault()});
const db = admin.firestore();
const stories = JSON.parse(fs.readFileSync(file, 'utf8'));
for (const entry of stories) {
  const {id, episodes = [], chapters = [], ...story} = entry;
  const storyRef = db.collection('stories').doc(id);
  const sections = story.format === 'chapter' ? chapters : episodes;
  const subcollection = story.format === 'chapter' ? 'chapters' : 'episodes';
  await storyRef.set({
    ...story, published: true, episodeCount: sections.length,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  for (let i = 0; i < sections.length; i++) {
    const section = sections[i];
    const payload = story.format === 'chapter'
      ? {title: section.title, order: i, paragraphs: section.paragraphs}
      : {title: section.title, order: i, lines: section.lines};
    await storyRef.collection(subcollection).doc(`${story.format === 'chapter' ? 'c' : 'e'}${i + 1}`)
      .set({...payload, createdAt: admin.firestore.FieldValue.serverTimestamp()});
  }
  console.log(`Seeded: ${story.title} (${sections.length} ${subcollection})`);
}
console.log('Done.');
