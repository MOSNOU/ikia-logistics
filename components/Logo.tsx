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
      let di = i % pi.length; result.push({d,grad:i%2===0?"url(#g1)":"url(#g2)",dash:`${pi[di]*3} ${pi[(di+1)%pi.length]*2}`,w:1.2,op:0.5});
    }
    for (let i = 0; i < 12; i++) {
      let a = (i/12)*Math.PI, d = "M ";
      for (let j = 0; j <= 80; j++) { let t=(j/80)*2*Math.PI; let p=project3D(R*Math.sin(t),R*Math.cos(t)*Math.sin(a),R*Math.cos(t)*Math.cos(a),tiltX,tiltY); d+=(j===0?"":"L ")+`${p.x},${p.y} `; }
      let di=(i+12)%pi.length; result.push({d,grad:i%2===0?"url(#g2)":"url(#g3)",dash:`${pi[di]*3} ${pi[(di+1)%pi.length]*2}`,w:1.2,op:0.5});
    }
    for (let i=-3;i<=3;i++) {
      let lat=(i/4)*Math.PI/2,r=R*Math.cos(lat),z=R*Math.sin(lat),d="M ";
      for (let j=0;j<=80;j++) { let th=(j/80)*2*Math.PI; let p=project3D(r*Math.cos(th),r*Math.sin(th),z,tiltX,tiltY); d+=(j===0?"":"L ")+`${p.x},${p.y} `; }
      result.push({d,grad:i===0?"url(#g3)":"url(#g2)",dash:i===0?"31 16":`${pi[Math.abs(i)]*3} ${pi[Math.abs(i)+1]*2}`,w:i===0?1.5:1.2,op:i===0?0.6:0.5});
    }
    return result;
  }, [R]);
  const nodes = useMemo(() => {
    const result: {x:number;y:number;color:string;size:number}[] = [];
    const lats=[-.942,-.898,-.524,0,.524,.898,.942];
    const counts=[4,8,14,18,14,8,4]; const colors=["#0EA5E9","#3B82F6","#60A5FA"];
    lats.forEach((lat,li)=>{let r=R*Math.cos(lat),z=R*Math.sin(lat);for(let i=0;i<counts[li];i++){let a=(i/counts[li])*2*Math.PI;let p=project3D(r*Math.cos(a),r*Math.sin(a),z,tiltX,tiltY);if(p.z>-R*0.4)result.push({x:p.x,y:p.y,color:colors[li%3],size:li===3?3.5:2.8});}});
    let np=project3D(0,0,R,tiltX,tiltY); if(np.z>-R*0.4) result.push({x:np.x,y:np.y,color:"#0EA5E9",size:3.5});
    let sp=project3D(0,0,-R,tiltX,tiltY); if(sp.z>-R*0.4) result.push({x:sp.x,y:sp.y,color:"#3B82F6",size:3.5});
    return result;
  }, [R]);
  const half = size/2;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} suppressHydrationWarning>
      <defs>
        <linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#BFDBFE"/><stop offset="100%" stopColor="#60A5FA"/></linearGradient>
        <linearGradient id="g2" x1="100%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stopColor="#93C5FD"/><stop offset="100%" stopColor="#3B82F6"/></linearGradient>
        <linearGradient id="g3" x1="0%" y1="100%" x2="100%" y2="0%"><stop offset="0%" stopColor="#60A5FA"/><stop offset="100%" stopColor="#1E40AF"/></linearGradient>
      </defs>
      <g transform={`translate(${half},${half})`} suppressHydrationWarning>
        {paths.map((p,i)=><path key={i} d={p.d} fill="none" stroke={p.grad} strokeWidth={p.w} opacity={p.op} strokeDasharray={p.dash} suppressHydrationWarning/>)}
        {nodes.map((n,i)=>(<g key={`n${i}`} suppressHydrationWarning><circle cx={n.x} cy={n.y} r={Math.round(n.size*1.6*100)/100} fill={n.color} opacity={0.12} suppressHydrationWarning/><circle cx={n.x} cy={n.y} r={n.size} fill={n.color} suppressHydrationWarning/><circle cx={n.x} cy={n.y} r={Math.round(n.size*0.3*100)/100} fill="white" suppressHydrationWarning/></g>))}
      </g>
    </svg>
  );
}

export function LogoText({ size = "large", onDark = false }: { size?: "large"|"medium"|"small"; onDark?: boolean }) {
  const mainSize = size === "large" ? "48px" : size === "medium" ? "26px" : "18px";
  const gap = size === "large" ? "8px" : size === "medium" ? "4px" : "3px";
  return (
    <div dir="ltr" style={{ fontFamily: "'Orbitron', sans-serif", display: "flex", alignItems: "baseline", gap }}>
      <span style={{ fontSize: mainSize, fontWeight: 900, letterSpacing: "3px" }}>
        <span style={{ color: "#B22234" }}>i</span>
        <span style={{ color: onDark ? "#FFFFFF" : "#3C3B6E" }}>KIA</span>
      </span>
      <span style={{ fontSize: mainSize, fontWeight: 700, letterSpacing: "3px", color: onDark ? "rgba(255,255,255,0.85)" : "#3C3B6E" }}>Logistics</span>
    </div>
  );
}

export function LogoHero({ onDark = false }: { onDark?: boolean }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "16px" }}>
      <LogoSphere size={200} />
      <LogoText size="large" onDark={onDark} />
    </div>
  );
}

export function LogoNav({ onDark = false }: { onDark?: boolean }) {
  return (
    <div dir="ltr" style={{ display: "flex", alignItems: "center", gap: "8px" }}>
      <LogoSphere size={40} />
      <LogoText size="small" onDark={onDark} />
    </div>
  );
}
