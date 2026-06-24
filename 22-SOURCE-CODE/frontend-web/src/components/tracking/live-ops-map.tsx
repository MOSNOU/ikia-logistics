"use client";

import Link from "next/link";
import { useMemo } from "react";
import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import L from "leaflet";
import { LeafletStyles } from "./leaflet-styles";
import type { TelematicsActiveSession } from "@/types/database";

const liveIcon = L.icon({
  iconUrl: "/leaflet/marker-icon.png",
  iconRetinaUrl: "/leaflet/marker-icon-2x.png",
  shadowUrl: "/leaflet/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

const staleIcon = L.divIcon({
  className: "",
  html: '<div style="background:#f59e0b;width:14px;height:14px;border-radius:50%;border:2px solid white;box-shadow:0 0 0 2px rgba(245,158,11,0.4);"></div>',
  iconSize: [14, 14],
  iconAnchor: [7, 7],
});

interface Props {
  sessions: TelematicsActiveSession[];
  staleAfterMinutes?: number;
}

const DEFAULT_CENTER: [number, number] = [35.6892, 51.389];

export function LiveOpsMap({ sessions, staleAfterMinutes = 30 }: Props) {
  const located = useMemo(
    () => sessions.filter((s) => s.latitude != null && s.longitude != null),
    [sessions],
  );
  const staleCount = useMemo(
    () =>
      located.filter(
        (s) => s.age_minutes != null && s.age_minutes > staleAfterMinutes,
      ).length,
    [located, staleAfterMinutes],
  );
  const first = located[0];
  const center: [number, number] = first
    ? [Number(first.latitude), Number(first.longitude)]
    : DEFAULT_CENTER;
  const zoom = first ? 5 : 4;

  return (
    <div className="space-y-2">
      <LeafletStyles />
      {sessions.length > 0 && located.length === 0 ? (
        <div
          role="status"
          className="rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-xs leading-5 text-amber-900"
        >
          {sessions.length.toLocaleString("fa-IR")} نشست فعال وجود دارد ولی هیچ‌کدام
          مختصات معتبر گزارش نکرده‌اند. نشست‌ها در فهرست اعزام‌ها قابل پیگیری‌اند.
        </div>
      ) : null}
      {staleCount > 0 ? (
        <div
          role="status"
          className="rounded-md border border-amber-200 bg-amber-50/60 px-3 py-1.5 text-xs leading-5 text-amber-900"
        >
          {staleCount.toLocaleString("fa-IR")} نشست با داده قدیمی (آخرین گزارش بیش از{" "}
          {staleAfterMinutes.toLocaleString("fa-IR")} دقیقه پیش).
        </div>
      ) : null}
      <div className="h-[520px] overflow-hidden rounded-md border" dir="ltr">
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
          {located.map((s) => {
            const age = s.age_minutes ?? null;
            const stale = age != null && age > staleAfterMinutes;
            return (
              <Marker
                key={s.dispatch_id}
                position={[Number(s.latitude), Number(s.longitude)]}
                icon={stale ? staleIcon : liveIcon}
              >
                <Popup>
                  <div className="text-xs leading-5">
                    <div>اعزام: <span className="font-mono">{s.dispatch_id}</span></div>
                    <div>سازمان حمل‌کننده: <span className="font-mono">{s.carrier_organization_id}</span></div>
                    <div>شروع نشست: {s.session_started_at}</div>
                    <div>آخرین گزارش: {s.last_position_at ?? "—"}</div>
                    {age != null ? (
                      <div>
                        سن داده: {Math.round(age)} دقیقه
                        {stale ? <strong className="text-amber-600"> (قدیمی)</strong> : null}
                      </div>
                    ) : null}
                    <Link
                      href={`/admin/dispatches/${s.dispatch_id}`}
                      className="underline text-blue-600"
                    >
                      مشاهده اعزام
                    </Link>
                  </div>
                </Popup>
              </Marker>
            );
          })}
        </MapContainer>
      </div>
      <div className="text-xs text-muted-foreground">
        نشست‌های فعال: {sessions.length.toLocaleString("fa-IR")}
        {" — "}
        با مختصات قابل نمایش: {located.length.toLocaleString("fa-IR")}
      </div>
    </div>
  );
}
