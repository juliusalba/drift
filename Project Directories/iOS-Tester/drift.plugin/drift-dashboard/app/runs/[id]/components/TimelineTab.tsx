"use client";

import { Iteration } from "@/lib/types";
import { formatScore, getStatusColor } from "@/lib/utils";

export function TimelineTab({ iterations }: { iterations: Iteration[] }) {
  const maxScore = Math.max(...iterations.map(i => i.score), 0.01);

  return (
    <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
      <h3 className="text-lg font-medium text-white mb-6">Iteration Timeline</h3>

      <div className="mb-8">
        <div className="flex items-end gap-4 h-48">
          {iterations.map((it) => {
            const height = (it.score / maxScore) * 100;
            return (
              <div key={it.number} className="flex-1 flex flex-col items-center justify-end h-full">
                <span className={`text-xs font-medium mb-2 ${getStatusColor(it.score)}`}>
                  {formatScore(it.score)}
                </span>
                <div
                  className={`w-full rounded-t-lg transition-all ${
                    it.score >= 0.9 ? 'bg-green-500/30 border-green-500/50' :
                    it.score >= 0.7 ? 'bg-yellow-500/30 border-yellow-500/50' :
                    'bg-red-500/30 border-red-500/50'
                  } border border-b-0`}
                  style={{ height: `${height}%` }}
                />
                <div className="text-xs text-neutral-500 mt-2">#{it.number}</div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="space-y-3">
        {iterations.map((it) => (
          <div key={it.number} className="flex items-center gap-4 bg-neutral-950 rounded-lg px-4 py-3 border border-neutral-800">
            <div className="w-8 h-8 rounded-full bg-neutral-800 flex items-center justify-center text-sm font-medium text-neutral-300">
              {it.number}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-3">
                <span className={`font-medium ${getStatusColor(it.score)}`}>
                  {formatScore(it.score)}
                </span>
                {it.delta !== 0 && (
                  <span className={`text-xs ${it.delta > 0 ? 'text-green-500' : 'text-red-500'}`}>
                    {it.delta > 0 ? '+' : ''}{Math.round(it.delta * 100)}%
                  </span>
                )}
              </div>
              <p className="text-xs text-neutral-500 mt-0.5">
                {it.fixed} issues fixed · {it.regressions} regressions
              </p>
            </div>
            <div className={`w-2 h-2 rounded-full ${
              it.score >= 0.9 ? 'bg-green-500' :
              it.score >= 0.7 ? 'bg-yellow-500' : 'bg-red-500'
            }`} />
          </div>
        ))}
      </div>
    </div>
  );
}
