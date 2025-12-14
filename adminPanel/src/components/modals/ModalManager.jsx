import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { X } from 'lucide-react';

const ModalOverlay = ({ title, onClose, children }) => (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg shadow-xl w-96 overflow-hidden">
            <div className="flex justify-between items-center bg-gray-100 p-3 border-b">
                <h3 className="font-bold text-gray-700">{title}</h3>
                <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
                    <X size={20} />
                </button>
            </div>
            <div className="p-4">
                {children}
            </div>
        </div>
    </div>
);

export const MonitorModals = () => {
    // Ideally this state would be in a store or local state lifted up
    // For this architecture without a specific UI store, we might keep it local or assumes a "isModalOpen" in store.
    // However, the prompt mentioned "ModalManager". I will implement a simple local manager or assumes usage inside Dashboard.
    // Let's assume we need a way to open them. I will add a floating action button or similar to Dashboard to trigger these for testing.
    // But for strict adherence, I'll export the components to be used.
    return null;
};

export const AddPilotModal = ({ isOpen, onClose }) => {
    const addPilot = useRaceStore(state => state.addPilot);
    const getNextPilotId = useRaceStore(state => state.getNextPilotId);
    const nextId = getNextPilotId();

    const handleSubmit = (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        addPilot({
            groupId: 'Default',
            // id is auto-generated in store
            nameSurname: formData.get('nameSurname'),
            phoneNumber: formData.get('phoneNumber'),
            locationX: 36.6 + (Math.random() * 0.1), // Mock
            locationY: 29.2 + (Math.random() * 0.1),
            status: 'befFly',
            lastStatusUpdate: new Date().toISOString()
        });
        onClose();
    };

    if (!isOpen) return null;

    return (
        <ModalOverlay title="Add New Pilot" onClose={onClose}>
            <form onSubmit={handleSubmit} className="space-y-3">
                <div className="bg-blue-50 p-2 rounded text-sm text-blue-800 mb-2">
                    Auto-assigning ID: <strong>{nextId}</strong>
                </div>
                <input name="nameSurname" placeholder="Name Surname" className="w-full border p-2 rounded" required />
                <input name="phoneNumber" placeholder="Phone Number" className="w-full border p-2 rounded" required />
                <button type="submit" className="w-full bg-blue-600 text-white p-2 rounded font-bold hover:bg-blue-700">Add Pilot</button>
            </form>
        </ModalOverlay>
    );
};

export const AddRetrieverModal = ({ isOpen, onClose }) => {
    const addRetriever = useRaceStore(state => state.addRetriever);
    const getNextRetrieverId = useRaceStore(state => state.getNextRetrieverId);
    const nextId = getNextRetrieverId();

    const handleSubmit = (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        addRetriever({
            groupId: 'Default',
            // id is auto-generated
            nameSurname: formData.get('nameSurname'),
            phoneNumber: formData.get('phoneNumber'),
            locationX: 36.6 + (Math.random() * 0.1),
            locationY: 29.2 + (Math.random() * 0.1),
            taskCount: 0
        });
        onClose();
    };

    if (!isOpen) return null;

    return (
        <ModalOverlay title="Add Retriever" onClose={onClose}>
            <form onSubmit={handleSubmit} className="space-y-3">
                <div className="bg-green-50 p-2 rounded text-sm text-green-800 mb-2">
                    Auto-assigning ID: <strong>{nextId}</strong>
                </div>
                <input name="nameSurname" placeholder="Driver Name" className="w-full border p-2 rounded" required />
                <input name="phoneNumber" placeholder="Phone Number" className="w-full border p-2 rounded" required />
                <button type="submit" className="w-full bg-green-600 text-white p-2 rounded font-bold hover:bg-green-700">Add Retriever</button>
            </form>
        </ModalOverlay>
    );
};
