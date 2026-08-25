importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing the messagingSenderId
firebase.initializeApp({
  messagingSenderId: "384928842494"
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
