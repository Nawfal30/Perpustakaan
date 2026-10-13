export type CopyStatus = "TERSEDIA" | "DIPINJAM" | "DITAHAN" | "RUSAK" | "DALAM_PERBAIKAN" | "HILANG" | "DITARIK";
export type Book = { id: string; title: string; author: string; category: string; code: string; status: CopyStatus; due?: string; borrower?: string; cover: string; kind: "BUKU" | "PERALATAN" | "LAINNYA" };
export const books: Book[] = [
  { id: "BK-000123", title: "Filosofi Teras", author: "Henry Manampiring", category: "Pengembangan Diri", code: "BK-000123", status: "DIPINJAM", due: "14 Okt 2026", borrower: "Nadia Putri", cover: "linear-gradient(145deg,#dd9f70,#6d403b)", kind: "BUKU" },
  { id: "BK-000124", title: "Laut Bercerita", author: "Leila S. Chudori", category: "Fiksi", code: "BK-000124", status: "TERSEDIA", cover: "linear-gradient(145deg,#b8c9c8,#2a5551)", kind: "BUKU" },
  { id: "BK-000125", title: "Atomic Habits", author: "James Clear", category: "Pengembangan Diri", code: "BK-000125", status: "DIPINJAM", due: "10 Okt 2026", borrower: "Rafi Ahmad", cover: "linear-gradient(145deg,#c5bd9e,#4a5337)", kind: "BUKU" },
  { id: "BK-000126", title: "Bumi Manusia", author: "Pramoedya A. Toer", category: "Sastra", code: "BK-000126", status: "TERSEDIA", cover: "linear-gradient(145deg,#d7aa81,#86482a)", kind: "BUKU" },
  { id: "EQ-000045", title: "Proyektor Epson EB-E01", author: "Epson · 1 unit", category: "Elektronik", code: "EQ-000045", status: "DITAHAN", due: "Klaim s/d 15 Okt", borrower: "Dimas Pratama", cover: "linear-gradient(145deg,#c1cad5,#596d83)", kind: "PERALATAN" },
  { id: "BK-000127", title: "Pulang", author: "Tere Liye", category: "Fiksi", code: "BK-000127", status: "TERSEDIA", cover: "linear-gradient(145deg,#c8b3a0,#705347)", kind: "BUKU" }
];
export const loans = [
  { member: "Nadia Putri", initials: "NP", item: "Filosofi Teras", code: "BK-000123", date: "07 Okt 2026", due: "14 Okt 2026", status: "Aktif", color: "mint" },
  { member: "Rafi Ahmad", initials: "RA", item: "Atomic Habits", code: "BK-000125", date: "03 Okt 2026", due: "10 Okt 2026", status: "Terlambat 3 hari", color: "coral" },
  { member: "Dimas Pratama", initials: "DP", item: "Proyektor Epson EB-E01", code: "EQ-000045", date: "12 Okt 2026", due: "14 Okt 2026", status: "Aktif", color: "blue" },
  { member: "Siti Rahma", initials: "SR", item: "Bumi Manusia", code: "BK-000129", date: "12 Okt 2026", due: "19 Okt 2026", status: "Aktif", color: "lavender" }
];
export const members = [
  {id:"M-000128",name:"Nadia Putri",category:"Warga",loans:2,fines:0,status:"Aktif",initials:"NP"},
  {id:"M-000129",name:"Rafi Ahmad",category:"Warga",loans:1,fines:1500,status:"Aktif",initials:"RA"},
  {id:"M-000130",name:"Dimas Pratama",category:"Pengurus",loans:1,fines:0,status:"Aktif",initials:"DP"},
  {id:"M-000131",name:"Siti Rahma",category:"Warga",loans:1,fines:0,status:"Aktif",initials:"SR"},
  {id:"M-000132",name:"Bima Saputra",category:"Tamu",loans:0,fines:5000,status:"Ditangguhkan",initials:"BS"}
];
export const rupiah = (amount: number) => new Intl.NumberFormat("id-ID", { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(amount);
