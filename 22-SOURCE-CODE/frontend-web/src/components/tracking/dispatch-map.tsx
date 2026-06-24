"use client";

import { useMemo } from "react";
import {
  MapContainer,
  Marker,
  Polyline,
  Popup,
  TileLayer,
} from "react-leaflet";
import L from "leaflet";
import { LeafletStyles } from "./leaflet-styles";
import type {
  TelematicsPosition,
  TelematicsSnapshot,
} from "@/types/database";

// Patch default marker icon paths so webpack-bundled apps render them.
const defaultIcon = L.icon({
  iconUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

interface Props {
  positions: TelematicsPosition[];
  snapshot: TelematicsSnapshot | null;
  staleAfterMinutes?: number;
}

const DEFAULT_CENTER: [number, number] = [35.6892, 51.389]; // Tehran fallback.
const DEFAULT_ZOOM = 6;

export function DispatchMap({
  positions,
  snapshot,
  staleAfterMinutes = 30,
}: Props) {
  const path = useMemo<[number, number][]>(
    () =>
      positions
        .filter((p) => p.latitude != null && p.longitude != null)
        .map((p) => [Number(p.latitude), Number(p.longitude)] as [number, number]),
    [positions],
  );

  const latest = snapshot?.latest_position ?? null;
  const center: [number, number] = latest
    ? [Number(latest.latitude), Number(latest.longitude)]
    : path[path.length - 1] ?? DEFAULT_CENTER;
  const zoom = latest || path.length > 0 ? 9 : DEFAULT_ZOOM;

  const lastReportedAt = latest?.reported_at ?? null;
  const ageMinutes = lastReportedAt
    ? (Date.now() - new Date(lastReportedAt).getTime()) / 60000
    : null;
  const isStale = ageMinutes != null && ageMinutes > staleAfterMinutes;

  return (
    <div className="space-y-2">
      <LeafletStyles />
      <div className="h-[480px] overflow-hidden rounded-md border" dir="ltr">
        <MapContainer
          center={center}
          zoom={zoom}
          scrollWheelZoom
          style={{ height: "100%", width: "100%" }}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          />
          {path.length > 1 ? (
            <Polyline positions={path} pathOptions={{ color: "#1f6feb", weight: 3, opacity: 0.8 }} />
          ) : null}
          {latest ? (
            <Marker position={[Number(latest.latitude), Number(latest.longitude)]} icon={defaultIcon}>
              <Popup>
                <div className="text-xs leading-5">
                  <div>زمان گزارش: {latest.reported_at}</div>
                  {latest.speed_kmh != null ? <div>سرعت: {latest.speed_kmh} km/h</div> : null}
                  {latest.heading_degrees != null ? <div>جهت: {latest.heading_degrees}°</div> : null}
                  <div>منبع: {latest.source ?? "—"}</div>
                </div>
              </Popup>
            </Marker>
          ) : null}
        </MapContainer>
      </div>
      <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
        <span>تعداد نقاط: {positions.length.toLocaleString("fa-IR")}</span>
        {lastReportedAt ? (
          <span>
            آخرین گزارش: {lastReportedAt}
            {isStale ? <strong className="text-amber-600"> (داده قدیمی)</strong> : null}
          </span>
        ) : (
          <span>هیچ گزارشی برای این محموله ثبت نشده است.</span>
        )}
      </div>
    </div>
  );
}
