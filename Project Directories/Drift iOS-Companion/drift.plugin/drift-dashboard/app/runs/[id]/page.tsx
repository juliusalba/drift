import { getRun } from "@/lib/data";
import { RunDetail } from "./components/RunDetail";

const SAMPLE_RUN = {
  id: 'run-001',
  project_name: 'iOS-Tester',
  timestamp: new Date().toISOString(),
  summary: {
    overall_score: 0.87,
    total_screens: 6,
    passing_screens: 4,
    review_screens: 2,
    critical_issues: 0,
    major_issues: 3,
    auto_fixed: 5,
    total_iterations: 3,
    status: 'acceptable' as const,
  },
  screens: [
    { name: 'HomeView', score: 0.95, file_path: 'Sources/Views/HomeView.swift', discrepancies: [] },
    { name: 'ProfileView', score: 0.92, file_path: 'Sources/Views/ProfileView.swift', discrepancies: [] },
    { name: 'SettingsView', score: 0.91, file_path: 'Sources/Views/SettingsView.swift', discrepancies: [] },
    { name: 'TransactionsView', score: 0.93, file_path: 'Sources/Views/TransactionsView.swift', discrepancies: [] },
    {
      name: 'LoginView', score: 0.78, file_path: 'Sources/Views/LoginView.swift',
      discrepancies: [
        { type: 'color' as const, severity: 'major' as const, element: 'CTA Button', expected: '#377CC8', actual: '#3A7BC8', status: 'fixed' as const, confidence: 0.85, fix_hint: '.foregroundColor(Color(hex: "#377CC8"))' },
        { type: 'spacing' as const, severity: 'major' as const, element: 'Header padding', expected: '16pt', actual: '12pt', status: 'fixed' as const, confidence: 0.9, fix_hint: '.padding(.top, 16)' },
        { type: 'typography' as const, severity: 'minor' as const, element: 'Subtitle', expected: 'SF Pro Medium 14', actual: 'SF Pro Regular 14', status: 'open' as const, confidence: 0.72, fix_hint: '.font(.system(size: 14, weight: .medium))' },
      ],
    },
    {
      name: 'OnboardingView', score: 0.72, file_path: 'Sources/Views/OnboardingView.swift',
      discrepancies: [
        { type: 'layout' as const, severity: 'major' as const, element: 'Card stack', expected: 'Horizontal scroll', actual: 'Vertical list', status: 'open' as const, confidence: 0.65 },
        { type: 'spacing' as const, severity: 'minor' as const, element: 'Bottom CTA margin', expected: '24pt', actual: '20pt', status: 'fixed' as const, confidence: 0.88, fix_hint: '.padding(.bottom, 24)' },
      ],
    },
  ],
  iterations: [
    { number: 1, score: 0.71, delta: 0, fixed: 0, regressions: 0 },
    { number: 2, score: 0.82, delta: 0.11, fixed: 3, regressions: 0 },
    { number: 3, score: 0.87, delta: 0.05, fixed: 2, regressions: 0 },
  ],
};

export default async function RunPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const run = await getRun(id) || SAMPLE_RUN;
  return <RunDetail run={run} />;
}
