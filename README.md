# Zetrum

Meteran pengisian mobil dan motor listrik. Pilih kendaraanmu, cari SPKLU di
peta, pindai konektornya, setujui, lalu tinggalkan kendaraannya — persen
baterai, kWh yang masuk, biaya berjalan dan hitung mundur sampai penuh
terus terlihat di layar kunci lewat Live Activity.

Aplikasi contoh, bukan produk PLN. Lokasi SPKLU-nya memakai koordinat tempat
yang nyata, tapi merek, nomor kotak pengisian dan keadaannya karangan.

## Menjalankan

```bash
python3 Tools/genproj.py          # menyusun ulang Zetrum.xcodeproj
open Zetrum.xcodeproj             # ▶︎ ke simulator mana pun, iOS 17+
```

Live Activity-nya baru kelihatan utuh setelah pengisian dimulai: kunci layar
(`Cmd+L`) untuk kartu layar kunci, atau pakai simulator dengan Dynamic Island.

## Alurnya

1. **Garasi** — 57 mobil dan 30 motor listrik yang dijual di Indonesia,
   lengkap dengan kapasitas baterai, soket, daya terima AC/DC dan tabel
   lama isi 20→80% di tiap kelas charger. Pilih satu sebagai kendaraanmu.
2. **SPKLU** — peta OpenStreetMap dengan penanda di rumah sakit, stadion,
   stasiun, mal, rest area, bandara, kantor dan kampus. Bisa disaring per
   jenis tempat, ketersediaan, dan jenis konektor.
3. **Detail stasiun** — tiap kotak pengisian ditulis apa adanya: merek
   charger, soket, daya, tarif, biaya layanan dan keadaannya (tersedia /
   sedang digunakan / dalam perbaikan). Ada ulasan dan fasilitas umum.
4. **Pindai** — tombol tengah membuka kamera untuk kode QR di badan charger.
   Memindai **tidak** langsung mengisi: hasilnya membuka lembar persetujuan.
5. **Setujui** — periksa kendaraan, konektor, persen sekarang, target dan
   perkiraan biaya, lalu **tahan** tombolnya. Baru di detik itu listrik
   dianggap mengalir.
6. **Mengisi / penuh** — satu layar penuh yang berubah dari hijau setrum ke
   biru es begitu target tercapai.

## Isi

| Berkas | Isinya |
| --- | --- |
| `Shared/Charging.swift` | Kurva pengisian bentuk tertutup, biaya, daya |
| `Shared/Places.swift` | Soket, kotak pengisian, jenis tempat, fasilitas |
| `Shared/PlaceData.swift` | 26 lokasi SPKLU Zetrum dengan koordinat sebenarnya |
| `Shared/Vehicles.swift` | Bentuk data kendaraan |
| `Shared/Catalog.swift` | Katalog 87 model EV Indonesia |
| `Shared/Glyphs.swift` | Gambar soket (Type 2, CCS2, CHAdeMO, GB/T) dan siluet kendaraan |
| `Shared/Palette.swift` | Warna, kilat Zetrum, indikator sel baterai |
| `Shared/Odometer.swift` | Angka berguling seperti meteran listrik |
| `Shared/TicketShape.swift` | Bentuk karcis untuk struk |
| `Zetrum/ChargeStore.swift` | Satu-satunya sumber keadaan + Live Activity |
| `Zetrum/Components/OSMMapView.swift` | MKMapView dengan ubin OpenStreetMap |
| `Zetrum/Views/` | Sembilan layar aplikasi |
| `ZetrumWidget/` | Live Activity: layar kunci + Dynamic Island |
| `Tools/genproj.py` | Penyusun `project.pbxproj` |
| `Tools/fetchphotos.py` | Pengambil foto kendaraan dari Wikimedia Commons |

## Kurva pengisian

Daya tidak rata. Sampai 80% arusnya penuh, di atas itu melandai supaya sel
tidak rusak:

```
di bawah 80%:  dSoC/dt = A
di atasnya:    dSoC/dt = A · (1 − b·u),   u = SoC − 80
jawabannya:    u(t) = (1/b)·(1 − e^(−A·b·t))
```

`A = 100·kW/kWh` dan `b = (1 − lantai)/20`. Lantainya ikut daya kotaknya —
pengisian 200 kW melandai jauh lebih tajam daripada wallbox 7,4 kW.

