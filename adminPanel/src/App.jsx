import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import PilotManagementPage from './pages/PilotManagementPage';
import RetrieverManagementPage from './pages/RetrieverManagementPage';

function App() {
    return (
        <BrowserRouter>
            <div className="App">
                <Routes>
                    <Route path="/" element={<Dashboard />} />
                    <Route path="/pilots" element={<PilotManagementPage />} />
                    <Route path="/vehicles" element={<RetrieverManagementPage />} />
                </Routes>
            </div>
        </BrowserRouter>
    );
}

export default App;
