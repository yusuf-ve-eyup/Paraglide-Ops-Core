import React, { useState } from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Settings, LogOut, Trash2, X } from 'lucide-react';

const SettingsModal = ({ isOpen, onClose }) => {
    const leaveGroup = useRaceStore(state => state.leaveGroup);
    const groupId = useRaceStore(state => state.groupId);

    const handleLeave = () => {
        if (confirm('Are you sure you want to leave this group? You can join back later with the ID.')) {
            leaveGroup();
            onClose(); // useful if logic changes, but WelcomeModal usually takes over
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[1500]">
            <div className="bg-white rounded-lg shadow-xl w-96 overflow-hidden">
                <div className="flex justify-between items-center bg-gray-100 p-3 border-b">
                    <h3 className="font-bold text-gray-700 flex items-center">
                        <Settings size={18} className="mr-2" /> Settings
                    </h3>
                    <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
                        <X size={20} />
                    </button>
                </div>

                <div className="p-4 space-y-4">
                    <div className="bg-gray-50 p-3 rounded border">
                        <p className="text-xs text-gray-500 uppercase font-bold">Current Group ID</p>
                        <p className="text-xl font-mono text-gray-800">{groupId}</p>
                    </div>

                    <button
                        onClick={handleLeave}
                        className="w-full flex items-center justify-center bg-red-100 text-red-700 p-3 rounded font-bold hover:bg-red-200 transition"
                    >
                        <LogOut size={18} className="mr-2" /> Leave Group
                    </button>

                    <p className="text-xs text-gray-400 text-center">
                        Leaving the group will return you to the welcome screen. Your data is saved locally.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default SettingsModal;
