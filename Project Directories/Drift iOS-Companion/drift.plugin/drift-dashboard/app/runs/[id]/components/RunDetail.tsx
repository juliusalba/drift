"use client";

import { useState } from "react";
import { Run, Screen } from "@/lib/types";
import { formatScore, formatDate, getStatusColor, getSeverityColor, cn } from "@/lib/utils";
import { ComparisonTab } from "./ComparisonTab";
import { TimelineTab } from "./TimelineTab";
import { DiscrepancyTab } from "./DiscrepancyTab";

type TabId = 'comparison' | 'timeline' | 'discrepancies' | 'diffs';

const TABS: { id: TabId; label: string; icon: React.ReactNode }[] = [
  { id: 'comparison', label: 'Comparison', icon: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5" />
    </svg>
  )},
  { id: 'timeline', label: 'Timeline', icon: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
    </svg>
  )},
  { id: 'discrepancies', label: 'Discrepancies', icon: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
    </svg>
  )},
  { id: 'diffs', label: 'Code Diffs', icon: (
    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
    </svg>
  )},
];

export function RunDetail({ run }: { run: Run }) {
  const [activeTab, setActiveTab] = useState<TabId>('comparison');
  const [selectedScreen, setSelectedScreen] = useState<Screen>(run.screens[0]);

  const score = run.summary.overall_score;
  const statusLabel = run.summary.status === 'pass' ? 'Passed' :
    run.summary.status === 'acceptable' ? 'Acceptable' :
    run.summary.status === 'needs_review' ? 'Needs Review' : 'Failed';

  const stats = [
    { label: 'Screens', value: run.summary.total_screens, icon: (
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
      </svg>
    )},
    { label: 'Passing', value: run.summary.passing_screens, color: 'text-green-400', icon: (
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    )},
    { label: 'Auto-Fixed', value: run.summary.auto_fixed, color: 'text-blue-400', icon: (
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M11.42 15.17l-5.1-5.1m0 0L11.42 4.96m-5.1 5.11h11.25M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    )},
    { label: 'Iterations', value: run.summary.total_iterations, icon: (
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" />
      </svg>
    )},
  ];

  return (
    <div className="max-w-7xl mx-auto px-6 py-8 animate-fade-in">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-2 text-xs text-neutral-500 mb-3">
          <a href="/" className="hover:text-white transition-colors">Runs</a>
          <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
          <span className="text-neutral-300">{run.id}</span>
        </div>
        <h1 className="text-xl font-semibold text-white">
          {run.project_name}
          <span className="text-neutral-600 font-normal font-mono ml-2 text-sm">{run.id}</span>
        </h1>
        <div className="flex items-center gap-4 mt-2">
          <div className="flex items-center gap-2">
            <span className={`text-2xl font-bold ${getStatusColor(score)}`}>
              {formatScore(score)}
            </span>
            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ring-1 ${
              score >= 0.9 ? 'bg-green-500/10 text-green-400 ring-green-500/20' :
              score >= 0.7 ? 'bg-yellow-500/10 text-yellow-400 ring-yellow-500/20' :
              'bg-red-500/10 text-red-400 ring-red-500/20'
            }`}>
              {statusLabel}
            </span>
          </div>
          <div className="h-4 w-px bg-neutral-800" />
          <span className="text-sm text-neutral-400">
            {run.summary.passing_screens}/{run.summary.total_screens} screens &middot; {run.summary.total_iterations} iterations &middot; {run.summary.auto_fixed} auto-fixed
          </span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-3 mb-6">
        {stats.map((stat) => (
          <div key={stat.label} className="bg-neutral-900 border border-neutral-800 rounded-xl p-4 group hover:border-neutral-700 transition-colors">
            <div className="flex items-center gap-2 mb-2">
              <div className="text-neutral-500 group-hover:text-neutral-400 transition-colors">{stat.icon}</div>
              <span className="text-xs text-neutral-500 uppercase tracking-wider">{stat.label}</span>
            </div>
            <div className={`text-2xl font-bold ${(stat as any).color || 'text-white'}`}>{stat.value}</div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-neutral-900 border border-neutral-800 rounded-xl p-1 w-fit">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              "flex items-center gap-2 px-4 py-2 text-sm rounded-lg transition-all",
              activeTab === tab.id
                ? "bg-neutral-800 text-white font-medium shadow-sm"
                : "text-neutral-400 hover:text-white hover:bg-neutral-800/50"
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex gap-6">
        {/* Screen Sidebar */}
        <div className="w-56 shrink-0">
          <h3 className="text-xs font-medium text-neutral-500 uppercase tracking-wider mb-3">Screens</h3>
          <div className="space-y-1">
            {run.screens.map((screen) => (
              <button
                key={screen.name}
                onClick={() => setSelectedScreen(screen)}
                className={cn(
                  "w-full text-left px-3 py-2.5 rounded-lg text-sm transition-all flex items-center justify-between",
                  selectedScreen?.name === screen.name
                    ? "bg-neutral-800 text-white ring-1 ring-neutral-700"
                    : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
                )}
              >
                <span className="flex items-center gap-2">
                  <span className={`w-2 h-2 rounded-full ${
                    screen.score >= 0.9 ? 'bg-green-500' :
                    screen.score >= 0.7 ? 'bg-yellow-500' : 'bg-red-500'
                  }`} />
                  <span className="truncate">{screen.name}</span>
                </span>
                <span className={`text-xs font-mono ${getStatusColor(screen.score)}`}>
                  {formatScore(screen.score)}
                </span>
              </button>
            ))}
          </div>

          {/* Sidebar Summary */}
          <div className="mt-4 pt-4 border-t border-neutral-800">
            <div className="space-y-2 text-xs text-neutral-500">
              <div className="flex justify-between">
                <span>Overall</span>
                <span className={`font-medium font-mono ${getStatusColor(score)}`}>{formatScore(score)}</span>
              </div>
              <div className="flex justify-between">
                <span>Passing</span>
                <span className="text-neutral-300">{run.summary.passing_screens}/{run.screens.length}</span>
              </div>
              <div className="flex justify-between">
                <span>Review</span>
                <span className="text-neutral-300">{run.summary.review_screens}</span>
              </div>
              {/* Score bar */}
              <div className="pt-1">
                <div className="w-full h-1.5 bg-neutral-800 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-1000 ${
                      score >= 0.9 ? 'bg-green-500' : score >= 0.7 ? 'bg-yellow-500' : 'bg-red-500'
                    }`}
                    style={{ width: `${score * 100}%` }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Panel */}
        <div className="flex-1 min-w-0">
          {activeTab === 'comparison' && <ComparisonTab screen={selectedScreen} iterations={run.iterations} />}
          {activeTab === 'timeline' && <TimelineTab iterations={run.iterations} />}
          {activeTab === 'discrepancies' && <DiscrepancyTab screens={run.screens} />}
          {activeTab === 'diffs' && (
            <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-6">
              <h3 className="text-lg font-medium text-white mb-4">Code Diffs</h3>
              {run.screens.flatMap(s => s.discrepancies).filter(d => d.status === 'fixed' && d.fix_hint).length === 0 ? (
                <div className="py-12 text-center">
                  <div className="w-12 h-12 mx-auto mb-4 rounded-xl bg-neutral-800 flex items-center justify-center">
                    <svg className="w-6 h-6 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
                    </svg>
                  </div>
                  <p className="text-neutral-500 text-sm">Code diffs will appear here after running</p>
                  <code className="text-sm text-blue-400 font-mono bg-blue-500/5 px-2 py-0.5 rounded mt-1 inline-block">/drift-fix</code>
                </div>
              ) : (
                <div className="space-y-3">
                  {run.screens.flatMap(s => s.discrepancies).filter(d => d.status === 'fixed' && d.fix_hint).map((d, i) => (
                    <div key={i} className="bg-neutral-950 border border-neutral-800 rounded-lg p-4 hover:border-neutral-700 transition-colors">
                      <div className="flex items-center gap-2 mb-2">
                        <span className={`text-xs px-2 py-0.5 rounded-full ${getSeverityColor(d.severity)}`}>{d.severity}</span>
                        <span className="text-sm text-neutral-300">{d.element}</span>
                      </div>
                      <pre className="text-xs text-green-400 bg-green-500/5 border border-green-500/10 rounded-lg p-3 overflow-x-auto">
                        <code>+ {d.fix_hint}</code>
                      </pre>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
