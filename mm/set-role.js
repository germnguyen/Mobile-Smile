
const admin = require('firebase-admin');

async function setAuthenticatedRole(uid) {
  const user = await admin.auth().getUser(uid);

  // Giữ nguyên các claim hiện có.
  const existingClaims = user.customClaims ?? {};

  await admin.auth().setCustomUserClaims(uid, {
    ...existingClaims,
    role: 'authenticated',
  });

  console.log(`Đã cấp role=authenticated cho UID: ${uid}`);
}

