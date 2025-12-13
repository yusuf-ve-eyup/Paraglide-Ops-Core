import React, { useState } from 'react';
import useRaceStore from '../store/useRaceStore';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Truck, User, Phone } from 'lucide-react';

const RetrieverManagementPage = () => {
    const navigate = useNavigate();
    const { retrievers, addRetriever, getNextRetrieverId } = useRaceStore();
    const nextId = getNextRetrieverId();

    const [formData, setFormData] = useState({
        nameSurname: '',
        phoneNumber: '',
    });

    const handleSubmit = (e) => {
        e.preventDefault();
        addRetriever({
            nameSurname: formData.nameSurname,
            phoneNumber: formData.phoneNumber,
            locationX: 36.5 + (Math.random() * 0.1),
            locationY: 29.1 + (Math.random() * 0.1),
            taskCount: 0,
        });
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
                    <h2 className="text-lg font-bold text-gray-800">Active Retrievers ({retrievers.length})</h2>
                </div>
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {retrievers.map((retriever) => (
                        <div key={retriever.id} className="p-4 bg-white border border-gray-200 rounded shadow-sm hover:shadow-md transition flex justify-between items-center">
                            <div className="flex items-center gap-3">
                                <div className="bg-green-100 p-2 rounded-full text-green-600 font-bold">
                                    {retriever.id}
                                </div>
                                <div>
                                    <h3 className="font-bold text-gray-800">{retriever.nameSurname}</h3>
                                    <p className="text-sm text-gray-500 flex items-center">
                                        <Phone size={12} className="mr-1" /> {retriever.phoneNumber}
                                    </p>
                                </div>
                            </div>
                            <div className="text-right">
                                <div className="text-xs text-gray-400 uppercase font-bold">Tasks</div>
                                <div className="font-mono font-bold text-lg text-green-600">{retriever.taskCount}</div>
                            </div>
                        </div>
                    ))}
                    {retrievers.length === 0 && <p className="text-center text-gray-400 mt-10">No retrievers found.</p>}
                </div>
            </div>

            {/* RIGHT SIDE: ADD FORM */}
            <div className="h-full flex items-center justify-center p-8 bg-gray-50">
                <div className="bg-white p-8 rounded-xl shadow-xl w-full max-w-md border border-gray-200">
                    <div className="flex items-center gap-3 mb-6 border-b pb-4">
                        <div className="bg-green-600 text-white p-3 rounded-lg shadow-lg">
                            <Truck size={32} />
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold text-gray-800">Add Rescue Vehicle</h1>
                            <p className="text-gray-500 text-sm">Register new retrieval vehicle</p>
                        </div>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div className="bg-green-50 border border-green-200 p-4 rounded-lg flex justify-between items-center">
                            <span className="text-green-800 font-medium">Auto-Assigned ID</span>
                            <span className="text-2xl font-bold text-green-700 font-mono tracking-wider">#{nextId}</span>
                        </div>

                        <div>
                            <label className="block text-sm font-semibold text-gray-700 mb-2">Driver Name</label>
                            <div className="relative">
                                <User className="absolute left-3 top-3 text-gray-400" size={18} />
                                <input
                                    type="text"
                                    required
                                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
                                    placeholder="Driver Name"
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
                                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 outline-none transition"
                                    placeholder="+1 234 567 890"
                                    value={formData.phoneNumber}
                                    onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                                />
                            </div>
                        </div>

                        <button
                            type="submit"
                            className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-lg shadow-md hover:shadow-lg transform active:scale-95 transition-all flex items-center justify-center gap-2"
                        >
                            <Truck size={20} /> Add Vehicle
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default RetrieverManagementPage;
