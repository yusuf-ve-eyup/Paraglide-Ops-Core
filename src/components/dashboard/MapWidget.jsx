import React from 'react';
import { MapContainer, TileLayer, Marker, Popup, Tooltip } from 'react-leaflet'; // 1. Tooltip'i import ettik
import useRaceStore from '../../store/useRaceStore';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// ... İKON OLUŞTURMA FONKSİYONLARIN AYNI KALSIN (createCustomIcon, createVehicleIcon) ...
// (Kod tekrarı olmasın diye o kısımları buraya tekrar yapıştırmıyorum, aynen kullanabilirsin)

const createCustomIcon = (color) => {
    const svgIcon = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="48" height="48" style="filter: drop-shadow(2px 4px 4px rgba(0,0,0,0.5));">
        <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87 3.13-7 7-7z" fill="${color}" stroke="white" stroke-width="1.5"/>
        <circle cx="12" cy="9" r="3" fill="white"/>
    </svg>
    `;

    return new L.DivIcon({
        className: 'custom-pin-icon',
        html: svgIcon,
        iconSize: [48, 48],
        iconAnchor: [24, 48],
        popupAnchor: [0, -48]
    });
};

const createVehicleIcon = (color) => {
    const svgVehicle = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="54" height="54" style="filter: drop-shadow(3px 5px 3px rgba(0,0,0,0.4));">
        <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87 3.13-7 7-7z" fill="${color}" stroke="white" stroke-width="2"/>
        <g transform="translate(6, 4) scale(0.5)"> 
            <path fill="white" d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
        </g>
    </svg>
    `;

    return new L.DivIcon({
        className: 'vehicle-pin-icon',
        html: svgVehicle,
        iconSize: [54, 54],
        iconAnchor: [27, 54],
        popupAnchor: [0, -54]
    });
};

const MapWidget = () => {
    const { pilots, retrievers } = useRaceStore();

    const landedPilots = pilots.filter(p => p.status === 'landed');
    const waitingPilots = pilots.filter(p => p.status === 'waiting');
    const flyingPilots = pilots.filter(p => p.status === 'flying');
    const befFlyPilots = pilots.filter(p => p.status === 'befFly');

    const defaultCenter = [36.55, 29.15];

    return (
        <div className="h-full w-full relative z-0">
            <MapContainer center={defaultCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
                <TileLayer
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />

                {/* Flying Pilots (Blue) */}
                {flyingPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('#4285F4')}
                    >
                        {/* TOOLTIP: Mouse ile üzerine gelince çalışır */}
                        <Tooltip direction="top" offset={[0, -45]} opacity={1}>
                            <span className="font-bold">{pilot.nameSurname} (Uçuyor)</span>
                        </Tooltip>

                        {/* POPUP: Tıklayınca çalışır (Detay bilgi için tutabilirsin) */}
                        <Popup>
                            <div className="text-center">
                                <strong className="text-blue-600">{pilot.nameSurname}</strong><br />
                                <span className="text-xs font-bold text-gray-500">FLYING</span><br />
                                {pilot.phoneNumber}
                            </div>
                        </Popup>
                    </Marker>
                ))}

                {/* Before Flight Pilots (Gray) */}
                {befFlyPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('#9AA0A6')}
                    >
                        <Tooltip direction="top" offset={[0, -45]} opacity={1}>
                            <span className="font-bold">{pilot.nameSurname} (Hazırlık)</span>
                        </Tooltip>
                        <Popup>
                            <div className="text-center">
                                <strong className="text-gray-600">{pilot.nameSurname}</strong><br />
                                <span className="text-xs font-bold text-gray-500">PRE-FLIGHT</span><br />
                                {pilot.phoneNumber}
                            </div>
                        </Popup>
                    </Marker>
                ))}

                {/* Landed Pilots */}
                {landedPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('#EA4335')}
                    >
                        <Tooltip direction="top" offset={[0, -45]} opacity={1}>
                            <span className="font-bold">{pilot.nameSurname} (İndi)</span>
                        </Tooltip>
                        <Popup>
                            <div className="text-center">
                                <strong className="text-red-600">{pilot.nameSurname}</strong><br />
                                <span className="text-xs font-bold text-gray-500">LANDED</span><br />
                                {pilot.phoneNumber}
                            </div>
                        </Popup>
                    </Marker>
                ))}

                {/* Waiting Pilots */}
                {waitingPilots.map(pilot => (
                    <Marker
                        key={pilot.id}
                        position={[pilot.locationX, pilot.locationY]}
                        icon={createCustomIcon('#FF9900')}
                    >
                        <Tooltip direction="top" offset={[0, -45]} opacity={1}>
                            <span className="font-bold">{pilot.nameSurname} (Bekliyor)</span>
                        </Tooltip>
                        <Popup>
                            <div className="text-center">
                                <strong className="text-orange-600">{pilot.nameSurname}</strong><br />
                                <span className="text-xs font-bold text-gray-500">WAITING</span><br />
                                {pilot.phoneNumber}
                            </div>
                        </Popup>
                    </Marker>
                ))}

                {/* RETRIEVERS (ARAÇLAR) */}
                {retrievers.map(retriever => (
                    <Marker
                        key={retriever.id}
                        position={[retriever.locationX, retriever.locationY]}
                        icon={createVehicleIcon('#34A853')}
                    >
                        {/* Araç ikonu biraz daha büyük (54px), o yüzden offset'i biraz daha yukarı aldım (-50) */}
                        <Tooltip direction="top" offset={[0, -50]} opacity={1}>
                            <span className="font-bold">🚙 {retriever.nameSurname}</span>
                        </Tooltip>
                        <Popup>
                            <div className="text-center">
                                <strong className="text-green-600">🚙 {retriever.nameSurname}</strong><br />
                                <span className="text-xs font-bold text-gray-500">VEHICLE</span><br />
                                Görev: {retriever.taskCount}<br />
                                {retriever.phoneNumber}
                            </div>
                        </Popup>
                    </Marker>
                ))}
            </MapContainer>
        </div>
    );
};

export default MapWidget;