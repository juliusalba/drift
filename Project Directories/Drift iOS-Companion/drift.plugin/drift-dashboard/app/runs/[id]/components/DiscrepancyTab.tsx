"use client";

import { useState } from "react";
import { Screen } from "@/lib/types";
import { getSeverityColor, cn } from "@/lib/utils";

type Filter = {
  severity: string | null;
  type: string | null;
  status: string | null;
};

function FilterPill({
  label,
  options,
  value,
  onChange,
}: {
  label: string;
  options: string[];
  value: string | null;
  onChange: (v: string | null) => void;
}) {
  return (
    <div className="flex items-center gap-1">
      <button
        onClick={() => onChange(null)}
        className={cn(
          "px-2.5 py-1 text-xs rounded-md transition-colors",
          !value
            ? "bg-neutral-700 text-white"
            : "text-neutral-500 hover:text-neutral-300"
        )}
      >
        All {label}
      </button>
      {options.map((opt) => (
        <button
          key={opt}
          onClick={() => onChange(value === opt ? null : opt)}
          className={cn(
            "px-2.5 py-1 text-xs rounded-md transition-colors capitalize",
            value === opt
              ? "bg-neutral-700 text-white"
              : "text-neutral-500 hover:text-neutral-300"
          )}
        >
          {opt}
        </button>
      ))}
    </div>
  );
}

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

  const severities = Array.from(new Set(allDiscrepancies.map(d => d.severity)));
  const types = Array.from(new Set(allDiscrepancies.map(d => d.type)));
  const statuses = Array.from(new Set(allDiscrepancies.map(d => d.status)));

  const counts = {
    open: allDiscrepancies.filter(d => d.status === 'open').length,
    fixed: allDiscrepancies.filter(d => d.status === 'fixed').length,
    wont_fix: allDiscrepancies.filter(d => d.status === 'wont_fix').length,
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Summary badges */}
      <div className="flex gap-3">
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl px-4 py-3 flex items-center gap-3">
          <span className="text-2xl font-bold text-white">{allDiscrepancies.length}</span>
          <span className="text-xs text-neutral-500">Total</span>
        </div>
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl px-4 py-3 flex items-center gap-3">
          <span className="text-2xl font-bold text-orange-400">{counts.open}</span>
          <span className="text-xs text-neutral-500">Open</span>
        </div>
        <div className="bg-neutral-900 border border-neutral-800 rounded-xl px-4 py-3 flex items-center gap-3">
          <span className="text-2xl font-bold text-green-400">{counts.fixed}</span>
          <span className="text-xs text-neutral-500">Fixed</span>
        </div>
        {counts.wont_fix > 0 && (
          <div className="bg-neutral-900 border border-neutral-800 rounded-xl px-4 py-3 flex items-center gap-3">
            <span className="text-2xl font-bold text-neutral-400">{counts.wont_fix}</span>
            <span className="text-xs text-neutral-500">Won&apos;t Fix</span>
          </div>
        )}
      </div>

      {/* Filters and list */}
      <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-medium text-white">
            All Discrepancies
            <span className="text-sm text-neutral-500 font-normal ml-2">({filtered.length})</span>
          </h3>
        </div>

        {/* Filter pills */}
        <div className="flex flex-wrap gap-4 mb-6 pb-4 border-b border-neutral-800">
          <FilterPill label="severity" options={severities} value={filter.severity} onChange={(v) => setFilter({ ...filter, severity: v })} />
          <div className="w-px h-6 bg-neutral-800" />
          <FilterPill label="type" options={types} value={filter.type} onChange={(v) => setFilter({ ...filter, type: v })} />
          <div className="w-px h-6 bg-neutral-800" />
          <FilterPill label="status" options={statuses} value={filter.status} onChange={(v) => setFilter({ ...filter, status: v })} />
        </div>

        {filtered.length === 0 ? (
          <div className="py-12 text-center">
            <div className="w-12 h-12 mx-auto mb-4 rounded-xl bg-neutral-800 flex items-center justify-center">
              <svg className="w-6 h-6 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-neutral-500 text-sm">No discrepancies match the current filters.</p>
          </div>
        ) : (
          <div className="space-y-2">
            {filtered.map((d, i) => (
              <div key={i} className="bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 hover:border-neutral-700 transition-colors">
                <div className="flex items-center gap-3">
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${getSeverityColor(d.severity)}`}>
                    {d.severity}
                  </span>
                  <span className="text-xs text-neutral-600 uppercase w-20 font-mono">{d.type}</span>
                  <span className="text-sm text-neutral-300 flex-1">{d.element}</span>
                  <span className="text-xs text-neutral-600 font-mono">{d.screenName}</span>
                  <span className={`text-xs px-2 py-0.5 rounded-full ring-1 ${
                    d.status === 'fixed' ? 'bg-green-500/10 text-green-400 ring-green-500/20' :
                    d.status === 'wont_fix' ? 'bg-neutral-500/10 text-neutral-400 ring-neutral-500/20' :
                    'bg-orange-500/10 text-orange-400 ring-orange-500/20'
                  }`}>
                    {d.status === 'fixed' ? 'Fixed' : d.status === 'wont_fix' ? "Won't Fix" : 'Open'}
                  </span>
                </div>
                <div className="mt-2 flex items-center gap-4 text-xs text-neutral-500">
                  {d.expected && <span>Expected: <span className="text-neutral-300 font-mono">{d.expected}</span></span>}
                  {d.actual && <span>Actual: <span className="text-neutral-300 font-mono">{d.actual}</span></span>}
                  <span>Confidence: <span className="text-neutral-300 font-mono">{Math.round(d.confidence * 100)}%</span></span>
                </div>
                {d.fix_hint && (
                  <pre className="mt-2 text-xs text-blue-400 bg-blue-500/5 border border-blue-500/10 rounded-lg p-2.5 overflow-x-auto">
                    <code>{d.fix_hint}</code>
                  </pre>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
