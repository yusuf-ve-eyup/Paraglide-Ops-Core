import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

/**
 * @typedef {'befFly' | 'flying' | 'landed' | 'waiting' | 'taked'} PilotStatus
 */

/**
 * @typedef {Object} Pilot
 * @property {string} groupId
 * @property {string} id - Unique identifier (Random 6-digit)
 * @property {string} nameSurname
 * @property {string} phoneNumber
 * @property {number} locationX - Latitude
 * @property {number} locationY - Longitude
 * @property {PilotStatus} status
 * @property {number} retrieverId - ID of assigned rescue vehicle (0 if none)
 * @property {string} lastStatusUpdate - ISO String
 */

/**
 * @typedef {Object} Retriever
 * @property {string} groupId
 * @property {string} id - Unique identifier (Random 6-digit)
 * @property {string} nameSurname - Driver name
 * @property {string} phoneNumber
 * @property {number} locationX
 * @property {number} locationY
 * @property {number} taskCount - Active missions count
 */

const generateUniqueId = (existingItems) => {
  let newId;
  let isUnique = false;
  while (!isUnique) {
    newId = Math.floor(100000 + Math.random() * 900000).toString();
    if (!existingItems.some(item => item.id === newId)) {
      isUnique = true;
    }
  }
  return newId;
};

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
        const newId = generateUniqueId(currentGroupPilots);

        const newPilot = {
          ...pilotData,
          groupId: groupId,
          id: newId,
          status: 'befFly',
          locationX: pilotData.locationX || (37.7394308 + (Math.random() - 0.5) * 0.05),
          locationY: pilotData.locationY || (29.0999973 + (Math.random() - 0.5) * 0.05),
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
        set((state) => {
          const targetPilot = state.pilots.find(p => p.id === id && p.groupId === groupId);
          const retrieverId = targetPilot?.retrieverId;

          let newRetrievers = state.retrievers;

          // If status changing to 'taked', decrement task count for assigned retriever
          if (status === 'taked' && retrieverId && retrieverId !== 0 && retrieverId !== "0") {
            newRetrievers = state.retrievers.map(r => {
              if (r.id === retrieverId && r.groupId === groupId) {
                return { ...r, taskCount: Math.max(0, (r.taskCount || 0) - 1) };
              }
              return r;
            });
          }

          return {
            pilots: state.pilots.map((p) =>
              (p.id === id && p.groupId === groupId) ? { ...p, status, wtsc: Date.now() } : p
            ),
            retrievers: newRetrievers
          };
        });

        // Cloud Update
        const { updatePilotStatusInCloud } = await import('../services/raceService');
        // Pass retrieverId explicitly to helper
        const targetPilotForCloud = state.pilots.find(p => p.id === id && p.groupId === groupId);
        updatePilotStatusInCloud(groupId, id, status, targetPilotForCloud?.retrieverId);
      },

      addRetriever: async (retrieverData) => {
        const state = get();
        const groupId = state.groupId;

        const currentGroupRetrievers = state.retrievers.filter(r => r.groupId === groupId);
        const newId = generateUniqueId(currentGroupRetrievers);

        const newRetriever = {
          ...retrieverData,
          groupId: groupId,
          id: newId,
          locationX: retrieverData.locationX || (37.7394308 + (Math.random() - 0.5) * 0.05),
          locationY: retrieverData.locationY || (29.0999973 + (Math.random() - 0.5) * 0.05),
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

      updatePilotRetriever: async (pilotId, retrieverId) => {
        const state = get();
        const groupId = state.groupId;

        // Optimistic Update
        set((state) => ({
          pilots: state.pilots.map((p) =>
            (p.id === pilotId && p.groupId === groupId) ? { ...p, retrieverId } : p
          )
        }));

        // Cloud Update
        const { updatePilotRetrieverInCloud } = await import('../services/raceService');
        updatePilotRetrieverInCloud(groupId, pilotId, retrieverId);
      },

      assignRetrieverToPilot: async (pilotId, retrieverId) => {
        const state = get();
        const groupId = state.groupId;

        // Optimistic Update
        set((state) => ({
          pilots: state.pilots.map((p) =>
            (p.id === pilotId && p.groupId === groupId) ? { ...p, retrieverId, status: 'waiting' } : p
          ),
          retrievers: state.retrievers.map((r) => {
            if (r.id === retrieverId && r.groupId === groupId) {
              return { ...r, taskCount: (r.taskCount || 0) + 1 };
            }
            return r;
          })
        }));

        // Cloud Update
        const { assignRetrieverToPilotInCloud } = await import('../services/raceService');
        assignRetrieverToPilotInCloud(groupId, pilotId, retrieverId);
      },

      // Helper to get next ID for UI display (optional use)
      getNextPilotId: () => "AUTO",
      getNextRetrieverId: () => "AUTO",
    }),
    {
      name: 'race-storage', // name of the item in the storage (must be unique)
      storage: createJSONStorage(() => localStorage), // (optional) by default, 'localStorage' is used
    }
  )
);

export default useRaceStore;
