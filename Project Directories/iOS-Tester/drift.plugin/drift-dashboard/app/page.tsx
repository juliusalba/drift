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
  const runs = index.runs.length > 0 ? index.runs : SAMPLE_RUNS;

  return (
    <div className="max-w-5xl mx-auto px-6 py-10">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold text-white">Drift Runs</h1>
        <p className="text-neutral-500 text-sm mt-1">Design compliance analysis history</p>
      </div>

      {index.runs.length === 0 && (
        <div className="mb-6 px-4 py-3 bg-neutral-900 border border-neutral-800 rounded-lg text-sm text-neutral-400">
          No runs found yet. Showing sample data. Run <code className="text-blue-400">/drift-check</code> in Claude Code to start.
        </div>
      )}

      <div className="space-y-3">
        {runs.map((run) => (
          <Link
            key={run.id}
            href={`/runs/${run.id}`}
            className="block bg-neutral-900 border border-neutral-800 rounded-xl p-5 hover:border-neutral-700 transition-colors group"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="relative w-12 h-12">
                  <svg width="48" height="48" className="-rotate-90">
                    <circle cx="24" cy="24" r="20" fill="none" stroke="#262626" strokeWidth="3" />
                    <circle
                      cx="24" cy="24" r="20" fill="none"
                      stroke={run.overall_score >= 0.9 ? '#22c55e' : run.overall_score >= 0.7 ? '#f59e0b' : '#ef4444'}
                      strokeWidth="3" strokeLinecap="round"
                      strokeDasharray={`${run.overall_score * 125.7} 125.7`}
                    />
                  </svg>
                  <span className={`absolute inset-0 flex items-center justify-center text-xs font-bold ${getStatusColor(run.overall_score)}`}>
                    {formatScore(run.overall_score)}
                  </span>
                </div>

                <div>
                  <h2 className="font-medium text-white group-hover:text-blue-400 transition-colors">
                    {run.project_name}
                    <span className="text-neutral-600 font-normal ml-2 text-sm">{run.id}</span>
                  </h2>
                  <p className="text-xs text-neutral-500 mt-0.5">
                    {formatDate(run.timestamp)} · {run.iterations} iteration{run.iterations !== 1 ? 's' : ''} · {run.passing_screens}/{run.total_screens} screens passing
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                  run.status === 'pass' ? 'bg-green-500/10 text-green-500' :
                  run.status === 'acceptable' ? 'bg-yellow-500/10 text-yellow-500' :
                  run.status === 'needs_review' ? 'bg-orange-500/10 text-orange-500' :
                  'bg-red-500/10 text-red-500'
                }`}>
                  {run.status === 'pass' ? 'Passed' :
                   run.status === 'acceptable' ? 'Acceptable' :
                   run.status === 'needs_review' ? 'Needs Review' :
                   run.status === 'in_progress' ? 'In Progress' :
                   'Failed'}
                </span>
                <svg className="w-4 h-4 text-neutral-600 group-hover:text-neutral-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
