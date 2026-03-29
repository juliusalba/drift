"use client";

import { useState } from "react";
import { Run, Screen } from "@/lib/types";
import { formatScore, getStatusColor, getSeverityColor } from "@/lib/utils";
import { ComparisonTab } from "./ComparisonTab";
import { TimelineTab } from "./TimelineTab";
import { DiscrepancyTab } from "./DiscrepancyTab";

type TabId = 'comparison' | 'timeline' | 'discrepancies' | 'diffs';

const TABS: { id: TabId; label: string }[] = [
  { id: 'comparison', label: 'Comparison' },
  { id: 'timeline', label: 'Timeline' },
  { id: 'discrepancies', label: 'Discrepancies' },
  { id: 'diffs', label: 'Code Diffs' },
];

export function RunDetail({ run }: { run: Run }) {
  const [activeTab, setActiveTab] = useState<TabId>('comparison');
  const [selectedScreen, setSelectedScreen] = useState<Screen>(run.screens[0]);

  const score = run.summary.overall_score;
  const statusLabel = run.summary.status === 'pass' ? 'Passed' :
    run.summary.status === 'acceptable' ? 'Acceptable' :
    run.summary.status === 'needs_review' ? 'Needs Review' : 'Failed';

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-xl font-semibold text-white">
          {run.project_name}
          <span className="text-neutral-600 font-normal ml-2 text-sm">{run.id}</span>
        </h1>
        <div className="flex items-center gap-4 mt-2">
          <div className="flex items-center gap-2">
            <span className={`text-2xl font-bold ${getStatusColor(score)}`}>
              {formatScore(score)}
            </span>
            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
              score >= 0.9 ? 'bg-green-500/10 text-green-500' :
              score >= 0.7 ? 'bg-yellow-500/10 text-yellow-500' :
              'bg-red-500/10 text-red-500'
            }`}>
              {statusLabel}
            </span>
          </div>
          <span className="text-neutral-600">|</span>
          <span className="text-sm text-neutral-400">
            {run.summary.passing_screens}/{run.summary.total_screens} screens · {run.summary.total_iterations} iterations · {run.summary.auto_fixed} auto-fixed
          </span>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-3 mb-6">
        {[
          { label: 'Screens', value: run.summary.total_screens },
          { label: 'Passing', value: run.summary.passing_screens },
          { label: 'Auto-Fixed', value: run.summary.auto_fixed },
          { label: 'Iterations', value: run.summary.total_iterations },
        ].map((stat) => (
          <div key={stat.label} className="bg-neutral-900 border border-neutral-800 rounded-lg p-4 text-center">
            <div className="text-2xl font-bold text-white">{stat.value}</div>
            <div className="text-xs text-neutral-500 uppercase tracking-wider mt-0.5">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-neutral-900 border border-neutral-800 rounded-lg p-1 w-fit">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-4 py-2 text-sm rounded-md transition-colors ${
              activeTab === tab.id
                ? 'bg-neutral-800 text-white font-medium'
                : 'text-neutral-400 hover:text-white'
            }`}
          >
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
                className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors flex items-center justify-between ${
                  selectedScreen?.name === screen.name
                    ? 'bg-neutral-800 text-white'
                    : 'text-neutral-400 hover:bg-neutral-900 hover:text-white'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span className={`w-1.5 h-1.5 rounded-full ${
                    screen.score >= 0.9 ? 'bg-green-500' :
                    screen.score >= 0.7 ? 'bg-yellow-500' : 'bg-red-500'
                  }`} />
                  {screen.name}
                </span>
                <span className={`text-xs ${getStatusColor(screen.score)}`}>
                  {formatScore(screen.score)}
                </span>
              </button>
            ))}
          </div>
          <div className="mt-4 pt-4 border-t border-neutral-800">
            <div className="text-xs text-neutral-500">
              <p>Score: <span className={`font-medium ${getStatusColor(score)}`}>{formatScore(score)}</span></p>
              <p className="mt-1">{run.screens.length} screens</p>
              <p>{run.summary.passing_screens} pass</p>
              <p>{run.summary.review_screens} review</p>
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
              <p className="text-neutral-500 text-sm">Code diffs will appear here after running <code className="text-blue-400">/drift-fix</code>.</p>
              <div className="mt-4 space-y-3">
                {run.screens.flatMap(s => s.discrepancies).filter(d => d.status === 'fixed' && d.fix_hint).map((d, i) => (
                  <div key={i} className="bg-neutral-950 border border-neutral-800 rounded-lg p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <span className={`text-xs px-2 py-0.5 rounded-full ${getSeverityColor(d.severity)}`}>{d.severity}</span>
                      <span className="text-sm text-neutral-300">{d.element}</span>
                    </div>
                    <pre className="text-xs text-green-400 bg-green-500/5 rounded p-2 overflow-x-auto">
                      <code>+ {d.fix_hint}</code>
                    </pre>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
