import React from 'react';
import FlyingList from '../lists/FlyingList';
import TimeoutList from '../lists/TimeoutList';

const BottomPanel = () => {
    return (
        <div className="h-full grid grid-cols-2 shadow-inner">
            <div className="h-full overflow-hidden">
                <FlyingList />
            </div>
            <div className="h-full overflow-hidden">
                <TimeoutList />
            </div>
        </div>
    );
};

export default BottomPanel;
