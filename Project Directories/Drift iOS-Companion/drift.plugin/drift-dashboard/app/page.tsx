import Link from "next/link";
import { getRunIndex } from "@/lib/data";
import { formatScore, formatDate, getStatusColor } from "@/lib/utils";

const SAMPLE_RUNS = [
  {
    id: 'run-001',
    project_name: 'iOS-Tester',
    timestamp: new Date().toISOString(),
    overall_score: 0.87,
    total_screens: 6,
    passing_screens: 4,
    status: 'acceptable',
    iterations: 3,
  },
  {
    id: 'run-002',
    project_name: 'iOS-Tester',
    timestamp: new Date(Date.now() - 86400000).toISOString(),
    overall_score: 0.94,
    total_screens: 6,
    passing_screens: 6,
    status: 'pass',
    iterations: 2,
  },
  {
    id: 'run-003',
    project_name: 'iOS-Tester',
    timestamp: new Date(Date.now() - 172800000).toISOString(),
    overall_score: 0.71,
    total_screens: 6,
    passing_screens: 2,
    status: 'needs_review',
    iterations: 5,
  },
];

export default async function HomePage() {
  const index = await getRunIndex();
  const hasRealData = index.runs.length > 0;
  const runs = hasRealData ? index.runs : SAMPLE_RUNS;

  const avgScore = runs.length > 0
    ? runs.reduce((sum, r) => sum + r.overall_score, 0) / runs.length
    : 0;
  const totalScreens = runs.reduce((sum, r) => sum + r.total_screens, 0);
  const passingScreens = runs.reduce((sum, r) => sum + r.passing_screens, 0);
  const passRate = totalScreens > 0 ? passingScreens / totalScreens : 0;

  return (
    <div className="max-w-5xl mx-auto px-6 py-10 animate-fade-in">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-semibold text-white">Drift Runs</h1>
        <p className="text-neutral-500 text-sm mt-1">Design compliance analysis history</p>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-4 gap-3 mb-8">
        {[
          { label: 'Total Runs', value: runs.length, icon: (
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
            </svg>
          )},
          { label: 'Avg Score', value: formatScore(avgScore), color: getStatusColor(avgScore), icon: (
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
            </svg>
          )},
          { label: 'Pass Rate', value: formatScore(passRate), color: getStatusColor(passRate), icon: (
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          )},
          { label: 'Screens Analyzed', value: totalScreens, icon: (
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
            </svg>
          )},
        ].map((stat) => (
          <div key={stat.label} className="bg-neutral-900 border border-neutral-800 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <div className="text-neutral-500">{stat.icon}</div>
              <span className="text-xs text-neutral-500 uppercase tracking-wider">{stat.label}</span>
            </div>
            <div className={`text-2xl font-bold ${(stat as any).color || 'text-white'}`}>
              {stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* Empty state banner */}
      {!hasRealData && (
        <div className="mb-6 px-4 py-3 bg-blue-500/5 border border-blue-500/10 rounded-xl text-sm text-blue-400 flex items-center gap-3">
          <svg className="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" />
          </svg>
          <span>
            Showing sample data. Run <code className="font-mono bg-blue-500/10 px-1.5 py-0.5 rounded">/drift-check</code> in Claude Code to start analyzing your project.
          </span>
        </div>
      )}

      {/* Run List */}
      <div className="space-y-2">
        {runs.map((run, i) => (
          <Link
            key={run.id}
            href={`/runs/${run.id}`}
            className="block bg-neutral-900 border border-neutral-800 rounded-xl p-5 hover:border-neutral-700 hover:bg-neutral-900/80 transition-all group animate-slide-up"
            style={{ animationDelay: `${i * 50}ms`, animationFillMode: 'backwards' }}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                {/* Score Ring */}
                <div className="relative w-12 h-12 shrink-0">
                  <svg width="48" height="48" className="-rotate-90">
                    <circle cx="24" cy="24" r="20" fill="none" stroke="#1e1e1e" strokeWidth="3" />
                    <circle
                      cx="24" cy="24" r="20" fill="none"
                      stroke={run.overall_score >= 0.9 ? '#22c55e' : run.overall_score >= 0.7 ? '#f59e0b' : '#ef4444'}
                      strokeWidth="3" strokeLinecap="round"
                      strokeDasharray={`${run.overall_score * 125.7} 125.7`}
                      className="transition-all duration-1000"
                    />
                  </svg>
                  <span className={`absolute inset-0 flex items-center justify-center text-xs font-bold ${getStatusColor(run.overall_score)}`}>
                    {formatScore(run.overall_score)}
                  </span>
                </div>

                <div>
                  <h2 className="font-medium text-white group-hover:text-blue-400 transition-colors">
                    {run.project_name}
                    <span className="text-neutral-600 font-normal font-mono ml-2 text-xs">{run.id}</span>
                  </h2>
                  <p className="text-xs text-neutral-500 mt-1 flex items-center gap-2">
                    <span>{formatDate(run.timestamp)}</span>
                    <span className="text-neutral-700">&middot;</span>
                    <span>{run.iterations} iteration{run.iterations !== 1 ? 's' : ''}</span>
                    <span className="text-neutral-700">&middot;</span>
                    <span>{run.passing_screens}/{run.total_screens} screens passing</span>
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  run.status === 'pass' ? 'bg-green-500/10 text-green-400 ring-1 ring-green-500/20' :
                  run.status === 'acceptable' ? 'bg-yellow-500/10 text-yellow-400 ring-1 ring-yellow-500/20' :
                  run.status === 'needs_review' ? 'bg-orange-500/10 text-orange-400 ring-1 ring-orange-500/20' :
                  'bg-red-500/10 text-red-400 ring-1 ring-red-500/20'
                }`}>
                  {run.status === 'pass' ? 'Passed' :
                   run.status === 'acceptable' ? 'Acceptable' :
                   run.status === 'needs_review' ? 'Needs Review' :
                   run.status === 'in_progress' ? 'In Progress' :
                   'Failed'}
                </span>
                <svg className="w-4 h-4 text-neutral-700 group-hover:text-neutral-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
