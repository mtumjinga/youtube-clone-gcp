import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: "gcp-clone-e980f.firebaseapp.com",
  projectId: "gcp-clone-e980f",
  storageBucket: "gcp-clone-e980f.firebasestorage.app",
  messagingSenderId: "542436036899",
  appId: "1:542436036899:web:8aba89c38f941311fdfc96"
};
console.log("Firebase API Key:", process.env.REACT_APP_FIREBASE_API_KEY);
const app = initializeApp(firebaseConfig);
export const auth = getAuth();
export const provider = new GoogleAuthProvider();

export default app;
