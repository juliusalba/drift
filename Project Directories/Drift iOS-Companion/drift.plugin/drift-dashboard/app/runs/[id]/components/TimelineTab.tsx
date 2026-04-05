"use client";

import { Iteration } from "@/lib/types";
import { formatScore, getStatusColor } from "@/lib/utils";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from "recharts";

function getBarColor(score: number): string {
  if (score >= 0.9) return '#22c55e';
  if (score >= 0.7) return '#f59e0b';
  return '#ef4444';
}

function CustomTooltip({ active, payload }: any) {
  if (!active || !payload?.[0]) return null;
  const data = payload[0].payload;
  return (
    <div className="bg-neutral-800 border border-neutral-700 rounded-lg px-3 py-2 shadow-xl">
      <p className="text-xs text-neutral-400 mb-1">Iteration #{data.number}</p>
      <p className="text-sm font-bold text-white">{formatScore(data.score)}</p>
      {data.delta !== 0 && (
        <p className={`text-xs ${data.delta > 0 ? 'text-green-400' : 'text-red-400'}`}>
          {data.delta > 0 ? '+' : ''}{Math.round(data.delta * 100)}%
        </p>
      )}
      <p className="text-xs text-neutral-500 mt-1">
        {data.fixed} fixed · {data.regressions} regressions
      </p>
    </div>
  );
}

export function TimelineTab({ iterations }: { iterations: Iteration[] }) {
  const data = iterations.map((it) => ({
    ...it,
    label: `#${it.number}`,
    scorePercent: Math.round(it.score * 100),
  }));

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Chart */}
      <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-medium text-white">Iteration Timeline</h3>
          <div className="flex items-center gap-4 text-xs text-neutral-500">
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-green-500" /> &ge;90%
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-yellow-500" /> 70-89%
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-red-500" /> &lt;70%
            </span>
          </div>
        </div>

        <div className="h-56">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e1e1e" vertical={false} />
              <XAxis
                dataKey="label"
                tick={{ fill: '#737373', fontSize: 12 }}
                axisLine={{ stroke: '#1e1e1e' }}
                tickLine={false}
              />
              <YAxis
                domain={[0, 100]}
                tick={{ fill: '#737373', fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                tickFormatter={(v: number) => `${v}%`}
              />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(255,255,255,0.02)' }} />
              <Bar dataKey="scorePercent" radius={[6, 6, 0, 0]} maxBarSize={64}>
                {data.map((entry, index) => (
                  <Cell key={index} fill={getBarColor(entry.score)} fillOpacity={0.8} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Detail List */}
      <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
        <h4 className="text-sm font-medium text-neutral-300 mb-4">Iteration Details</h4>
        <div className="space-y-2">
          {iterations.map((it) => (
            <div key={it.number} className="flex items-center gap-4 bg-neutral-950 rounded-lg px-4 py-3 border border-neutral-800 hover:border-neutral-700 transition-colors">
              <div className="w-8 h-8 rounded-lg bg-neutral-800 flex items-center justify-center text-sm font-mono font-medium text-neutral-300">
                {it.number}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <span className={`font-bold font-mono ${getStatusColor(it.score)}`}>
                    {formatScore(it.score)}
                  </span>
                  {it.delta !== 0 && (
                    <span className={`text-xs font-mono px-1.5 py-0.5 rounded ${
                      it.delta > 0 ? 'text-green-400 bg-green-500/10' : 'text-red-400 bg-red-500/10'
                    }`}>
                      {it.delta > 0 ? '+' : ''}{Math.round(it.delta * 100)}%
                    </span>
                  )}
                </div>
                <p className="text-xs text-neutral-500 mt-0.5">
                  {it.fixed} issues fixed &middot; {it.regressions} regressions
                </p>
              </div>
              {/* Progress dot */}
              <div className="flex items-center gap-1.5">
                <div className="w-16 h-1.5 bg-neutral-800 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full ${
                      it.score >= 0.9 ? 'bg-green-500' : it.score >= 0.7 ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ width: `${it.score * 100}%` }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
