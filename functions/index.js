/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const cloudinary = require("cloudinary").v2;
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentDeleted, onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");

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
  
  const messagesRef = db.collection("chats").doc(chatId).collection("messages");
  await db.recursiveDelete(messagesRef);

  const batch = db.batch();

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

  const itemID = deletedChat.itemID;
  if (itemID) {
    const itemRef = db.collection("items").doc(itemID);
    
    const itemSnap = await itemRef.get();
    if (itemSnap.exists) {
      batch.update(itemRef, {
        chats: FieldValue.arrayRemove(chatId),
      });
    }
  }

  try {
    await batch.commit();
    console.log(`チャット (${chatId}) の削除に伴い、関連する users と items を更新しました`);
  } catch (error) {
    console.error(`チャット (${chatId}) に関連するデータの更新に失敗しました:`, error);
  }
});

exports.deleteOldImageOnUpdate = onDocumentUpdated("items/{itemId}", async (event) => {
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

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "ログイン状態が確認できませんでした。");
  }

  const db = getFirestore();

  try {
    const batch = db.batch();

    const userRef = db.collection("users").doc(uid);
    batch.delete(userRef);

    const itemsSnapshot = await db.collection("items")
      .where("ownerID", "==", uid)
      .get();

    itemsSnapshot.forEach((itemDoc) => {
      batch.delete(itemDoc.ref);
    });

    await batch.commit();
    console.log(`DB削除完了: ユーザー(${uid}) と アイテム ${itemsSnapshot.size} 件`);

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

  const { publicId } = request.data;
  if (!publicId || typeof publicId !== "string") {
    throw new HttpsError("invalid-argument", "画像の publicId が正しく指定されていません。");
  }

  try {
    const result = await cloudinary.uploader.destroy(publicId);
    console.log(`Cloudinary削除結果 (${publicId}):`, result);

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

exports.sendNotificationOnNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const messageData = snap.data();

  if (messageData.contentType === "Delete") return;

  const senderID = messageData.senderID;
  const chatId = event.params.chatId;
  const db = getFirestore();

  try {
    const chatRef = db.collection("chats").doc(chatId);
    const chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;

    const chatData = chatDoc.data();
    const sentBy = chatData.sentBy;
    const sentTo = chatData.sentTo;

    const receiverId = senderID === sentBy ? sentTo : sentBy;
    if (!receiverId) return;

    const blockedBy = chatData.blockedBy || [];
    if (blockedBy.includes(receiverId) || blockedBy.includes(senderID)) {
      console.log("ブロック設定のため通知および未読インクリメントをスキップします");
      return;
    }

    await chatRef.update({
      [`unreadCounts.${receiverId}`]: FieldValue.increment(1)
    });

    const mutedBy = chatData.mutedBy || [];
    if (mutedBy.includes(receiverId)) {
      console.log(`ユーザー (${receiverId}) はミュート設定のため通知をスキップします`);
      return;
    }

    const userDoc = await db.collection("users").doc(receiverId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`ユーザー (${receiverId}) のFCMトークンが存在しません`);
      return;
    }

    let bodyText = "";
    if (messageData.contentType === "text") {
      bodyText = messageData.content;
    } else if (messageData.contentType === "image") {
      bodyText = "画像が送信されました";
    }

    const itemName = chatData.item?.name ? `(${chatData.item.name})` : "";

    const payload = {
      token: fcmToken,
      notification: {
        title: `新しいメッセージ ${itemName}`,
        body: bodyText,
      },
      data: {
        chatId: chatId
      },
      apns: {
        payload: {
          aps: {
            sound: "default"
          }
        }
      }
    };

    await getMessaging().send(payload);
    console.log(`通知送信成功: ユーザー ${receiverId} 宛て`);

  } catch (error) {
    console.error("プッシュ通知の送信中にエラーが発生しました:", error);
  }
});
