import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import SidebarLeft from '../components/dashboard/SidebarLeft';
import BottomPanel from '../components/dashboard/BottomPanel';
import MapWidget from '../components/dashboard/MapWidget';
import WelcomeModal from '../components/modals/WelcomeModal';
import SettingsModal from '../components/modals/SettingsModal';
import { PlusCircle, Truck, Settings } from 'lucide-react';

const Dashboard = () => {
    const navigate = useNavigate();
    const [isSettingsModalOpen, setSettingsModalOpen] = useState(false);

    return (
        <div className="h-screen w-screen grid grid-cols-12 grid-rows-6 overflow-hidden relative">
            {/* --- MODALLAR --- */}
            {/* Giriş Modalı (Otomatik açılır) */}
            <WelcomeModal />

            {/* Ayarlar Modalı */}
            <SettingsModal
                isOpen={isSettingsModalOpen}
                onClose={() => setSettingsModalOpen(false)}
            />

            {/* --- SAĞ ÜST BUTON GRUBU --- */}
            <div className="absolute top-4 right-4 z-[1000] flex space-x-2 bg-white/80 p-1 rounded-lg backdrop-blur-sm shadow-md">
                <button
                    onClick={() => setSettingsModalOpen(true)}
                    className="bg-gray-700 hover:bg-gray-800 text-white p-2 rounded transition-colors"
                    title="Ayarlar"
                >
                    <Settings size={20} />
                </button>

                <div className="w-px bg-gray-300 mx-1 h-auto my-1"></div>

                <button
                    onClick={() => navigate('/pilots')}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded flex items-center gap-2 transition-colors"
                >
                    <PlusCircle size={18} />
                    <span className="font-semibold text-sm">Pilot Ekle</span>
                </button>

                <button
                    onClick={() => navigate('/vehicles')}
                    className="bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded flex items-center gap-2 transition-colors"
                >
                    <Truck size={18} />
                    <span className="font-semibold text-sm">Araç Ekle</span>
                </button>
            </div>

            {/* --- SOL PANEL (Rescue Queue) --- */}
            {/* 3 sütun genişliğinde, tam yükseklik */}
            <div className="col-span-3 row-span-6 border-r border-gray-300 shadow-xl z-10 bg-white">
                <SidebarLeft />
            </div>

            {/* --- ORTA PANEL (Harita) --- */}
            {/* 9 sütun genişliğinde, üstteki 4 satır */}
            <div className="col-span-9 row-span-4 bg-gray-100 relative z-0">
                <MapWidget />
            </div>

            {/* --- ALT PANEL (Uçanlar & Timeout) --- */}
            {/* 9 sütun genişliğinde, alttaki 2 satır */}
            <div className="col-span-9 row-span-2 border-t border-gray-300 z-10 bg-white">
                <BottomPanel />
            </div>
        </div>
    );
};

export default Dashboard;