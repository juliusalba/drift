"use client";

import { useState } from "react";

export default function SettingsPage() {
  const [figmaFileId, setFigmaFileId] = useState('');
  const [threshold, setThreshold] = useState(0.9);
  const [maxIterations, setMaxIterations] = useState(5);
  const [device, setDevice] = useState('iPhone 16 Pro');

  return (
    <div className="max-w-2xl mx-auto px-6 py-10">
      <h1 className="text-2xl font-semibold text-white mb-1">Settings</h1>
      <p className="text-neutral-500 text-sm mb-8">Configure Drift behavior</p>

      <div className="space-y-8">
        <div>
          <label className="block text-sm font-medium text-neutral-300 mb-2">Figma File ID</label>
          <input
            type="text"
            value={figmaFileId}
            onChange={(e) => setFigmaFileId(e.target.value)}
            placeholder="Enter Figma file key..."
            className="w-full bg-neutral-900 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white placeholder:text-neutral-600 focus:outline-none focus:border-neutral-600"
          />
          <p className="text-xs text-neutral-600 mt-1.5">From the Figma URL: figma.com/design/<strong className="text-neutral-400">THIS_PART</strong>/...</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-300 mb-2">
            Pass Threshold: <span className="text-white">{Math.round(threshold * 100)}%</span>
          </label>
          <input
            type="range"
            min={0.5}
            max={1}
            step={0.05}
            value={threshold}
            onChange={(e) => setThreshold(parseFloat(e.target.value))}
            className="w-full accent-blue-500"
          />
          <div className="flex justify-between text-xs text-neutral-600 mt-1">
            <span>50%</span>
            <span>100%</span>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-300 mb-2">Max Iterations</label>
          <select
            value={maxIterations}
            onChange={(e) => setMaxIterations(parseInt(e.target.value))}
            className="w-full bg-neutral-900 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-neutral-600"
          >
            {[1, 2, 3, 5, 8, 10].map(n => (
              <option key={n} value={n}>{n} iteration{n > 1 ? 's' : ''}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-300 mb-2">Simulator Device</label>
          <select
            value={device}
            onChange={(e) => setDevice(e.target.value)}
            className="w-full bg-neutral-900 border border-neutral-800 rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-neutral-600"
          >
            {['iPhone 16 Pro', 'iPhone 16 Pro Max', 'iPhone 16', 'iPhone 15 Pro', 'iPhone SE'].map(d => (
              <option key={d} value={d}>{d}</option>
            ))}
          </select>
        </div>

        <div className="pt-4 border-t border-neutral-800">
          <p className="text-xs text-neutral-600">
            Settings are saved locally. They apply to all Drift runs in this project.
          </p>
        </div>
      </div>
    </div>
  );
}
