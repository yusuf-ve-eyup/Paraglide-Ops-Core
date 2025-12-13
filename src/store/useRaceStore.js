import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

/**
 * @typedef {'befFly' | 'flying' | 'landed' | 'waiting' | 'taked'} PilotStatus
 */

/**
 * @typedef {Object} Pilot
 * @property {string} groupId
 * @property {string} id - Unique identifier (Auto-inc)
 * @property {string} nameSurname
 * @property {string} phoneNumber
 * @property {number} locationX - Latitude
 * @property {number} locationY - Longitude
 * @property {PilotStatus} status
 * @property {string} lastStatusUpdate - ISO String
 */

/**
 * @typedef {Object} Retriever
 * @property {string} groupId
 * @property {string} id - Unique identifier (Auto-inc)
 * @property {string} nameSurname - Driver name
 * @property {string} phoneNumber
 * @property {number} locationX
 * @property {number} locationY
 * @property {number} taskCount - Active missions count
 */

const useRaceStore = create(
  persist(
    (set, get) => ({
      groupId: null,
      pilots: [],
      retrievers: [],

      // Actions
      setGroupId: (id) => {
        set({ groupId: id });
        // Trigger subscription if ID is set
        get().subscribeToGroup(id);
      },

      unsubscribe: null, // Store cleanup function

      subscribeToGroup: async (groupId) => {
        const state = get();
        if (state.unsubscribe) {
          state.unsubscribe(); // Cleanup previous listener
        }

        if (!groupId) return;

        const { listenToGroupData } = await import('../services/raceService');

        const cleanup = listenToGroupData(groupId, (type, data) => {
          if (type === 'pilots') set({ pilots: data });
          if (type === 'retrievers') set({ retrievers: data });
        });

        set({ unsubscribe: cleanup });
      },

      leaveGroup: () => {
        const state = get();
        if (state.unsubscribe) state.unsubscribe();
        set({ groupId: null, unsubscribe: null, pilots: [], retrievers: [] });
      },

      addPilot: async (pilotData) => {
        // Calculate State First (Optimistic or wait for DB? For now, let's calculate ID locally or let User decide? 
        // Current logic uses local Auto-ID.
        // We will call the cloud first, if success, update local.
        const state = get();
        const groupId = state.groupId;

        // Calculate new ID
        const currentGroupPilots = state.pilots.filter(p => p.groupId === groupId);
        const maxId = currentGroupPilots.reduce((max, p) => Math.max(max, parseInt(p.id) || 0), 0);
        const newId = (maxId + 1).toString();

        const newPilot = {
          ...pilotData,
          groupId: groupId,
          id: newId,
          status: 'befFly',
          // wtsc will be set by server, but for local UI immediate feedback:
          wtsc: Date.now()
        };

        // Update Local immediately (Optimistic UI)
        set((state) => ({ pilots: [...state.pilots, newPilot] }));

        // Push to Cloud
        // Dynamic import to avoid cycles or simple import at top
        const { addPilotToCloud } = await import('../services/raceService');
        addPilotToCloud(groupId, newPilot);
      },

      updatePilotStatus: async (id, status) => {
        const state = get();
        const groupId = state.groupId;

        // Optimistic Local Update
        set((state) => ({
          pilots: state.pilots.map((p) =>
            (p.id === id && p.groupId === groupId) ? { ...p, status, wtsc: Date.now() } : p
          )
        }));

        // Cloud Update
        const { updatePilotStatusInCloud } = await import('../services/raceService');
        updatePilotStatusInCloud(groupId, id, status);
      },

      addRetriever: async (retrieverData) => {
        const state = get();
        const groupId = state.groupId;

        const currentGroupRetrievers = state.retrievers.filter(r => r.groupId === groupId);
        const maxId = currentGroupRetrievers.reduce((max, r) => Math.max(max, parseInt(r.id) || 0), 0);
        const newId = (maxId + 1).toString();

        const newRetriever = {
          ...retrieverData,
          groupId: groupId,
          id: newId,
        };

        set((state) => ({ retrievers: [...state.retrievers, newRetriever] }));

        const { addRetrieverToCloud } = await import('../services/raceService');
        addRetrieverToCloud(groupId, newRetriever);
      },

      updateRetrieverTaskCount: (id, count) => set((state) => ({
        retrievers: state.retrievers.map((r) =>
          (r.id === id && r.groupId === state.groupId) ? { ...r, taskCount: count } : r
        )
      })),

      // Helper to get next ID for UI display (optional use)
      getNextPilotId: () => {
        const state = get();
        if (!state.groupId) return "-";
        const currentGroupPilots = state.pilots.filter(p => p.groupId === state.groupId);
        const maxId = currentGroupPilots.reduce((max, p) => Math.max(max, parseInt(p.id) || 0), 0);
        return (maxId + 1).toString();
      },
      getNextRetrieverId: () => {
        const state = get();
        if (!state.groupId) return "-";
        const currentGroupRetrievers = state.retrievers.filter(r => r.groupId === state.groupId);
        const maxId = currentGroupRetrievers.reduce((max, r) => Math.max(max, parseInt(r.id) || 0), 0);
        return (maxId + 1).toString();
      },
    }),
    {
      name: 'race-storage', // name of the item in the storage (must be unique)
      storage: createJSONStorage(() => localStorage), // (optional) by default, 'localStorage' is used
    }
  )
);

export default useRaceStore;