Bentuk tertutup ini dipilih bukan karena rapi, tapi karena bisa dibalik:
waktu selesai diketahui **sejak detik pertama**. Akibatnya hitung mundur di
layar kunci berjalan sendiri tanpa aplikasi perlu dibangunkan, dan kabar
"sudah penuh" bisa dijadwalkan di depan.

Daya yang betul-betul dipakai adalah yang terkecil antara kemampuan kotak
pengisian dan kemampuan kendaraannya menerima. Jadi Wuling Air ev di kotak
200 kW tetap mengisi di 6,6 kW — seperti aslinya.

Contoh, BYD Atto 3 Superior (60,48 kWh) dari 20% ke 80%:

| Kotak | Daya nyata | Lama |
| --- | --- | --- |
| Wallbox rumah 7,4 kW | 7,4 kW | 4 j 54 m |
| AC Type 2 22 kW | 7 kW | 5 j 11 m |
| DC 60 kW | 60 kW | 36 m |
| DC 200 kW | 88 kW | 24 m |

### Pemadat waktu

Angka di tabel itu waktu sungguhan, dan tidak ada yang mau menonton empat
jam pengisian. `Charge.Plan.speed` memadatkan **jam dindingnya saja**:
`soc()` mengalikan waktu yang sudah lewat, `time()` membaginya. Keduanya
tetap pasangan balikan yang tepat, jadi jam selesai yang dipakai Live
Activity tetap benar.

Yang **tidak** ikut dipadatkan: daya, kWh, rupiah dan bentuk kurvanya.
Semuanya diturunkan dari persen baterai, bukan dari jam dinding — jadi
angka di layar tetap angka yang sebenarnya.

Pemadatnya satu tetapan, `Charge.demoSpeed`, tanpa pilihan di antarmuka:
ini aplikasi contoh dan tidak ada gunanya menunggu empat jam. Tabel
spesifikasi di layar kendaraan memakai `speed: 1` supaya tetap menyebut
durasi sungguhan.

## Data

**Kendaraan.** Kapasitas baterai memakai angka kotor (nominal) pabrikan —
tidak ada satu pun sumber Indonesia yang menerbitkan kapasitas bersih, jadi
lebih jujur konsisten pakai satu jenis angka daripada mencampur keduanya.
Daya pengisian mobil memakai spesifikasi global pabrikan kalau versi
Indonesia tidak menerbitkannya. Untuk motor, hampir tidak ada yang
mengumumkan daya chargernya, jadi angkanya dihitung dari waktu pengisian
penuh yang diumumkan — anggap perkiraan, bukan kutipan.

Yang sengaja tidak dimasukkan: **Tesla** (tidak ada agen resmi di Indonesia,
hanya impor umum), **Yamaha E01** dan **NEO's** (tidak pernah dijual di
sini), dan **Yamaha Fazzio Hybrid** — itu motor bensin 124,8 cc dengan
bantuan start listrik tiga detik, bukan EV.

**Tarif.** Memakai skema PLN: Rp 2.466,78/kWh, ditambah biaya layanan untuk
kotak di atas 50 kW.

**Foto.** Diambil dari Wikimedia Commons dengan `Tools/fetchphotos.py` dan
dipakai sesuai lisensinya; daftarnya ada di `CREDITS-PHOTOS.md`. Model yang
tidak punya foto berlisensi bebas — kebanyakan motor listrik lokal —
digambar sebagai siluet per bentuk bodi. Jadi kalau yang muncul gambar,
memang tidak ada fotonya, bukan gagal memuat.

**Peta.** Ubin OpenStreetMap, dua gaya: gelap (CARTO di atas data OSM) dan
terang (ubin resmi OSM). Bisa diganti dari tombol di peta. Permintaan ubin
memakai User-Agent yang jelas sesuai aturan pakai OSM, dan sumbernya
dicantumkan di pojok peta.

## Yang jujur perlu diketahui

Live Activity di sini diperbarui dari dalam aplikasi (`activity.update`),
bukan lewat push notification. Selama aplikasi masih hidup di latar
belakang, angkanya ikut bergerak. Kalau iOS mematikan prosesnya, persen,
kWh dan biaya berhenti di angka terakhir — tapi **hitung mundurnya tetap
benar**, karena yang digambar `Text(timerInterval:)` ke tanggal selesai yang
sudah dihitung sejak awal. Aplikasi SPKLU sungguhan memakai push
notification dari servernya untuk ini.
