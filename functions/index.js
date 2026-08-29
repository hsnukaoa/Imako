/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onDocumentDeleted, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const cloudinary = require("cloudinary").v2;

initializeApp();

setGlobalOptions({
    region: "asia-northeast1",
    maxInstances: 10
});

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

exports.onItemDeleted = onDocumentDeleted("items/{itemId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const deletedData = snap.data();
  const db = getFirestore();

  const publicId = deletedData.imagePublicId;
  if (publicId) {
    try {
      await cloudinary.uploader.destroy(publicId);
      console.log(`Cloudinaryの画像 (${publicId}) の削除に成功しました`);
    } catch (error) {
      console.error(`Cloudinaryの画像 (${publicId}) の削除に失敗しました:`, error);
    }
  } else {
    console.log("このドキュメントにはCloudinaryの画像が紐付いていませんでした。");
  }

  // Swift側の CodingKeys で `case chatIDs = "chats"` としているため、
  // Firestoreに保存されているフィールド名は `chatsArray` ではなく `chats` になります。
  const chatsArray = deletedData.chats;
  
  if (chatsArray && Array.isArray(chatsArray) && chatsArray.length > 0) {
    try {
      const batch = db.batch();
      
      chatsArray.forEach((chatId) => {
        const chatRef = db.collection("chats").doc(chatId);
        batch.delete(chatRef);
      });

      await batch.commit();
      console.log(`関連するチャット ${chatsArray.length} 件を削除しました`);
      
    } catch (error) {
      console.error("関連チャットの削除に失敗しました:", error);
    }
  }
});

exports.onChatDeleted = onDocumentDeleted("chats/{chatId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  
  const deletedChat = snap.data();
  const db = getFirestore();
  const chatId = event.params.chatId;
  
  // 1. messages サブコレクションの削除
  const messagesRef = db.collection("chats").doc(chatId).collection("messages");
  await db.recursiveDelete(messagesRef);

  // 2. 配列からのID削除用バッチを作成
  const batch = db.batch();

  // ① users コレクションから該当チャットIDを削除
  const usersSnapshot = await db.collection("users")
    .where("chats", "array-contains", chatId)
    .get();

  if (!usersSnapshot.empty) {
    usersSnapshot.forEach((userDoc) => {
      batch.update(userDoc.ref, {
        chats: FieldValue.arrayRemove(chatId),
      });
    });
  }

  // ② items コレクションから該当チャットIDを削除 (TODO 2 解決 ＋ 連鎖削除エラー防止策)
  const itemID = deletedChat.itemID;
  if (itemID) {
    const itemRef = db.collection("items").doc(itemID);
    
    // 連鎖削除時（退会→アイテム削除→チャット削除）に、
    // すでにアイテムが存在しない場合のエラーを防ぐため、存在チェックを挟みます。
    const itemSnap = await itemRef.get();
    if (itemSnap.exists) {
      batch.update(itemRef, {
        chats: FieldValue.arrayRemove(chatId),
      });
    }
  }

  // バッチ処理をコミット
  try {
    await batch.commit();
    console.log(`チャット (${chatId}) の削除に伴い、関連する users と items を更新しました`);
  } catch (error) {
    console.error(`チャット (${chatId}) に関連するデータの更新に失敗しました:`, error);
  }
});

// v2 の `onDocumentUpdated` を使った書き方に修正
exports.deleteOldImageOnUpdate = onDocumentUpdated("items/{itemId}", async (event) => {
  // イベントデータが存在しない場合はスキップ
  if (!event.data) return;

  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  const oldPublicId = beforeData.imagePublicId;
  const newPublicId = afterData.imagePublicId;

  if (oldPublicId && newPublicId && oldPublicId !== newPublicId) {
    console.log(`画像の変更を検知しました。古い画像を削除します: ${oldPublicId}`);
    
    try {
      const result = await cloudinary.uploader.destroy(oldPublicId);
      console.log(`Cloudinary削除結果 (${oldPublicId}):`, result);
    } catch (error) {
      console.error(`Cloudinary画像の削除エラー (${oldPublicId}):`, error);
    }
  }
  
  return null;
});

// 新規追加: ユーザー退会処理（v2 Callable関数）
exports.deleteAccount = onCall(async (request) => {
  // リクエストしたユーザーのUIDを取得（未認証なら弾く）
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "ログイン状態が確認できませんでした。");
  }

  const db = getFirestore();

  try {
    const batch = db.batch();

    // ① users コレクションから同じUIDを持つドキュメントを削除
    const userRef = db.collection("users").doc(uid);
    batch.delete(userRef);

    // ② items コレクションから ownerID が uid と一致するものを検索
    const itemsSnapshot = await db.collection("items")
      .where("ownerID", "==", uid)
      .get();

    itemsSnapshot.forEach((itemDoc) => {
      batch.delete(itemDoc.ref);
    });

    // バッチ処理を実行（DBのデータを一括削除）
    await batch.commit();
    console.log(`DB削除完了: ユーザー(${uid}) と アイテム ${itemsSnapshot.size} 件`);

    // ③ 最後に Firebase Authentication からユーザー本体を削除
    await getAuth().deleteUser(uid);
    console.log(`Auth削除完了: ユーザー(${uid})`);

    return { success: true, message: "退会処理が正常に完了しました。" };
    
  } catch (error) {
    console.error(`ユーザー(${uid}) の退会処理に失敗しました:`, error);
    throw new HttpsError("internal", "サーバーエラーが発生しました。");
  }
});


exports.deleteCloudinaryImage = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "ログイン状態が確認できませんでした。");
  }

  // 2. Swift側から渡されたパラメータ(publicId)を取得
  const { publicId } = request.data;
  if (!publicId || typeof publicId !== "string") {
    throw new HttpsError("invalid-argument", "画像の publicId が正しく指定されていません。");
  }

  // 3. Cloudinaryから画像を削除
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    console.log(`Cloudinary削除結果 (${publicId}):`, result);

    // destroyメソッドは成功しても { result: 'ok' } 以外（'not found'など）を返すことがあるため確認
    if (result.result === 'ok' || result.result === 'not found') {
      return { success: true, message: "画像の削除に成功しました" };
    } else {
      throw new HttpsError("internal", `Cloudinaryで不明なエラー: ${result.result}`);
    }

  } catch (error) {
    console.error(`Cloudinary画像の削除に失敗しました (${publicId}):`, error);
    throw new HttpsError("internal", "サーバーエラーにより画像の削除に失敗しました。");
  }
});
