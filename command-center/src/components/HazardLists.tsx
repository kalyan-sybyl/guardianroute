import type { HazardRecord } from "../types";
import { severityColor } from "../utils/colors";

interface HazardListsProps {
  hazards: HazardRecord[];
  resolved: HazardRecord[];
}

export function HazardLists({ hazards, resolved }: HazardListsProps) {
  const recent = [...hazards]
    .sort((a, b) => (b.updatedAt?.getTime() ?? 0) - (a.updatedAt?.getTime() ?? 0))
    .slice(0, 8);

  return (
    <div className="hazard-lists">
      <section>
        <h3>Recent hazards</h3>
        <ul className="hazard-list">
          {recent.length === 0 ? (
            <li className="muted">No active hazards in Firestore.</li>
          ) : (
            recent.map((h) => <HazardRow key={h.id} hazard={h} />)
          )}
        </ul>
      </section>
      <section>
        <h3>Resolved / stale</h3>
        <ul className="hazard-list">
          {resolved.length === 0 ? (
            <li className="muted">No resolved hazards yet.</li>
          ) : (
            resolved.map((h) => <HazardRow key={h.id} hazard={h} />)
          )}
        </ul>
      </section>
    </div>
  );
}

function HazardRow({ hazard }: { hazard: HazardRecord }) {
  return (
    <li className="hazard-row">
      <span
        className="severity-dot"
        style={{ background: severityColor(hazard.severity) }}
        title={hazard.severity}
      />
      <div className="hazard-row-body">
        <strong>
          {hazard.publicId} · {hazard.type.replaceAll("_", " ")}
        </strong>
        <span className="hazard-meta">
          {hazard.status}
          {hazard.isDemo ? " · DEMO" : ""}
          {hazard.confidence > 0
            ? ` · ${Math.round(hazard.confidence * 100)}%`
            : ""}
        </span>
      </div>
    </li>
  );
}
