# Parkir Meter

Aplikasi iOS buat mencatat jam mulai parkir dan tarif per jam. Begitu meteran
dijalankan, sebuah Live Activity muncul di layar kunci dan Dynamic Island,
menampilkan durasi berjalan dan total biaya yang naik terus.

## Jalankan

```
open ParkirMeter.xcodeproj
```

Pilih skema **ParkirMeter**, jalankan di simulator atau perangkat iOS 17+.
Di perangkat, isi dulu Signing & Capabilities → Team untuk kedua target
(`ParkirMeter` dan `ParkirMeterWidget`).

## Isi

| Berkas | Isinya |
| --- | --- |
| `Shared/Billing.swift` | Rumus biaya — satu-satunya sumber angka, dipakai app dan widget |
| `Shared/ParkirAttributes.swift` | Bentuk data yang dikirim ke Live Activity |
| `Shared/Palette.swift`, `TicketShape.swift`, `Odometer.swift` | Warna, bentuk karcis, angka berguling |
| `ParkirMeter/ParkingStore.swift` | Status sesi, penyimpanan, dan kendali ActivityKit |
| `ParkirMeter/Views/` | Layar utama, kartu meteran, struk, riwayat |
| `ParkirMeterWidget/ParkirLiveActivity.swift` | Kartu layar kunci + Dynamic Island |

## Dua cara hitung

- **Per jam** — dibulatkan ke atas, seperti tukang parkir. Biaya naik melompat,
  dan aplikasi menghitung mundur ke lompatan berikutnya ("naik ke Rp 6.000
  dalam 17:25"). Ini bagian yang bikin deg-degan.
- **Pro-rata** — dihitung per menit, dibulatkan ke 100 perak terdekat.

## Catatan soal Live Activity

Durasi di layar kunci berjalan sendiri (`Text(timerInterval:)`), jadi tetap
berdetak walau aplikasi tidak aktif. Angka biaya diperbarui oleh aplikasi:
setiap kali nilainya berubah, dan paling lambat tiap 60 detik. Kalau iOS
membekukan aplikasi lama sekali di latar belakang, angka biaya bisa tertinggal
sampai aplikasi dibangunkan lagi — untuk selalu tepat tanpa itu, perlu push
notification ke Live Activity (butuh server dan APNs key).

Kalau aplikasi dibuka lagi sementara sesi masih jalan, kartunya disambung
kembali, atau dibuat ulang bila sudah hilang.
