importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker with full credentials
firebase.initializeApp({
  apiKey: "AIzaSyB9CayWyFJSQ7qHczNaTr7yzVS0LTnfmbc",
  authDomain: "church-usher-app.firebaseapp.com",
  projectId: "church-usher-app",
  storageBucket: "church-usher-app.firebasestorage.app",
  messagingSenderId: "384928842494",
  appId: "1:384928842494:web:fe40cc61f152b172235baf"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'Guardians Usher Hub';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : 'New alert from Usher Hub',
    icon: 'favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
