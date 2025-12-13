import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Clock } from 'lucide-react';

const LandedPilotsList = () => {
    const pilots = useRaceStore((state) => state.pilots);
    const retrievers = useRaceStore((state) => state.retrievers);
    const updatePilotRetriever = useRaceStore((state) => state.updatePilotRetriever);

    const landedPilots = pilots
        .filter((p) => p.status === 'landed')
        .sort((a, b) => new Date(a.wtsc).getTime() - new Date(b.wtsc).getTime());

    const getTimeSince = (dateString) => {
        const diff = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(diff / 60000);
        return `${mins}m`;
    };

    // Haversine Distance Calculation (km)
    const calculateDistance = (lat1, lon1, lat2, lon2) => {
        if (!lat1 || !lon1 || !lat2 || !lon2) return Infinity;
        const R = 6371; // Radius of the earth in km
        const dLat = (lat2 - lat1) * (Math.PI / 180);
        const dLon = (lon2 - lon1) * (Math.PI / 180);
        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c; // Distance in km
    };

    const getOptimalRetrieverId = (pilot) => {
        if (pilot.retrieverId && pilot.retrieverId !== 0 && pilot.retrieverId !== "0") {
            return pilot.retrieverId;
        }

        // Find nearest
        let nearestId = "";
        let minDist = Infinity;

        retrievers.forEach(r => {
            const dist = calculateDistance(pilot.locationX, pilot.locationY, r.locationX, r.locationY);
            if (dist < minDist) {
                minDist = dist;
                nearestId = r.id;
            }
        });

        // Use a timeout/effect to save this "auto-selection" to the DB? 
        // The user asked for "selected by default". 
        // If we just show it as selected in the UI without saving to DB, that's "default selection".
        // Saving it automatically might be aggressive, but ensures consistency. 
        // For now, let's just RETURN it for the UI value so it LOOKS selected. 
        // If the user confirms/changes, updates happen. 
        // Actually, let's strictly follow: "default olarak en yakın mesafedeki araç seçili gelmeli"
        return nearestId;
    };

    const handleVehicleChange = (pilotId, e) => {
        const newRetrieverId = e.target.value;
        updatePilotRetriever(pilotId, newRetrieverId);
    };

    return (
        <div className="flex flex-col h-full bg-red-50 border-r border-red-200">
            <div className="p-4 bg-red-100 border-b border-red-200 flex justify-between items-center">
                <h2 className="font-bold text-red-800">Landed Queue (Red)</h2>
                <span className="bg-red-600 text-white text-xs px-2 py-1 rounded-full">{landedPilots.length}</span>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-2">
                {landedPilots.map((pilot) => {
                    const selectedRetrieverId = getOptimalRetrieverId(pilot);

                    return (
                        <div key={pilot.id} className="bg-white p-3 rounded shadow-sm border-l-4 border-red-500 flex flex-col gap-2">
                            <div className="flex justify-between items-center">
                                <div>
                                    <p className="font-semibold text-gray-800">{pilot.nameSurname}</p>
                                    <p className="text-xs text-gray-500">{pilot.phoneNumber}</p>
                                </div>
                                <div className="flex items-center text-red-600 font-bold text-sm">
                                    <Clock size={14} className="mr-1" />
                                    {getTimeSince(pilot.wtsc)}
                                </div>
                            </div>

                            {/* Vehicle Assignment */}
                            <div className="mt-1">
                                <label className="text-xs text-gray-500 font-bold mb-1 block">Pick Up Vehicle:</label>
                                <select
                                    className="w-full text-sm border-gray-300 rounded border p-1"
                                    value={selectedRetrieverId || ""}
                                    onChange={(e) => handleVehicleChange(pilot.id, e)}
                                >
                                    <option value="" disabled>Select Vehicle...</option>
                                    {retrievers.map(r => (
                                        <option key={r.id} value={r.id}>
                                            {r.nameSurname} ({calculateDistance(pilot.locationX, pilot.locationY, r.locationX, r.locationY).toFixed(1)} km)
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    )
                })}
                {landedPilots.length === 0 && (
                    <p className="text-center text-gray-400 text-sm mt-4">No landed pilots.</p>
                )}
            </div>
        </div>
    );
};

export default LandedPilotsList;
