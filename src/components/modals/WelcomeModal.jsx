import React, { useState } from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Users } from 'lucide-react';

const WelcomeModal = () => {
    const groupId = useRaceStore((state) => state.groupId);
    const setGroupId = useRaceStore((state) => state.setGroupId);
    const [inputValue, setInputValue] = useState('');

    if (groupId) return null; // Don't show if group is set

    const handleJoin = (e) => {
        e.preventDefault();
        if (inputValue.trim()) {
            setGroupId(inputValue.trim());
        }
    };

    const handleCreateNew = () => {
        // Generate a random 4 digit ID or similar
        const newId = Math.floor(1000 + Math.random() * 9000).toString();
        setGroupId(newId);
    };

    return (
        <div className="fixed inset-0 bg-gray-900 bg-opacity-90 flex items-center justify-center z-[2000] backdrop-blur-sm">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-8">
                <div className="text-center mb-8">
                    <div className="bg-blue-100 p-4 rounded-full inline-block mb-4">
                        <Users size={48} className="text-blue-600" />
                    </div>
                    <h1 className="text-2xl font-bold text-gray-800">Welcome to Paraglide Ops</h1>
                    <p className="text-gray-500 mt-2">Please join a group or create a new one to start.</p>
                </div>

                <div className="space-y-6">
                    <form onSubmit={handleJoin} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Join Existing Group</label>
                            <input
                                type="text"
                                value={inputValue}
                                onChange={(e) => setInputValue(e.target.value)}
                                placeholder="Enter Group ID"
                                className="w-full border border-gray-300 p-3 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                            />
                        </div>
                        <button
                            type="submit"
                            disabled={!inputValue.trim()}
                            className="w-full bg-blue-600 text-white p-3 rounded-lg font-bold hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Join Group
                        </button>
                    </form>

                    <div className="relative">
                        <div className="absolute inset-0 flex items-center">
                            <div className="w-full border-t border-gray-300"></div>
                        </div>
                        <div className="relative flex justify-center text-sm">
                            <span className="px-2 bg-white text-gray-500">Or</span>
                        </div>
                    </div>

                    <button
                        onClick={handleCreateNew}
                        className="w-full bg-gray-100 text-gray-800 p-3 rounded-lg font-bold hover:bg-gray-200 transition border border-gray-300"
                    >
                        Create New Group
                    </button>
                </div>
            </div>
        </div>
    );
};

export default WelcomeModal;
