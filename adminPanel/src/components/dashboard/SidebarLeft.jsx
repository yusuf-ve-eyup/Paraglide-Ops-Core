import React from 'react';
import LandedPilotsList from '../lists/LandedPilotsList';
import ActiveRetrieversList from '../lists/ActiveRetrieversList';

const SidebarLeft = () => {
    return (
        <div className="h-full grid grid-rows-2 shadow-xl z-20">
            {/* Top Half: Landed Pilots */}
            <div className="h-full overflow-hidden">
                <LandedPilotsList />
            </div>

            {/* Bottom Half: Active Retrievers */}
            <div className="h-full overflow-hidden">
                <ActiveRetrieversList />
            </div>
        </div>
    );
};

export default SidebarLeft;
