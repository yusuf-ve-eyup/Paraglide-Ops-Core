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
      setGroupId: (id) => set({ groupId: id }),

      leaveGroup: () => set({ groupId: null }), // Reset group ID to trigger WelcomeModal

      addPilot: (pilotData) => set((state) => {
        const currentGroupPilots = state.pilots.filter(p => p.groupId === state.groupId);
        // Find max ID in current group. Assumes IDs are numeric strings "1", "2", etc.
        const maxId = currentGroupPilots.reduce((max, p) => Math.max(max, parseInt(p.id) || 0), 0);
        const newId = (maxId + 1).toString();

        const newPilot = {
          ...pilotData,
          groupId: state.groupId,
          id: newId,
          status: 'befFly',
          lastStatusUpdate: new Date().toISOString()
        };

        return { pilots: [...state.pilots, newPilot] };
      }),

      updatePilotStatus: (id, status) => set((state) => ({
        pilots: state.pilots.map((p) =>
          (p.id === id && p.groupId === state.groupId) ? { ...p, status, lastStatusUpdate: new Date().toISOString() } : p
        )
      })),

      addRetriever: (retrieverData) => set((state) => {
        const currentGroupRetrievers = state.retrievers.filter(r => r.groupId === state.groupId);
        const maxId = currentGroupRetrievers.reduce((max, r) => Math.max(max, parseInt(r.id) || 0), 0);
        const newId = (maxId + 1).toString();

        const newRetriever = {
          ...retrieverData,
          groupId: state.groupId,
          id: newId,
        };

        return { retrievers: [...state.retrievers, newRetriever] };
      }),

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
