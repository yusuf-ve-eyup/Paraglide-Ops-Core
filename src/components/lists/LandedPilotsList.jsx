import React from 'react';
import useRaceStore from '../../store/useRaceStore';
import { Clock } from 'lucide-react';

const LandedPilotsList = () => {
    const pilots = useRaceStore((state) => state.pilots);
    const retrievers = useRaceStore((state) => state.retrievers);
    const assignRetrieverToPilot = useRaceStore((state) => state.assignRetrieverToPilot);

    // Local state to track pending assignments: { [pilotId]: retrieverId }
    const [pendingAssignments, setPendingAssignments] = React.useState({});

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
        // If we have a pending change, show that
        if (pendingAssignments[pilot.id]) {
            return pendingAssignments[pilot.id];
        }

        // Otherwise show existing or calculate default
        if (pilot.retrieverId && pilot.retrieverId !== 0 && pilot.retrieverId !== "0") {
            return pilot.retrieverId;
        }

        // Find nearest default
        let nearestId = "";
        let minDist = Infinity;

        retrievers.forEach(r => {
            const dist = calculateDistance(pilot.locationX, pilot.locationY, r.locationX, r.locationY);
            if (dist < minDist) {
                minDist = dist;
                nearestId = r.id;
            }
        });
        return nearestId;
    };

    const handleVehicleChange = (pilotId, e) => {
        const newRetrieverId = e.target.value;
        setPendingAssignments(prev => ({ ...prev, [pilotId]: newRetrieverId }));
    };

    const handleConfirm = (pilot) => {
        const selectedId = getOptimalRetrieverId(pilot);
        assignRetrieverToPilot(pilot.id, selectedId);
        // Clear pending for this pilot
        setPendingAssignments(prev => {
            const newState = { ...prev };
            delete newState[pilot.id];
            return newState;
        });
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
                    const isPending = !!pendingAssignments[pilot.id];
                    // Also consider "pending" if it's the first auto-calculation but not saved yet?
                    // The user wants "Onayla" button. 
                    // If pilot.retrieverId is missing/0, it means it's not confirmed yet, even if we show a default.
                    const isConfirmed = pilot.retrieverId && pilot.retrieverId !== 0 && pilot.retrieverId !== "0";
                    const showConfirmButton = isPending || !isConfirmed;

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
                                <div className="flex gap-1">
                                    <select
                                        className="flex-1 text-sm border-gray-300 rounded border p-1"
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
                                    {showConfirmButton && (
                                        <button
                                            onClick={() => handleConfirm(pilot)}
                                            className="bg-green-600 text-white text-xs px-2 py-1 rounded hover:bg-green-700"
                                        >
                                            Onayla
                                        </button>
                                    )}
                                </div>
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
