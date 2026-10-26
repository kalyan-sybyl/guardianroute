import type { DashboardMetrics } from "../types";

interface StatsPanelProps {
  metrics: DashboardMetrics | null;
  metricsLoading: boolean;
  liveActiveCount: number;
  pulseCount: number;
}

export function StatsPanel({
  metrics,
  metricsLoading,
  liveActiveCount,
  pulseCount,
}: StatsPanelProps) {
  const dist = metrics?.hazardSeverityDistribution;

  return (
    <aside className="stats-panel">
      <header className="stats-header">
        <h2>Operations</h2>
        <p className="stats-updated">
          {metricsLoading
            ? "Refreshing metrics…"
            : metrics
              ? `Updated ${new Date(metrics.generatedAt).toLocaleTimeString()}`
              : "Metrics unavailable"}
        </p>
      </header>

      <div className="stat-grid">
        <StatCard label="Active hazards (live)" value={liveActiveCount} accent="teal" />
        <StatCard
          label="Guardian Pulse™"
          value={pulseCount}
          accent="violet"
        />
        <StatCard
          label="Reports today"
          value={metrics?.reportsToday ?? "—"}
        />
        <StatCard
          label="Sensor events (24h)"
          value={metrics?.sensorEventsLast24h ?? "—"}
        />
        <StatCard
          label="High-risk areas"
          value={metrics?.highRiskAreas ?? "—"}
          accent="danger"
        />
        <StatCard
          label="Resolved hazards"
          value={metrics?.resolvedHazards ?? "—"}
        />
      </div>

      <section className="stats-section">
        <h3>Risk distribution (active)</h3>
        {dist ? (
          <ul className="risk-bars">
            <RiskBar label="Critical" count={dist.critical} color="#c62828" />
            <RiskBar label="High" count={dist.high} color="#e65100" />
            <RiskBar label="Moderate" count={dist.moderate} color="#f9a825" />
            <RiskBar label="Low" count={dist.low} color="#2e7d32" />
          </ul>
        ) : (
          <p className="muted">Sign in and deploy functions for server metrics.</p>
        )}
      </section>

      <section className="stats-section">
        <h3>Road intelligence</h3>
        <p className="stat-line">
          Segments tracked: <strong>{metrics?.roadSegmentsTracked ?? "—"}</strong>
        </p>
        <p className="stat-line">
          Elevated risk (≥50): <strong>{metrics?.elevatedRiskAreas ?? "—"}</strong>
        </p>
      </section>
    </aside>
  );
}

function StatCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: number | string;
  accent?: "teal" | "violet" | "danger";
}) {
  return (
    <div className={`stat-card ${accent ? `stat-card--${accent}` : ""}`}>
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>
    </div>
  );
}

function RiskBar({
  label,
  count,
  color,
}: {
  label: string;
  count: number;
  color: string;
}) {
  const width = Math.min(100, count * 12 + 8);
  return (
    <li className="risk-bar-row">
      <span>{label}</span>
      <div className="risk-bar-track">
        <div className="risk-bar-fill" style={{ width: `${width}%`, background: color }} />
      </div>
      <span className="risk-bar-count">{count}</span>
    </li>
  );
}
