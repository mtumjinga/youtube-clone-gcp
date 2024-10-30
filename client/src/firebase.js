import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: "clone-59a2e.firebaseapp.com",
  projectId: "clone-59a2e",
  storageBucket: "clone-59a2e.appspot.com",
  messagingSenderId: "510132767380",
  appId: "1:510132767380:web:9963ad58a8f85f3219c281",
};
const app = initializeApp(firebaseConfig);
export const auth = getAuth();
export const provider = new GoogleAuthProvider();

export default app;
