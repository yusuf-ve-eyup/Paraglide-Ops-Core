import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Plane } from 'lucide-react';

const FlyingList = () => {
    const pilots = useRaceStore((state) => state.pilots);
    const flyingPilots = pilots.filter((p) => p.status === 'flying');

    return (
        <div className="h-full bg-blue-50 border-r border-blue-100 flex flex-col">
            <div className="p-2 border-b border-blue-200 flex justify-between items-center bg-blue-100">
                <h3 className="font-bold text-blue-900 text-sm flex items-center">
                    <Plane size={14} className="mr-2" />
                    Flying
                </h3>
                <span className="bg-blue-600 text-white text-xs px-2 py-0.5 rounded-full">{flyingPilots.length}</span>
            </div>
            <div className="flex-1 overflow-y-auto p-2">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
                    {flyingPilots.map((pilot) => (
                        <div key={pilot.id} className="bg-white p-2 rounded shadow-sm text-sm border-l-2 border-blue-400">
                            <span className="font-semibold">{pilot.nameSurname}</span>
                            <span className="text-gray-400 text-xs ml-2">{pilot.id}</span>
                        </div>
                    ))}
                    {flyingPilots.length === 0 && <p className="text-gray-400 text-xs w-full text-center py-2">No pilots flying.</p>}
                </div>
            </div>
        </div>
    );
};

export default FlyingList;
