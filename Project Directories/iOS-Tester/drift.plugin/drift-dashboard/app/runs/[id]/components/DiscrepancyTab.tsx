"use client";

import { useState } from "react";
import { Screen } from "@/lib/types";
import { getSeverityColor } from "@/lib/utils";

type Filter = {
  severity: string | null;
  type: string | null;
  status: string | null;
};

export function DiscrepancyTab({ screens }: { screens: Screen[] }) {
  const [filter, setFilter] = useState<Filter>({ severity: null, type: null, status: null });

  const allDiscrepancies = screens.flatMap((screen) =>
    screen.discrepancies.map((d) => ({ ...d, screenName: screen.name }))
  );

  const filtered = allDiscrepancies.filter((d) => {
    if (filter.severity && d.severity !== filter.severity) return false;
    if (filter.type && d.type !== filter.type) return false;
    if (filter.status && d.status !== filter.status) return false;
    return true;
  });

  const severities = [...new Set(allDiscrepancies.map(d => d.severity))];
  const types = [...new Set(allDiscrepancies.map(d => d.type))];
  const statuses = [...new Set(allDiscrepancies.map(d => d.status))];

  return (
    <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-medium text-white">
          All Discrepancies
          <span className="text-sm text-neutral-500 font-normal ml-2">({filtered.length})</span>
        </h3>

        <div className="flex gap-2">
          {[
            { key: 'severity' as const, options: severities },
            { key: 'type' as const, options: types },
            { key: 'status' as const, options: statuses },
          ].map(({ key, options }) => (
            <select
              key={key}
              value={filter[key] || ''}
              onChange={(e) => setFilter({ ...filter, [key]: e.target.value || null })}
              className="bg-neutral-800 border border-neutral-700 rounded-lg px-3 py-1.5 text-xs text-neutral-300 focus:outline-none focus:border-neutral-600"
            >
              <option value="">{key}</option>
              {options.map(o => <option key={o} value={o}>{o}</option>)}
            </select>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <p className="text-neutral-500 text-sm py-8 text-center">No discrepancies match the current filters.</p>
      ) : (
        <div className="space-y-2">
          {filtered.map((d, i) => (
            <div key={i} className="bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3">
              <div className="flex items-center gap-3">
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getSeverityColor(d.severity)}`}>
                  {d.severity}
                </span>
                <span className="text-xs text-neutral-600 uppercase w-20">{d.type}</span>
                <span className="text-sm text-neutral-300 flex-1">{d.element}</span>
                <span className="text-xs text-neutral-500">{d.screenName}</span>
                <span className={`text-xs px-2 py-0.5 rounded-full ${
                  d.status === 'fixed' ? 'bg-green-500/10 text-green-500' :
                  d.status === 'wont_fix' ? 'bg-neutral-500/10 text-neutral-500' :
                  'bg-orange-500/10 text-orange-500'
                }`}>
                  {d.status === 'fixed' ? 'Fixed' : d.status === 'wont_fix' ? "Won't Fix" : 'Open'}
                </span>
              </div>
              <div className="mt-2 flex items-center gap-4 text-xs text-neutral-500">
                <span>Expected: <span className="text-neutral-300">{d.expected}</span></span>
                <span>Actual: <span className="text-neutral-300">{d.actual}</span></span>
                <span>Confidence: <span className="text-neutral-300">{Math.round(d.confidence * 100)}%</span></span>
              </div>
              {d.fix_hint && (
                <pre className="mt-2 text-xs text-blue-400 bg-blue-500/5 rounded p-2 overflow-x-auto">
                  <code>{d.fix_hint}</code>
                </pre>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
