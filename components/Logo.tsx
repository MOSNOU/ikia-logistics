"use client";
import { useMemo } from "react";

function project3D(x: number, y: number, z: number, tiltX: number, tiltY: number) {
  let y1 = y * Math.cos(tiltX) - z * Math.sin(tiltX);
  let z1 = y * Math.sin(tiltX) + z * Math.cos(tiltX);
  let x2 = x * Math.cos(tiltY) + z1 * Math.sin(tiltY);
  let z2 = -x * Math.sin(tiltY) + z1 * Math.cos(tiltY);
  return { x: Math.round(x2 * 100) / 100, y: Math.round(y1 * 100) / 100, z: Math.round(z2 * 100) / 100 };
}

export function LogoSphere({ size = 200 }: { size?: number }) {
  const R = Math.round((size / 2.8) * 100) / 100;
  const tiltX = 0.5236; const tiltY = 0.3927;
  const pi = [3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3];
  const paths = useMemo(() => {
    const result: { d: string; grad: string; dash: string; w: number; op: number }[] = [];
    for (let i = 0; i < 12; i++) {
      let a = (i / 12) * Math.PI, d = "M ";
      for (let j = 0; j <= 80; j++) { let t = (j/80)*2*Math.PI; let p = project3D(R*Math.cos(t)*Math.cos(a),R*Math.cos(t)*Math.sin(a),R*Math.sin(t),tiltX,tiltY); d += (j===0?"":"L ")+`${p.x},${p.y} `; }
      let di = i % pi.length; result.push({d,grad:i%3===0?"url(#g1)":i%3===1?"url(#g2)":"url(#g3)",dash:`${pi[di]*3} ${pi[(di+1)%pi.length]*2}`,w:1.5,op:0.65});
    }
    for (let i = 0; i < 12; i++) {
      let a = (i/12)*Math.PI, d = "M ";
      for (let j = 0; j <= 80; j++) { let t=(j/80)*2*Math.PI; let p=project3D(R*Math.sin(t),R*Math.cos(t)*Math.sin(a),R*Math.cos(t)*Math.cos(a),tiltX,tiltY); d+=(j===0?"":"L ")+`${p.x},${p.y} `; }
      let di=(i+12)%pi.length; result.push({d,grad:i%3===0?"url(#g2)":i%3===1?"url(#g3)":"url(#g4)",dash:`${pi[di]*3} ${pi[(di+1)%pi.length]*2}`,w:1.5,op:0.65});
    }
    for (let i=-3;i<=3;i++) {
      let lat=(i/4)*Math.PI/2,r=R*Math.cos(lat),z=R*Math.sin(lat),d="M ";
      for (let j=0;j<=80;j++) { let th=(j/80)*2*Math.PI; let p=project3D(r*Math.cos(th),r*Math.sin(th),z,tiltX,tiltY); d+=(j===0?"":"L ")+`${p.x},${p.y} `; }
      result.push({d,grad:i===0?"url(#g4)":"url(#g1)",dash:i===0?"31 16":`${pi[Math.abs(i)]*3} ${pi[Math.abs(i)+1]*2}`,w:i===0?2:1.5,op:i===0?0.75:0.6});
    }
    return result;
  }, [R]);
  const nodes = useMemo(() => {
    const result: {x:number;y:number;color:string;size:number}[] = [];
    const lats=[-.942,-.898,-.524,0,.524,.898,.942];
    const counts=[4,8,14,18,14,8,4];
    const colors=["#06b6d4","#0ea5e9","#f59e0b","#10b981","#3b82f6","#8b5cf6","#06b6d4"];
    lats.forEach((lat,li)=>{let r=R*Math.cos(lat),z=R*Math.sin(lat);for(let i=0;i<counts[li];i++){let a=(i/counts[li])*2*Math.PI;let p=project3D(r*Math.cos(a),r*Math.sin(a),z,tiltX,tiltY);if(p.z>-R*0.4)result.push({x:p.x,y:p.y,color:colors[li],size:li===3?4:3});}});
    let np=project3D(0,0,R,tiltX,tiltY); if(np.z>-R*0.4) result.push({x:np.x,y:np.y,color:"#f59e0b",size:4.5});
    let sp=project3D(0,0,-R,tiltX,tiltY); if(sp.z>-R*0.4) result.push({x:sp.x,y:sp.y,color:"#06b6d4",size:4.5});
    return result;
  }, [R]);
  const half = size/2;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} suppressHydrationWarning>
      <defs>
        <linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#06b6d4"/><stop offset="100%" stopColor="#0ea5e9"/></linearGradient>
        <linearGradient id="g2" x1="100%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stopColor="#0ea5e9"/><stop offset="100%" stopColor="#3b82f6"/></linearGradient>
        <linearGradient id="g3" x1="0%" y1="100%" x2="100%" y2="0%"><stop offset="0%" stopColor="#10b981"/><stop offset="100%" stopColor="#06b6d4"/></linearGradient>
        <linearGradient id="g4" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#f59e0b"/><stop offset="100%" stopColor="#06b6d4"/></linearGradient>
      </defs>
      <g transform={`translate(${half},${half})`} suppressHydrationWarning>
        {paths.map((p,i)=><path key={i} d={p.d} fill="none" stroke={p.grad} strokeWidth={p.w} opacity={p.op} strokeDasharray={p.dash} suppressHydrationWarning/>)}
        {nodes.map((n,i)=>(<g key={`n${i}`} suppressHydrationWarning><circle cx={n.x} cy={n.y} r={Math.round(n.size*1.8*100)/100} fill={n.color} opacity={0.15} suppressHydrationWarning/><circle cx={n.x} cy={n.y} r={n.size} fill={n.color} suppressHydrationWarning/><circle cx={n.x} cy={n.y} r={Math.round(n.size*0.35*100)/100} fill="white" suppressHydrationWarning/></g>))}
      </g>
    </svg>
  );
}

export function LogoText({ size = "large", onDark = false }: { size?: "large"|"medium"|"small"; onDark?: boolean }) {
  const mainSize = size === "large" ? "44px" : size === "medium" ? "24px" : "16px";
  return (
    <div dir="ltr" style={{ fontFamily: "Vazirmatn, sans-serif", textAlign: "center" }}>
      <span style={{ fontSize: mainSize, fontWeight: 900, letterSpacing: "2px" }}>
        <span style={{ color: "#B22234" }}>i</span>
        <span style={{ color: onDark ? "#FFFFFF" : "#3C3B6E" }}>KIA</span>
      </span>
      <span style={{ fontSize: mainSize, fontWeight: 900, letterSpacing: "2px", color: onDark ? "rgba(255,255,255,0.9)" : "#3C3B6E", marginLeft: "8px" }}>Logistics</span>
    </div>
  );
}

export function LogoHero({ onDark = false }: { onDark?: boolean }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "16px" }}>
      <LogoSphere size={220} />
      <LogoText size="large" onDark={onDark} />
    </div>
  );
}

export function LogoNav({ onDark = false }: { onDark?: boolean }) {
  return (
    <div dir="ltr" style={{ display: "flex", alignItems: "center", gap: "8px" }}>
      <LogoSphere size={36} />
      <LogoText size="small" onDark={onDark} />
    </div>
  );
}
