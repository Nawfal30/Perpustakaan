"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { BookOpen, LayoutDashboard, LibraryBig, Users, ArrowLeftRight, BookmarkCheck, Wallet, ChartNoAxesCombined, Settings2, Search, Bell, ChevronDown, CircleHelp, Menu, X, ScanBarcode, Plus, Leaf, LogOut, UserRound, Command } from "lucide-react";

const nav = [
  { label: "Ringkasan", href: "/", icon: LayoutDashboard, group: "MENU UTAMA" },
  { label: "Katalog", href: "/katalog", icon: LibraryBig, group: "MENU UTAMA" },
  { label: "Anggota", href: "/anggota", icon: Users, group: "MENU UTAMA" },
  { label: "Meja sirkulasi", href: "/sirkulasi", icon: ArrowLeftRight, group: "OPERASIONAL", badge: "3" },
  { label: "Reservasi", href: "/reservasi", icon: BookmarkCheck, group: "OPERASIONAL" },
  { label: "Denda & pembayaran", href: "/denda", icon: Wallet, group: "OPERASIONAL" },
  { label: "Laporan", href: "/laporan", icon: ChartNoAxesCombined, group: "LAINNYA" },
  { label: "Pengaturan", href: "/pengaturan", icon: Settings2, group: "LAINNYA" },
];
export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileNav, setMobileNav] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  return <div className="app-frame">
    {mobileNav && <button className="mobile-overlay" onClick={() => setMobileNav(false)} aria-label="Tutup menu" />}
    <aside className={`sidebar ${mobileNav ? "sidebar-open" : ""}`}>
      <div className="brand"><span className="brand-mark"><BookOpen size={21} strokeWidth={2.2}/><span className="brand-leaf"><Leaf size={10}/></span></span><span className="brand-copy"><strong>pustaka<span>bersama</span></strong><small>COMMUNITY LIBRARY</small></span><button className="icon-button sidebar-close" onClick={() => setMobileNav(false)} aria-label="Tutup navigasi"><X size={18}/></button></div>
      <button className="org-switch"><span className="org-avatar">PB</span><span className="org-meta"><b>Pustaka Bersama</b><small>Organisasi utama</small></span><ChevronDown size={15} className="muted"/></button>
      { ["MENU UTAMA", "OPERASIONAL", "LAINNYA"].map(group => <div className="nav-group" key={group}><p className="nav-label">{group}</p>{nav.filter(n => n.group === group).map(item => { const Icon = item.icon; const active = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href); return <Link href={item.href} key={item.href} onClick={() => setMobileNav(false)} className={`nav-item ${active ? "active" : ""}`}><Icon size={18} strokeWidth={active ? 2.2 : 1.8}/><span>{item.label}</span>{item.badge && <i className="nav-badge">{item.badge}</i>}{active && <i className="nav-active-bar"/>}</Link>})}</div>)}
      <div className="sidebar-spacer"/>
      <div className="support-card"><div className="support-icon"><CircleHelp size={17}/></div><b>Butuh bantuan?</b><p>Pelajari cara menggunakan Pustaka Bersama.</p><a href="mailto:bantuan@pustakabersama.id">Pusat bantuan <span>↗</span></a></div>
      <div className="sidebar-foot"><span className="status-dot"/> Semua sistem normal <small>v0.1.0</small></div>
    </aside>
    <div className="main-column">
      <header className="topbar"><button className="icon-button mobile-menu" onClick={() => setMobileNav(true)} aria-label="Buka navigasi"><Menu size={20}/></button><div className="breadcrumb"><span>Workspace</span><span className="crumb-slash">/</span><b>{nav.find(n => n.href === pathname)?.label ?? (pathname.startsWith("/portal") ? "Portal anggota" : "Pustaka Bersama")}</b></div><div className="topbar-actions"><label className="global-search"><Search size={16}/><input aria-label="Cari koleksi atau anggota" placeholder="Cari koleksi, anggota..." value={search} onChange={e=>setSearch(e.target.value)} onKeyDown={e=>{if(e.key === "Enter" && search.trim()) window.location.href=`/katalog?q=${encodeURIComponent(search)}`}}/><kbd><Command size={11}/> K</kbd></label><div className="top-action-wrap"><button className={`icon-button notification-button ${notificationsOpen ? "selected" : ""}`} onClick={()=>setNotificationsOpen(!notificationsOpen)} aria-label="Notifikasi"><Bell size={18}/><i/></button>{notificationsOpen && <div className="popover notifications-pop"><div className="popover-head"><b>Notifikasi</b><span className="mini-pill">2 baru</span></div><div className="notif-row"><span className="notif-icon orange"><Wallet size={15}/></span><span><b>Pengingat denda</b><small>2 anggota memiliki tunggakan.</small><em>12 menit lalu</em></span></div><div className="notif-row"><span className="notif-icon green"><BookmarkCheck size={15}/></span><span><b>Reservasi siap diambil</b><small>Proyektor menunggu klaim anggota.</small><em>48 menit lalu</em></span></div><Link href="/reservasi" className="popover-link" onClick={()=>setNotificationsOpen(false)}>Lihat semua notifikasi</Link></div>}</div><div className="top-divider"/><div className="top-action-wrap"><button className="profile-button" onClick={()=>setProfileOpen(!profileOpen)}><span className="avatar avatar-admin">AD</span><span className="profile-meta"><b>Admin Pustaka</b><small>Administrator</small></span><ChevronDown size={14}/></button>{profileOpen && <div className="popover profile-pop"><Link href="/pengaturan"><UserRound size={15}/> Profil & akun</Link><button onClick={()=>{setProfileOpen(false); alert("Mode demo — autentikasi Supabase akan aktif setelah konfigurasi proyek selesai.")}}><LogOut size={15}/> Keluar</button></div>}</div></div></header>
      <main className="page-main">{children}</main>
      <footer className="app-footer"><span>© 2026 Pustaka Bersama</span><span>Dibuat untuk komunitas, dengan <span className="heart">♥</span></span><Link href="/portal">Portal anggota ↗</Link></footer>
    </div>
  </div>;
}
