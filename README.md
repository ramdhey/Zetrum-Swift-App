# Zetrum

Meteran pengisian mobil listrik. Pilih SPKLU, atur baterai sekarang dan mau
diisi sampai berapa, lalu tinggal. Live Activity di layar kunci dan Dynamic
Island menampilkan persen baterai, kWh yang masuk, biaya yang naik terus, dan
hitung mundur sampai penuh.

## Jalankan

```
open Zetrum.xcodeproj
```

Pilih skema **Zetrum**, jalankan di simulator atau perangkat iOS 17+.
Di perangkat, isi dulu Signing & Capabilities → Team untuk kedua target
(`Zetrum` dan `ZetrumWidget`).

## Isi

| Berkas | Isinya |
| --- | --- |
| `Shared/Charging.swift` | Daftar SPKLU dan seluruh rumus pengisian — satu-satunya sumber angka |
| `Shared/ZetrumAttributes.swift` | Bentuk data yang dikirim ke Live Activity |
| `Shared/Palette.swift` | Warna, kilat Zetrum, dan indikator sel baterai |
| `Shared/Odometer.swift`, `TicketShape.swift`, `Format.swift` | Angka berguling, bentuk struk, penulisan rupiah dan kWh |
| `Zetrum/ChargeStore.swift` | Status sesi, penyimpanan, ActivityKit, dan kabar saat penuh |
| `Zetrum/Views/` | Layar persiapan, panel pengisian, struk, riwayat |
| `ZetrumWidget/ZetrumLiveActivity.swift` | Kartu layar kunci + Dynamic Island |
| `Tools/genproj.py` | Membuat ulang `Zetrum.xcodeproj` dari daftar berkas |

## Kurva pengisiannya

Daya tidak rata. Sampai 80% mengalir penuh, di atas itu melandai supaya sel
tidak rusak — pada DC turun sampai 18% dari daya terpasang di 100%, pada AC
hanya sampai 60%. Rumusnya ditulis dalam bentuk tertutup:

```
di bawah 80%:  dSoC/dt = A
di atasnya:    dSoC/dt = A · (1 − b·u),  u = SoC − 80
jawabannya:    u(t) = (1/b) · (1 − e^(−A·b·t))
```

Karena bentuknya tertutup, waktu selesai bisa dihitung sekali di depan. Itu
yang membuat hitung mundur di layar kunci tetap jalan tanpa aplikasi perlu
dibangunkan, dan kabar "sudah penuh" bisa dijadwalkan dari awal.

Contoh, baterai 64 kWh dari 28%:

| SPKLU | Sampai 80% | Sampai 100% |
| --- | --- | --- |
| Zetrum Home, 7,4 kW AC | 4 jam 30 menit | 6 jam 41 menit |
| Zetrum Senayan, 60 kW DC | 33 menit | 1 jam |
| Zetrum Rest Area 57, 200 kW DC | 9 menit | 18 menit |

## Catatan soal Live Activity

Hitung mundur di layar kunci berjalan sendiri (`Text(timerInterval:)`), jadi
tetap benar walau aplikasi tidak aktif. Angka persen, kWh, dan biaya
diperbarui oleh aplikasi: setiap baterai naik seperempat persen, dan paling
lambat tiap 60 detik. Kalau iOS membekukan aplikasi lama sekali di latar
belakang, angka-angka itu bisa tertinggal sampai aplikasi dibangunkan —
untuk selalu tepat tanpa itu, perlu push notification ke Live Activity
(butuh server dan APNs key).

Kalau aplikasi dibuka lagi sementara pengisian masih jalan, kartunya
disambung kembali, atau dibuat ulang bila sudah hilang.

## Catatan

Angka tarif memakai kisaran tarif PLN untuk SPKLU dan pengisian rumah.
Zetrum sendiri nama karangan untuk aplikasi ini.
