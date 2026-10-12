/**
 * Seed the four sample stories and their episodes into Firestore.
 * Run from the repository root: node firebase/seed/seed.mjs
 * Authentication: GOOGLE_APPLICATION_CREDENTIALS=/private/path/service-account.json
 * Never put service account files in the app or Git repository.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const dirname = path.dirname(fileURLToPath(import.meta.url));
const file = path.join(dirname, 'demo.json');
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('Configure GOOGLE_APPLICATION_CREDENTIALS with a private Firebase service account path.');
  process.exit(1);
}
admin.initializeApp({credential: admin.credential.applicationDefault()});
const db = admin.firestore();
const stories = JSON.parse(fs.readFileSync(file, 'utf8'));
for (const entry of stories) {
  const {id, episodes, ...story} = entry;
  const storyRef = db.collection('stories').doc(id);
  await storyRef.set({
    ...story, published: true, episodeCount: episodes.length,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  for (let i = 0; i < episodes.length; i++) {
    const episode = episodes[i];
    await storyRef.collection('episodes').doc(`e${i + 1}`).set({
      title: episode.title, order: i, lines: episode.lines,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  console.log(`Seeded: ${story.title} (${episodes.length} episodes)`);
}
console.log('Done. Stories are now published in Firestore.');
