/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const cloudinary = require("cloudinary").v2;

initializeApp();

setGlobalOptions({ maxInstances: 10 });

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

  const chatsArray = deletedData.chatsArray;
  
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
  const db = getFirestore();
  const chatId = event.params.chatId;
  const messagesRef = db.collection("chats").doc(chatId).collection("messages");
  await db.recursiveDelete(messagesRef);

  const usersSnapshot = await db.collection("users")
    .where("chats", "array-contains", chatId)
    .get();

  if (!usersSnapshot.empty) {
    const batch = db.batch();
    usersSnapshot.forEach((userDoc) => {
      batch.update(userDoc.ref, {
        chats: FieldValue.arrayRemove(chatId),
      });
    });
    await batch.commit();
  }
});
