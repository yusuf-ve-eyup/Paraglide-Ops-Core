// src/services/firebaseConfig.js
import { initializeApp } from "firebase/app";
import { getDatabase } from "firebase/database";


// Firebase konsolundan aldığın "firebaseConfig" nesnesini buraya yapıştır.
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {

    apiKey: "placeholder",

    authDomain: "placeholder",

    databaseURL: "placeholder",

    projectId: "placeholder",

    storageBucket: "placeholder",

    messagingSenderId: "placeholder",

    appId: "placeholder",

};

const app = initializeApp(firebaseConfig);
export const db = getDatabase(app);