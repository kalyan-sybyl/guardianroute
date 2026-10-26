import { APIProvider, Map, AdvancedMarker, Pin, Circle } from "@vis.gl/react-google-maps";
import type { HazardRecord, PulseRecord, RoadSegmentRecord } from "../types";
import { KAMPALA_CENTER, DEFAULT_MAP_ZOOM, mapsApiKey } from "../config";
import { riskScoreColor, severityColor } from "../utils/colors";

interface CommandMapProps {
  hazards: HazardRecord[];
  pulses: PulseRecord[];
  segments: RoadSegmentRecord[];
}

export function CommandMap({ hazards, pulses, segments }: CommandMapProps) {
  const apiKey = mapsApiKey();
  if (!apiKey) {
    return (
      <div className="map-placeholder">
        Set <code>VITE_GOOGLE_MAPS_API_KEY</code> in <code>.env</code> for the live map.
      </div>
    );
  }

  return (
    <APIProvider apiKey={apiKey}>
      <Map
        className="command-map"
        defaultCenter={KAMPALA_CENTER}
        defaultZoom={DEFAULT_MAP_ZOOM}
        gestureHandling="greedy"
        mapId="DEMO_MAP_ID"
        disableDefaultUI={false}
      >
        {segments.map((segment) => (
          <Circle
            key={segment.id}
            center={segment.location}
            radius={Math.max(35, 20 + segment.riskScore * 0.4)}
            strokeColor={riskScoreColor(segment.riskScore)}
            strokeOpacity={0.85}
            strokeWeight={2}
            fillColor={riskScoreColor(segment.riskScore)}
            fillOpacity={0.2}
          />
        ))}
        {pulses.map((pulse) => (
          <Circle
            key={pulse.id}
            center={pulse.location}
            radius={pulse.radiusMeters}
            strokeColor="#7c4dff"
            strokeOpacity={0.9}
            strokeWeight={2}
            fillColor="#7c4dff"
            fillOpacity={0.15}
          />
        ))}
        {hazards.map((hazard) => (
          <AdvancedMarker
            key={hazard.id}
            position={hazard.location}
            title={hazard.type}
          >
            <Pin
              background={severityColor(hazard.severity)}
              borderColor="#1a1a1a"
              glyphColor="#fff"
            />
          </AdvancedMarker>
        ))}
      </Map>
    </APIProvider>
  );
}
