import React, { useState } from 'react';
import useRaceStore from '../store/useRaceStore';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, PlusCircle, User, Phone } from 'lucide-react';

const PilotManagementPage = () => {
    const navigate = useNavigate();
    const { pilots, addPilot, getNextPilotId } = useRaceStore();
    const nextId = getNextPilotId();

    const [formData, setFormData] = useState({
        nameSurname: '',
        phoneNumber: '',
    });

    const handleSubmit = (e) => {
        e.preventDefault();
        addPilot({
            nameSurname: formData.nameSurname,
            phoneNumber: formData.phoneNumber,
            locationX: 36.5 + (Math.random() * 0.1), // Mock Location
            locationY: 29.1 + (Math.random() * 0.1),
            status: 'befFly', // Default status
        });
        // Clear form
        setFormData({ nameSurname: '', phoneNumber: '' });
    };

    return (
        <div className="h-screen w-screen grid grid-cols-1 md:grid-cols-2 bg-gray-50">
            {/* LEFT SIDE: LIST */}
            <div className="h-full overflow-hidden flex flex-col border-r border-gray-200 bg-white">
                <div className="p-4 border-b border-gray-200 flex items-center justify-between bg-gray-100">
                    <button onClick={() => navigate('/')} className="text-gray-600 hover:text-gray-900 flex items-center">
                        <ArrowLeft size={20} className="mr-2" /> Back
                    </button>
                    <h2 className="text-lg font-bold text-gray-800">Active Pilots ({pilots.length})</h2>
                </div>
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {pilots.map((pilot) => (
                        <div key={pilot.id} className="p-4 bg-white border border-gray-200 rounded shadow-sm hover:shadow-md transition flex justify-between items-center group">
                            <div className="flex items-center gap-3">
                                <div className="bg-blue-100 p-2 rounded-full text-blue-600 font-bold">
                                    {pilot.id}
                                </div>
                                <div>
                                    <h3 className="font-bold text-gray-800">{pilot.nameSurname}</h3>
                                    <p className="text-sm text-gray-500 flex items-center">
                                        <Phone size={12} className="mr-1" /> {pilot.phoneNumber}
                                    </p>
                                </div>
                            </div>
                            <span className={`px-2 py-1 rounded text-xs uppercase font-bold 
                                ${pilot.status === 'landed' ? 'bg-red-100 text-red-600' :
                                    pilot.status === 'flying' ? 'bg-blue-100 text-blue-600' : 'bg-gray-100 text-gray-600'}`}>
                                {pilot.status}
                            </span>
                        </div>
                    ))}
                    {pilots.length === 0 && <p className="text-center text-gray-400 mt-10">No pilots found.</p>}
                </div>
            </div>

            {/* RIGHT SIDE: ADD FORM */}
            <div className="h-full flex items-center justify-center p-8 bg-gray-50">
                <div className="bg-white p-8 rounded-xl shadow-xl w-full max-w-md border border-gray-200">
                    <div className="flex items-center gap-3 mb-6 border-b pb-4">
                        <div className="bg-blue-600 text-white p-3 rounded-lg shadow-lg">
                            <PlusCircle size={32} />
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold text-gray-800">Add Project Pilot</h1>
                            <p className="text-gray-500 text-sm">Create new pilot entry</p>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg flex justify-between items-center">
                            <span className="text-blue-800 font-medium">Auto-Assigned ID</span>
                            <span className="text-2xl font-bold text-blue-700 font-mono tracking-wider">{nextId}</span>
                        </div>

                        <div>
                            <label className="block text-sm font-semibold text-gray-700 mb-2">Full Name</label>
                            <div className="relative">
                                <User className="absolute left-3 top-3 text-gray-400" size={18} />
                                <input
                                    type="text"
                                    required
                                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                                    placeholder="John Doe"
                                    value={formData.nameSurname}
                                    onChange={(e) => setFormData({ ...formData, nameSurname: e.target.value })}
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-semibold text-gray-700 mb-2">Phone Number</label>
                            <div className="relative">
                                <Phone className="absolute left-3 top-3 text-gray-400" size={18} />
                                <input
                                    type="tel"
                                    required
                                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                                    placeholder="+1 234 567 890"
                                    value={formData.phoneNumber}
                                    onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                                />
                            </div>
                        </div>

                        <button
                            type="submit"
                            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-lg shadow-md hover:shadow-lg transform active:scale-95 transition-all flex items-center justify-center gap-2"
                        >
                            <PlusCircle size={20} /> Add Pilot
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default PilotManagementPage;
