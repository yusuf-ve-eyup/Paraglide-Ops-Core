import React, { useState } from 'react';
import SidebarLeft from '../components/dashboard/SidebarLeft';
import BottomPanel from '../components/dashboard/BottomPanel';
import MapWidget from '../components/dashboard/MapWidget';
import { AddPilotModal, AddRetrieverModal } from '../components/modals/ModalManager';
import WelcomeModal from '../components/modals/WelcomeModal';
import SettingsModal from '../components/modals/SettingsModal';
import { PlusCircle, Truck, Settings } from 'lucide-react';

const Dashboard = () => {
    const [isPilotModalOpen, setPilotModalOpen] = useState(false);
    const [isRetrieverModalOpen, setRetrieverModalOpen] = useState(false);
    const [isSettingsModalOpen, setSettingsModalOpen] = useState(false);

    return (
        <div className="h-screen w-screen grid grid-cols-12 grid-rows-6 overflow-hidden relative">
            <WelcomeModal />
            <SettingsModal isOpen={isSettingsModalOpen} onClose={() => setSettingsModalOpen(false)} />

            <AddPilotModal isOpen={isPilotModalOpen} onClose={() => setPilotModalOpen(false)} />
            <AddRetrieverModal isOpen={isRetrieverModalOpen} onClose={() => setRetrieverModalOpen(false)} />

            {/* Floating Action Buttons for Modals */}
            <div className="absolute top-4 right-4 z-[1000] flex space-x-2">
                <button
                    onClick={() => setSettingsModalOpen(true)}
                    className="bg-gray-700 hover:bg-gray-800 text-white px-3 py-2 rounded shadow-lg flex items-center"
                    title="Settings"
                >
                    <Settings size={18} />
                </button>
                <div className="w-px bg-gray-400 mx-2 h-full opacity-50"></div>
                <button
                    onClick={() => setPilotModalOpen(true)}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded shadow-lg flex items-center"
                >
                    <PlusCircle size={18} className="mr-2" /> Add Pilot
                </button>
                <button
                    onClick={() => setRetrieverModalOpen(true)}
                    className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded shadow-lg flex items-center"
                >
                    <Truck size={18} className="mr-2" /> Add Vehicle
                </button>
            </div>

            {/* Zone 1: Left Sidebar (Rescue Queue) */}
            {/* Spans 3 columns, full height */}
            <div className="col-span-3 row-span-6 border-r border-gray-300">
                <SidebarLeft />
            </div>

            {/* Zone 2: Center (Map Zone) */}
            {/* Spans 9 columns, 4 rows (Top 2/3 of remaining space) */}
            <div className="col-span-9 row-span-4 bg-gray-100">
                <MapWidget />
            </div>

            {/* Zone 3: Bottom Panel (Status Monitor) */}
            {/* Spans 9 columns, 2 rows (Bottom 1/3 of remaining space) */}
            <div className="col-span-9 row-span-2 border-t border-gray-300">
                <BottomPanel />
            </div>
        </div>
    );
};

export default Dashboard;
