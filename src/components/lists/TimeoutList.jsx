import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { AlertTriangle } from 'lucide-react';

const TimeoutList = () => {
    const pilots = useRaceStore((state) => state.pilots);

    const timeoutThreshold = 30 * 60 * 1000; // 30 minutes

    const timeoutPilots = pilots.filter((p) => {
        if (p.status !== 'waiting') return false;
        const timeDiff = Date.now() - new Date(p.lastStatusUpdate).getTime();
        return timeDiff > timeoutThreshold;
    });

    const getWaitTime = (dateString) => {
        const diff = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(diff / 60000);
        return `${mins}m`;
    };

    return (
        <div className="h-full bg-orange-50 flex flex-col">
            <div className="p-2 border-b border-orange-200 flex justify-between items-center bg-orange-100">
                <h3 className="font-bold text-orange-900 text-sm flex items-center">
                    <AlertTriangle size={14} className="mr-2" />
                    Timeout Warnings
                </h3>
                <span className="bg-orange-600 text-white text-xs px-2 py-0.5 rounded-full">{timeoutPilots.length}</span>
            </div>
            <div className="flex-1 overflow-y-auto p-2">
                {timeoutPilots.map((pilot) => (
                    <div key={pilot.id} className="bg-white p-2 rounded shadow-sm text-sm border border-orange-300 mb-2 flex justify-between items-center">
                        <div>
                            <span className="font-bold text-red-700">{pilot.nameSurname}</span>
                            <p className="text-xs text-gray-500">Waiting for: {getWaitTime(pilot.lastStatusUpdate)}</p>
                        </div>
                        <button className="bg-red-600 text-white px-2 py-1 rounded text-xs hover:bg-red-700 transition">
                            Escalate
                        </button>
                    </div>
                ))}
                {timeoutPilots.length === 0 && <p className="text-gray-400 text-xs text-center py-2">No timeouts.</p>}
            </div>
        </div>
    );
};

export default TimeoutList;
