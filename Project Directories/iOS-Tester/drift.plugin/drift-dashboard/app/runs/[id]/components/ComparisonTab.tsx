"use client";

import { Screen, Iteration } from "@/lib/types";
import { formatScore, getStatusColor, getSeverityColor } from "@/lib/utils";

export function ComparisonTab({ screen, iterations }: { screen: Screen; iterations: Iteration[] }) {
  return (
    <div className="space-y-6">
      <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
        <h3 className="text-lg font-medium text-white mb-1">{screen.name}</h3>
        <p className="text-xs text-neutral-500 mb-6">{screen.file_path}</p>

        <div className="grid grid-cols-2 gap-6">
          <div>
            <p className="text-xs text-neutral-500 uppercase tracking-wider mb-3">Build (Simulator)</p>
            <div className="bg-neutral-950 rounded-2xl p-4 border border-neutral-800 aspect-[9/16] flex items-center justify-center">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-3 rounded-2xl bg-neutral-800 flex items-center justify-center">
                  <svg className="w-8 h-8 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                  </svg>
                </div>
                <p className="text-sm text-neutral-500">Simulator screenshot</p>
                <p className="text-xs text-neutral-600 mt-1">Run /drift-check to capture</p>
              </div>
            </div>
          </div>

          <div>
            <p className="text-xs text-neutral-500 uppercase tracking-wider mb-3">Design (Figma)</p>
            <div className="bg-neutral-950 rounded-2xl p-4 border border-neutral-800 aspect-[9/16] flex items-center justify-center">
              <div className="text-center">
                <div className="w-16 h-16 mx-auto mb-3 rounded-2xl bg-neutral-800 flex items-center justify-center">
                  <svg className="w-8 h-8 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <p className="text-sm text-neutral-500">Figma design reference</p>
                <p className="text-xs text-neutral-600 mt-1">Connect Figma MCP to fetch</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {screen.discrepancies.length > 0 && (
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h4 className="text-sm font-medium text-neutral-300 mb-4">
            Discrepancies ({screen.discrepancies.length})
          </h4>
          <div className="space-y-2">
            {screen.discrepancies.map((d, i) => (
              <div key={i} className="flex items-center gap-3 bg-neutral-950 rounded-lg px-4 py-3 border border-neutral-800">
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getSeverityColor(d.severity)}`}>
                  {d.severity}
                </span>
                <span className="text-xs text-neutral-500 uppercase w-20">{d.type}</span>
                <span className="text-sm text-neutral-300 flex-1">{d.element}</span>
                <span className="text-xs text-neutral-500">
                  {d.expected} → {d.actual}
                </span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${
                  d.status === 'fixed' ? 'bg-green-500/10 text-green-500' :
                  d.status === 'wont_fix' ? 'bg-neutral-500/10 text-neutral-500' :
                  'bg-orange-500/10 text-orange-500'
                }`}>
                  {d.status === 'fixed' ? 'Fixed' : d.status === 'wont_fix' ? "Won't Fix" : 'Open'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {iterations.length > 0 && (
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
          <h4 className="text-sm font-medium text-neutral-300 mb-4">Iteration History</h4>
          <div className="flex gap-3">
            {iterations.map((it) => (
              <div key={it.number} className="flex-1 bg-neutral-950 border border-neutral-800 rounded-lg p-3 text-center">
                <div className="text-xs text-neutral-500 mb-1">#{it.number}</div>
                <div className={`text-lg font-bold ${getStatusColor(it.score)}`}>
                  {formatScore(it.score)}
                </div>
                {it.delta !== 0 && (
                  <div className={`text-xs mt-1 ${it.delta > 0 ? 'text-green-500' : 'text-red-500'}`}>
                    {it.delta > 0 ? '+' : ''}{formatScore(it.delta)}
                  </div>
                )}
                <div className="text-xs text-neutral-600 mt-1">
                  {it.fixed} fixed{it.regressions > 0 ? `, ${it.regressions} reg.` : ''}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
