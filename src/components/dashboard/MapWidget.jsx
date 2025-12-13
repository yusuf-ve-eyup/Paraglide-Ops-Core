import React from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import useRaceStore from '../../store/useRaceStore';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix for default marker icons in React Leaflet
// You might need to import marker images usually, but we will use colored divs (L.DivIcon) for custom colors as requested.

const createCustomIcon = (color) => {
    return new L.DivIcon({
        className: 'custom-icon',
        html: `<div style="background-color: ${color}; width: 12px; height: 12px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 4px rgba(0,0,0,0.5);"></div>`,
        iconSize: [12, 12],
        iconAnchor: [6, 6]
    });
};

const MapWidget = () => {
    const { pilots, retrievers } = useRaceStore();

    const landedPilots = pilots.filter(p => p.status === 'landed');
    const waitingPilots = pilots.filter(p => p.status === 'waiting');

    const defaultCenter = [36.6, 29.2]; // Example coordinates (somewhere in Turkey/Oludeniz based on mock data?)

    return (
        <div className="h-full w-full relative z-0">
            <MapContainer center={defaultCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
                <TileLayer
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />

                {/* Landed Pilots - Red */}
                {landedPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('red')}
                    >
                        <Popup>
                            <strong>{pilot.nameSurname}</strong><br />
                            Status: Landed<br />
                            {pilot.phoneNumber}
                        </Popup>
                    </Marker>
                ))}

                {/* Waiting Pilots - Orange */}
                {waitingPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('orange')}
                    >
                        <Popup>
                            <strong>{pilot.nameSurname}</strong><br />
                            Status: Waiting<br />
                            {pilot.phoneNumber}
                        </Popup>
                    </Marker>
                ))}

                {/* Retrievers - Green */}
                {retrievers.map(retriever => (
                    <Marker
                        key={retriever.id}
                        position={[retriever.locationX, retriever.locationY]}
                        icon={createCustomIcon('green')}
                    >
                        <Popup>
                            <strong>{retriever.nameSurname}</strong> (Vehicle)<br />
                            Tasks: {retriever.taskCount}<br />
                            {retriever.phoneNumber}
                        </Popup>
                    </Marker>
                ))}
            </MapContainer>
        </div>
    );
};

export default MapWidget;
