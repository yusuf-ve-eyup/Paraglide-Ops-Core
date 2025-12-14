// src/components/modals/WelcomeModal.jsx
import React, { useState, useEffect } from 'react';
import useRaceStore from '../../store/useRaceStore';
import { joinRaceGroup, createRaceGroup } from '../../services/raceService';
import { Users, PlusSquare, AlertCircle, Loader2 } from 'lucide-react';

const WelcomeModal = () => {
    const { groupId, setGroupId } = useRaceStore();
    const [isOpen, setIsOpen] = useState(true); // Başlangıçta açık
    const [activeTab, setActiveTab] = useState('join'); // 'join' veya 'create'
    const [inputVal, setInputVal] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    // Eğer zaten giriş yapılmışsa (Local Storage'dan geliyorsa) modalı kapat
    useEffect(() => {
        if (groupId) {
            setIsOpen(false);
        } else {
            setIsOpen(true);
        }
    }, [groupId]);

    // Modalı zorla açık tutmak için (Kullanıcı ESC ile kapatamasın diye)
    if (!isOpen) return null;

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        const cleanId = inputVal.trim().replace(/\s+/g, '-').toLowerCase(); // Boşlukları tire yap, küçült

        if (!cleanId) {
            setError("Lütfen bir Grup ID giriniz.");
            setLoading(false);
            return;
        }

        let result;
        if (activeTab === 'join') {
            result = await joinRaceGroup(cleanId);
        } else {
            result = await createRaceGroup(cleanId);
        }

        if (result.success) {
            setGroupId(cleanId); // Store'a kaydet (Bu da modalı kapatır)
        } else {
            setError(result.message);
        }

        setLoading(false);
    };

    return (
        <div className="fixed inset-0 z-[2000] bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">

                {/* Header Tabs */}
                <div className="flex border-b">
                    <button
                        onClick={() => { setActiveTab('join'); setError(''); }}
                        className={`flex-1 py-4 font-semibold text-sm flex items-center justify-center gap-2 transition-colors ${activeTab === 'join' ? 'bg-blue-50 text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-50'}`}
                    >
                        <Users size={18} /> Gruba Katıl
                    </button>
                    <button
                        onClick={() => { setActiveTab('create'); setError(''); }}
                        className={`flex-1 py-4 font-semibold text-sm flex items-center justify-center gap-2 transition-colors ${activeTab === 'create' ? 'bg-green-50 text-green-600 border-b-2 border-green-600' : 'text-gray-500 hover:bg-gray-50'}`}
                    >
                        <PlusSquare size={18} /> Grup Oluştur
                    </button>
                </div>

                {/* Body */}
                <div className="p-8">
                    <h2 className="text-2xl font-bold text-gray-800 mb-2 text-center">
                        {activeTab === 'join' ? 'Mevcut Operasyona Katıl' : 'Yeni Operasyon Başlat'}
                    </h2>
                    <p className="text-gray-500 text-center text-sm mb-6">
                        {activeTab === 'join'
                            ? 'Admin tarafından oluşturulan benzersiz grup ID\'sini giriniz.'
                            : 'Yarış veya etkinlik için benzersiz bir isim belirleyiniz.'}
                    </p>

                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div>
                            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                                Grup ID / Yarış İsmi
                            </label>
                            <input
                                type="text"
                                value={inputVal}
                                onChange={(e) => setInputVal(e.target.value)}
                                placeholder={activeTab === 'join' ? "örn: babadag-yaris-1" : "örn: denizli-cup-2025"}
                                className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                            />
                        </div>

                        {error && (
                            <div className="flex items-center gap-2 text-red-600 text-sm bg-red-50 p-3 rounded-lg">
                                <AlertCircle size={16} /> {error}
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            className={`w-full py-3 rounded-lg font-bold text-white shadow-lg transform transition-all active:scale-95 ${activeTab === 'join' ? 'bg-blue-600 hover:bg-blue-700' : 'bg-green-600 hover:bg-green-700'}`}
                        >
                            {loading ? (
                                <span className="flex items-center justify-center gap-2">
                                    <Loader2 size={18} className="animate-spin" /> İşleniyor...
                                </span>
                            ) : (
                                activeTab === 'join' ? 'Giriş Yap' : 'Oluştur ve Gir'
                            )}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default WelcomeModal;