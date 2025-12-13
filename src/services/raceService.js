// src/services/raceService.js
import { ref, get, set, child, update, serverTimestamp, onValue } from "firebase/database";
import { db } from "./firebaseConfig";

// --- GROUP MANAGEMENT ---

// 1. Join Existing Group
export const joinRaceGroup = async (groupId) => {
    const dbRef = ref(db);
    try {
        // Strict Check: Does 'groups/{groupId}' exist?
        const snapshot = await get(child(dbRef, `groups/${groupId}`));

        if (snapshot.exists()) {
            return { success: true, message: "Giriş başarılı." };
        } else {
            return { success: false, message: "Böyle bir oda (Grup) bulunamadı!" };
        }
    } catch (error) {
        console.error("Join Error:", error);
        return { success: false, message: "Sunucu hatası: " + error.message };
    }
};

// 2. Create New Group
export const createRaceGroup = async (groupId) => {
    const dbRef = ref(db);
    try {
        // Check if already exists
        const snapshot = await get(child(dbRef, `groups/${groupId}`));

        if (snapshot.exists()) {
            return { success: false, message: "Bu isimde bir grup zaten var! Katılmayı deneyin." };
        }

        // Create the Group explicitly
        await set(ref(db, `groups/${groupId}`), {
            createdAt: serverTimestamp(), // Use server timestamp
            createdBy: "admin", // Placeholder
            isActive: true
        });

        return { success: true, message: "Grup başarıyla oluşturuldu." };

    } catch (error) {
        console.error("Create Error:", error);
        return { success: false, message: "Oluşturma hatası: " + error.message };
    }
};

// --- DATA LISTENER ---

export const listenToGroupData = (groupId, onDataChange) => {
    // Listen directly to the Group's sub-nodes
    const pilotsRef = ref(db, `groups/${groupId}/pilots`);
    const retrieversRef = ref(db, `groups/${groupId}/retrievers`);

    // Listen to Pilots
    const unsubscribePilots = onValue(pilotsRef, (snapshot) => {
        const data = snapshot.val() || {};
        const pilotsArray = Object.values(data);
        onDataChange('pilots', pilotsArray);
    });

    // Listen to Retrievers
    const unsubscribeRetrievers = onValue(retrieversRef, (snapshot) => {
        const data = snapshot.val() || {};
        const retrieversArray = Object.values(data);
        onDataChange('retrievers', retrieversArray);
    });

    return () => {
        unsubscribePilots();
        unsubscribeRetrievers();
    };
};

// --- ADD / UPDATE ACTIONS ---

// Add Pilot (Nested under groups/{groupId}/pilots)
export const addPilotToCloud = async (groupId, pilotData) => {
    try {
        const pilotRef = ref(db, `groups/${groupId}/pilots/${pilotData.id}`);
        const data = {
            ...pilotData,
            retrieverId: pilotData.retrieverId || 0, // Ensure it exists
            wtsc: serverTimestamp()
        };
        await set(pilotRef, data);
        return { success: true };
    } catch (error) {
        console.error("Add Pilot Error:", error);
        return { success: false, error };
    }
};

// Update Pilot
export const updatePilotStatusInCloud = async (groupId, pilotId, newStatus) => {
    try {
        const updates = {};
        updates[`groups/${groupId}/pilots/${pilotId}/status`] = newStatus;
        updates[`groups/${groupId}/pilots/${pilotId}/wtsc`] = serverTimestamp();

        await update(ref(db), updates);
        return { success: true };
    } catch (error) {
        console.error("Update Pilot Error:", error);
        return { success: false, error };
    }
};

// Add Retriever (Nested under groups/{groupId}/retrievers)
export const addRetrieverToCloud = async (groupId, retrieverData) => {
    try {
        const retrieverRef = ref(db, `groups/${groupId}/retrievers/${retrieverData.id}`);
        const data = {
            ...retrieverData,
            timeStamp: serverTimestamp()
        };
        await set(retrieverRef, data);
        return { success: true };
    } catch (error) {
        console.error("Add Retriever Error:", error);
        return { success: false, error };
    }
};

// Update Pilot's Retriever
export const updatePilotRetrieverInCloud = async (groupId, pilotId, retrieverId) => {
    try {
        const updates = {};
        updates[`groups/${groupId}/pilots/${pilotId}/retrieverId`] = retrieverId;
        // Optional: Update timestamp if needed, but maybe not for just assignment? 
        // Let's keep wtsc as "last STATUS change". If assignment isn't a status change, maybe don't touch wtsc.

        await update(ref(db), updates);
        return { success: true };
    } catch (error) {
        console.error("Update Retriever Error:", error);
        return { success: false, error };
    }
};