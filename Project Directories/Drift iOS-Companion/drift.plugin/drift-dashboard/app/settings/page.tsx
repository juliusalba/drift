"use client";

import { useState } from "react";

export default function SettingsPage() {
  const [figmaFileId, setFigmaFileId] = useState('');
  const [threshold, setThreshold] = useState(0.9);
  const [maxIterations, setMaxIterations] = useState(5);
  const [device, setDevice] = useState('iPhone 16 Pro');
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div className="max-w-2xl mx-auto px-6 py-10 animate-fade-in">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-semibold text-white">Settings</h1>
          <p className="text-neutral-500 text-sm mt-1">Configure Drift behavior</p>
        </div>
        <button
          onClick={handleSave}
          className={`px-4 py-2 text-sm font-medium rounded-lg transition-all ${
            saved
              ? 'bg-green-500/10 text-green-400 ring-1 ring-green-500/20'
              : 'bg-blue-500 text-white hover:bg-blue-600 active:scale-[0.98]'
          }`}
        >
          {saved ? (
            <span className="flex items-center gap-1.5">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
              Saved
            </span>
          ) : 'Save Settings'}
        </button>
      </div>

      <div className="space-y-8">
        {/* Design Source */}
        <section className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h2 className="text-sm font-medium text-white mb-1">Design Source</h2>
          <p className="text-xs text-neutral-500 mb-5">Connect your Figma file for design comparison</p>

          <div>
            <label className="block text-xs font-medium text-neutral-400 mb-2">Figma File ID</label>
            <input
              type="text"
              value={figmaFileId}
              onChange={(e) => setFigmaFileId(e.target.value)}
              placeholder="Enter Figma file key..."
              className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white placeholder:text-neutral-600 focus:outline-none focus:border-blue-500/50 focus:ring-1 focus:ring-blue-500/20 transition-colors"
            />
            <p className="text-xs text-neutral-600 mt-2">
              From the Figma URL: figma.com/design/<span className="text-neutral-400 font-mono">THIS_PART</span>/...
            </p>
          </div>
        </section>

        {/* Analysis */}
        <section className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h2 className="text-sm font-medium text-white mb-1">Analysis</h2>
          <p className="text-xs text-neutral-500 mb-5">Tune how Drift evaluates design compliance</p>

          <div className="space-y-6">
            <div>
              <div className="flex items-center justify-between mb-3">
                <label className="text-xs font-medium text-neutral-400">Pass Threshold</label>
                <span className={`text-sm font-bold font-mono ${
                  threshold >= 0.9 ? 'text-green-400' : threshold >= 0.7 ? 'text-yellow-400' : 'text-red-400'
                }`}>
                  {Math.round(threshold * 100)}%
                </span>
              </div>
              <input
                type="range"
                min={0.5}
                max={1}
                step={0.05}
                value={threshold}
                onChange={(e) => setThreshold(parseFloat(e.target.value))}
                className="w-full accent-blue-500 h-1.5 bg-neutral-800 rounded-full appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:bg-blue-500 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:cursor-pointer [&::-webkit-slider-thumb]:shadow-lg"
              />
              <div className="flex justify-between text-[10px] text-neutral-600 mt-1.5 font-mono">
                <span>50%</span>
                <span>75%</span>
                <span>100%</span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-neutral-400 mb-2">Max Iterations</label>
              <select
                value={maxIterations}
                onChange={(e) => setMaxIterations(parseInt(e.target.value))}
                className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500/50 focus:ring-1 focus:ring-blue-500/20 transition-colors cursor-pointer"
              >
                {[1, 2, 3, 5, 8, 10].map(n => (
                  <option key={n} value={n}>{n} iteration{n > 1 ? 's' : ''}</option>
                ))}
              </select>
              <p className="text-xs text-neutral-600 mt-2">
                Maximum check-fix-rebuild cycles before stopping
              </p>
            </div>
          </div>
        </section>

        {/* Simulator */}
        <section className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h2 className="text-sm font-medium text-white mb-1">Simulator</h2>
          <p className="text-xs text-neutral-500 mb-5">Target device for screenshot capture</p>

          <div>
            <label className="block text-xs font-medium text-neutral-400 mb-2">Device</label>
            <select
              value={device}
              onChange={(e) => setDevice(e.target.value)}
              className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-blue-500/50 focus:ring-1 focus:ring-blue-500/20 transition-colors cursor-pointer"
            >
              {['iPhone 16 Pro', 'iPhone 16 Pro Max', 'iPhone 16', 'iPhone 15 Pro', 'iPhone SE'].map(d => (
                <option key={d} value={d}>{d}</option>
              ))}
            </select>
          </div>
        </section>

        {/* Footer note */}
        <div className="flex items-center gap-2 text-xs text-neutral-600 pt-2">
          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" />
          </svg>
          Settings are saved locally and apply to all Drift runs in this project.
        </div>
      </div>
    </div>
  );
}
