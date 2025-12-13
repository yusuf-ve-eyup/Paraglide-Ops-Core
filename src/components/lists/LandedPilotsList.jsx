import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Clock } from 'lucide-react';

const LandedPilotsList = () => {
    const pilots = useRaceStore((state) => state.pilots);

    const landedPilots = pilots
        .filter((p) => p.status === 'landed')
        .sort((a, b) => new Date(a.lastStatusUpdate).getTime() - new Date(b.lastStatusUpdate).getTime());

    const getTimeSince = (dateString) => {
        const diff = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(diff / 60000);
        return `${mins}m`;
    };

    return (
        <div className="flex flex-col h-full bg-red-50 border-r border-red-200">
            <div className="p-4 bg-red-100 border-b border-red-200 flex justify-between items-center">
                <h2 className="font-bold text-red-800">Landed Queue (Red)</h2>
                <span className="bg-red-600 text-white text-xs px-2 py-1 rounded-full">{landedPilots.length}</span>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-2">
                {landedPilots.map((pilot) => (
                    <div key={pilot.id} className="bg-white p-3 rounded shadow-sm border-l-4 border-red-500 flex justify-between items-center">
                        <div>
                            <p className="font-semibold text-gray-800">{pilot.nameSurname}</p>
                            <p className="text-xs text-gray-500">{pilot.phoneNumber}</p>
                        </div>
                        <div className="flex items-center text-red-600 font-bold text-sm">
                            <Clock size={14} className="mr-1" />
                            {getTimeSince(pilot.lastStatusUpdate)}
                        </div>
                    </div>
                ))}
                {landedPilots.length === 0 && (
                    <p className="text-center text-gray-400 text-sm mt-4">No landed pilots.</p>
                )}
            </div>
        </div>
    );
};

export default LandedPilotsList;
