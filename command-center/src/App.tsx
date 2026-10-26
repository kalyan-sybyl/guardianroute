import { useEffect, useState } from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth, fetchDashboardMetrics, signOutUser } from "./firebase";
import { LoginScreen } from "./components/LoginScreen";
import { CommandMap } from "./components/CommandMap";
import { StatsPanel } from "./components/StatsPanel";
import { HazardLists } from "./components/HazardLists";
import {
  useLiveHazards,
  useLivePulses,
  useLiveRoadRisk,
  useRecentResolvedHazards,
} from "./hooks/useLiveData";
import type { DashboardMetrics } from "./types";
import { demoOverlayEnabled } from "./config";

export default function App() {
  const [user, setUser] = useState<User | null | undefined>(undefined);
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [metricsLoading, setMetricsLoading] = useState(false);

  const { hazards, loading: hazardsLoading } = useLiveHazards();
  const pulses = useLivePulses();
  const segments = useLiveRoadRisk();
  const resolved = useRecentResolvedHazards();

  useEffect(() => {
    return onAuthStateChanged(auth, setUser);
  }, []);

  useEffect(() => {
    if (!user) {
      setMetrics(null);
      return;
    }

    let cancelled = false;

    async function load() {
      setMetricsLoading(true);
      try {
        const data = await fetchDashboardMetrics();
        if (!cancelled) setMetrics(data);
      } catch {
        if (!cancelled) setMetrics(null);
      } finally {
        if (!cancelled) setMetricsLoading(false);
      }
    }

    load();
    const interval = setInterval(load, 60_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [user]);

  if (user === undefined) {
    return <div className="app-loading">Loading…</div>;
  }

  if (!user) {
    return <LoginScreen />;
  }

  return (
    <div className="app-shell">
      <header className="top-bar">
        <div>
          <p className="top-eyebrow">GuardianRoute</p>
          <h1>Road Safety Command Centre</h1>
        </div>
        <div className="top-actions">
          {demoOverlayEnabled() && hazards.some((h) => h.isDemo) && (
            <span className="demo-pill">Demo overlay</span>
          )}
          <span className="user-email">{user.email ?? user.uid}</span>
          <button type="button" className="btn-ghost" onClick={() => signOutUser()}>
            Sign out
          </button>
        </div>
      </header>

      <main className="dashboard">
        <div className="map-column">
          <CommandMap hazards={hazards} pulses={pulses} segments={segments} />
          {hazardsLoading && <p className="map-status">Syncing hazards…</p>}
        </div>
        <div className="side-column">
          <StatsPanel
            metrics={metrics}
            metricsLoading={metricsLoading}
            liveActiveCount={hazards.length}
            pulseCount={pulses.length}
          />
          <HazardLists hazards={hazards} resolved={resolved} />
        </div>
      </main>

      <footer className="footer-note">
        Live map · hazards · Guardian Pulse™ · road risk · server analytics (sensor
        events via Cloud Functions only).
      </footer>
    </div>
  );
}
