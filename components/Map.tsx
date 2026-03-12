"use client";

const cities: Record<string, [number, number]> = {
  "تهران": [35.6892, 51.3890],
  "مشهد": [36.2605, 59.6168],
  "سمنان": [35.5729, 53.3971],
  "شاهرود": [36.4181, 54.9764],
  "نیشابور": [36.2132, 58.7961],
  "اصفهان": [32.6546, 51.6680],
};

export function RouteMap({ origin, destination, height = "300px" }: { origin: string; destination: string; height?: string }) {
  const o = cities[origin] || cities["تهران"];
  const d = cities[destination] || cities["مشهد"];
  const centerLat = (o[0] + d[0]) / 2;
  const centerLon = (o[1] + d[1]) / 2;
  const zoom = 6;

  const markerOrigin = `${o[0]},${o[1]}`;
  const markerDest = `${d[0]},${d[1]}`;

  // Distance calculation
  const R = 6371;
  const dLat = (d[0] - o[0]) * Math.PI / 180;
  const dLon = (d[1] - o[1]) * Math.PI / 180;
  const a = Math.sin(dLat/2)**2 + Math.cos(o[0]*Math.PI/180) * Math.cos(d[0]*Math.PI/180) * Math.sin(dLon/2)**2;
  const dist = Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)));

  const mapUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${Math.min(o[1],d[1])-1},${Math.min(o[0],d[0])-0.5},${Math.max(o[1],d[1])+1},${Math.max(o[0],d[0])+0.5}&layer=mapnik&marker=${markerDest}`;

  return (
    <div style={{borderRadius:"16px",overflow:"hidden",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.08)",position:"relative"}}>
      <iframe src={mapUrl} style={{width:"100%",height,border:"none"}} loading="lazy" />
      <div dir="rtl" style={{position:"absolute",bottom:"10px",right:"10px",background:"white",padding:"8px 14px",borderRadius:"10px",boxShadow:"0 2px 10px rgba(0,0,0,0.15)",fontFamily:"Vazirmatn",fontSize:"13px",fontWeight:900,color:"#1e3a5f",display:"flex",gap:"12px",alignItems:"center"}}>
        <span>📦 {origin}</span>
        <span style={{color:"#06b6d4"}}>←</span>
        <span>📍 {destination}</span>
        <span style={{background:"#ecfeff",padding:"2px 8px",borderRadius:"6px",color:"#0ea5e9"}}>~{new Intl.NumberFormat("fa-IR").format(dist)} کیلومتر</span>
      </div>
    </div>
  );
}
