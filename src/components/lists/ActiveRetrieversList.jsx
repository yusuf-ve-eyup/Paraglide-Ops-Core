import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Truck } from 'lucide-react';

const ActiveRetrieversList = () => {
    const retrievers = useRaceStore((state) => state.retrievers);

    // Filter only those that might be considered "Active" if needed, 
    // or just list all with their task counts as per request.
    // Assuming list all for now, or maybe only those with taskCount > 0?
    // Request said: "Lists vehicles currently on mission." -> taskCount > 0
    const activeRetrievers = retrievers.filter(r => r.taskCount > 0);

    return (
        <div className="flex flex-col h-full bg-gray-50 border-t border-gray-200">
            <div className="p-4 bg-gray-100 border-b border-gray-200 flex justify-between items-center">
                <h2 className="font-bold text-gray-700">Active Retrievers</h2>
                <span className="bg-blue-600 text-white text-xs px-2 py-1 rounded-full">{activeRetrievers.length}</span>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-2">
                {activeRetrievers.map((retriever) => (
                    <div key={retriever.id} className="bg-white p-3 rounded shadow-sm border border-gray-200 flex justify-between items-center">
                        <div className="flex items-center">
                            <div className="bg-blue-100 p-2 rounded-full mr-3">
                                <Truck size={16} className="text-blue-600" />
                            </div>
                            <div>
                                <p className="font-semibold text-gray-800">{retriever.nameSurname}</p>
                                <p className="text-xs text-gray-500">{retriever.phoneNumber}</p>
                            </div>
                        </div>
                        <div className="flex flex-col items-end">
                            <span className="text-xs font-bold text-gray-500 uppercase">Tasks</span>
                            <span className="text-lg font-bold text-blue-600">{retriever.taskCount}</span>
                        </div>
                    </div>
                ))}
                {activeRetrievers.length === 0 && (
                    <p className="text-center text-gray-400 text-sm mt-4">No active retrievers.</p>
                )}
            </div>
        </div>
    );
};

export default ActiveRetrieversList;
