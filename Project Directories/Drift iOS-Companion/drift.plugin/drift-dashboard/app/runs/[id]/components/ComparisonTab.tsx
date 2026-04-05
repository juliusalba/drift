"use client";

import { Screen, Iteration } from "@/lib/types";
import { formatScore, getStatusColor, getSeverityColor } from "@/lib/utils";

export function ComparisonTab({ screen, iterations }: { screen: Screen; iterations: Iteration[] }) {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-medium text-white">{screen.name}</h3>
            <p className="text-xs text-neutral-500 font-mono mt-0.5">{screen.file_path}</p>
          </div>
          <div className="flex items-center gap-2">
            <span className={`text-lg font-bold font-mono ${getStatusColor(screen.score)}`}>
              {formatScore(screen.score)}
            </span>
            {screen.discrepancies.length > 0 && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-orange-500/10 text-orange-400 ring-1 ring-orange-500/20">
                {screen.discrepancies.length} issue{screen.discrepancies.length !== 1 ? 's' : ''}
              </span>
            )}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-6">
          {/* Simulator */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <svg className="w-3.5 h-3.5 text-neutral-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
              </svg>
              <p className="text-xs text-neutral-500 uppercase tracking-wider">Build (Simulator)</p>
            </div>
            <div className="bg-neutral-950 rounded-2xl border border-neutral-800 aspect-[9/16] flex items-center justify-center overflow-hidden group hover:border-neutral-700 transition-colors">
              {screen.screenshot_path ? (
                <img src={screen.screenshot_path} alt={`${screen.name} screenshot`} className="w-full h-full object-cover" />
              ) : (
                <div className="text-center p-6">
                  <div className="w-14 h-14 mx-auto mb-3 rounded-2xl bg-neutral-800/50 border border-neutral-700/50 flex items-center justify-center group-hover:bg-neutral-800 transition-colors">
                    <svg className="w-7 h-7 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
                    </svg>
                  </div>
                  <p className="text-sm text-neutral-500">Simulator screenshot</p>
                  <p className="text-xs text-neutral-600 mt-1">
                    Run <code className="text-blue-400/70 font-mono">/drift-check</code> to capture
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Figma */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <svg className="w-3.5 h-3.5 text-neutral-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9.53 16.122a3 3 0 00-5.78 1.128 2.25 2.25 0 01-2.4 2.245 4.5 4.5 0 008.4-2.245c0-.399-.078-.78-.22-1.128zm0 0a15.998 15.998 0 003.388-1.62m-5.043-.025a15.994 15.994 0 011.622-3.395m3.42 3.42a15.995 15.995 0 004.764-4.648l3.876-5.814a1.151 1.151 0 00-1.597-1.597L14.146 6.32a15.996 15.996 0 00-4.649 4.763m3.42 3.42a6.776 6.776 0 00-3.42-3.42" />
              </svg>
              <p className="text-xs text-neutral-500 uppercase tracking-wider">Design (Figma)</p>
            </div>
            <div className="bg-neutral-950 rounded-2xl border border-neutral-800 aspect-[9/16] flex items-center justify-center overflow-hidden group hover:border-neutral-700 transition-colors">
              {screen.design_path ? (
                <img src={screen.design_path} alt={`${screen.name} design`} className="w-full h-full object-cover" />
              ) : (
                <div className="text-center p-6">
                  <div className="w-14 h-14 mx-auto mb-3 rounded-2xl bg-neutral-800/50 border border-neutral-700/50 flex items-center justify-center group-hover:bg-neutral-800 transition-colors">
                    <svg className="w-7 h-7 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9.53 16.122a3 3 0 00-5.78 1.128 2.25 2.25 0 01-2.4 2.245 4.5 4.5 0 008.4-2.245c0-.399-.078-.78-.22-1.128zm0 0a15.998 15.998 0 003.388-1.62m-5.043-.025a15.994 15.994 0 011.622-3.395m3.42 3.42a15.995 15.995 0 004.764-4.648l3.876-5.814a1.151 1.151 0 00-1.597-1.597L14.146 6.32a15.996 15.996 0 00-4.649 4.763m3.42 3.42a6.776 6.776 0 00-3.42-3.42" />
                    </svg>
                  </div>
                  <p className="text-sm text-neutral-500">Figma design reference</p>
                  <p className="text-xs text-neutral-600 mt-1">Connect Figma MCP to fetch</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Discrepancies for this screen */}
      {screen.discrepancies.length > 0 && (
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h4 className="text-sm font-medium text-neutral-300 mb-4 flex items-center gap-2">
            <svg className="w-4 h-4 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
            </svg>
            Discrepancies
            <span className="text-xs text-neutral-500 font-normal">({screen.discrepancies.length})</span>
          </h4>
          <div className="space-y-2">
            {screen.discrepancies.map((d, i) => (
              <div key={i} className="flex items-center gap-3 bg-neutral-950 rounded-lg px-4 py-3 border border-neutral-800 hover:border-neutral-700 transition-colors">
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getSeverityColor(d.severity)}`}>
                  {d.severity}
                </span>
                <span className="text-xs text-neutral-600 uppercase w-20 font-mono">{d.type}</span>
                <span className="text-sm text-neutral-300 flex-1">{d.element}</span>
                {d.expected && d.actual && (
                  <span className="text-xs text-neutral-500 font-mono">
                    {d.expected} <span className="text-neutral-700">&rarr;</span> {d.actual}
                  </span>
                )}
                <span className={`text-xs px-2 py-0.5 rounded-full ring-1 ${
                  d.status === 'fixed' ? 'bg-green-500/10 text-green-400 ring-green-500/20' :
                  d.status === 'wont_fix' ? 'bg-neutral-500/10 text-neutral-400 ring-neutral-500/20' :
                  'bg-orange-500/10 text-orange-400 ring-orange-500/20'
                }`}>
                  {d.status === 'fixed' ? 'Fixed' : d.status === 'wont_fix' ? "Won't Fix" : 'Open'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Iteration History */}
      {iterations.length > 0 && (
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h4 className="text-sm font-medium text-neutral-300 mb-4 flex items-center gap-2">
            <svg className="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" />
            </svg>
            Iteration History
          </h4>
          <div className="flex gap-3">
            {iterations.map((it) => (
              <div key={it.number} className="flex-1 bg-neutral-950 border border-neutral-800 rounded-lg p-4 text-center hover:border-neutral-700 transition-colors">
                <div className="text-xs text-neutral-500 mb-1.5 font-mono">#{it.number}</div>
                <div className={`text-xl font-bold font-mono ${getStatusColor(it.score)}`}>
                  {formatScore(it.score)}
                </div>
                {it.delta !== 0 && (
                  <div className={`text-xs mt-1.5 font-mono ${it.delta > 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {it.delta > 0 ? '+' : ''}{formatScore(it.delta)}
                  </div>
                )}
                <div className="text-xs text-neutral-600 mt-1.5">
                  {it.fixed} fixed{it.regressions > 0 ? ` · ${it.regressions} reg.` : ''}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
