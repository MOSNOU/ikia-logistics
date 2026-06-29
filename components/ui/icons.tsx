import type { LucideIcon } from "lucide-react";
import {
  Shuffle,
  Radar,
  FileText,
  ShieldCheck,
  ClipboardList,
  Handshake,
  Truck,
  CircleCheckBig,
  Map,
  Smartphone,
  Bell,
  Navigation,
  Route,
  Package,
  Star,
  Tag,
  ReceiptText,
  Lock,
  Hourglass,
  ScrollText,
  Repeat,
  MapPin,
  ListChecks,
  RefreshCw,
  Scale,
  ChartBar,
  TrendingUp,
  Search,
  FolderOpen,
  Building2,
  Users,
  Plug,
  Boxes,
  Circle,
} from "lucide-react";

// Semantic icon registry — content references icons by key (no emojis in UI).
const REGISTRY: Record<string, LucideIcon> = {
  matching: Shuffle,
  tracking: Radar,
  documents: FileText,
  finance: ShieldCheck,
  register: ClipboardList,
  offer: Handshake,
  truck: Truck,
  check: CircleCheckBig,
  map: Map,
  mobile: Smartphone,
  bell: Bell,
  navigation: Navigation,
  route: Route,
  package: Package,
  reliability: Star,
  price: Tag,
  receipt: ReceiptText,
  lock: Lock,
  settlement: Hourglass,
  audit: ScrollText,
  repeat: Repeat,
  pin: MapPin,
  assign: ListChecks,
  lifecycle: RefreshCw,
  compliance: Scale,
  analytics: ChartBar,
  trending: TrendingUp,
  insight: Search,
  report: FolderOpen,
  search: Search,
  enterprise: Building2,
  users: Users,
  api: Plug,
  boxes: Boxes,
};

export function Icon({ name, className }: { name: string; className?: string }) {
  const Cmp = REGISTRY[name] ?? Circle;
  return <Cmp className={className} strokeWidth={1.75} aria-hidden />;
}

export function getIcon(name: string): LucideIcon {
  return REGISTRY[name] ?? Circle;
}
