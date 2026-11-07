import Foundation

// MARK: - Pilihan bahasa

/// Dua bahasa saja. Nilai mentahnya dipakai untuk menyimpan pilihan dan
/// untuk dikirim ke widget, jadi jangan diubah.
enum Lang: String, Codable, Hashable, CaseIterable, Identifiable {
    case indonesian = "id"
    case english = "en"

    var id: String { rawValue }

    /// Nama bahasanya ditulis dalam bahasa itu sendiri — orang mencari
    /// kata yang dia kenal, bukan terjemahannya.
    var label: String { self == .indonesian ? "Indonesia" : "English" }
    var short: String { self == .indonesian ? "ID" : "EN" }

    /// Dipakai semua DateFormatter supaya nama bulan dan harinya ikut.
    var locale: Locale {
        Locale(identifier: self == .indonesian ? "id_ID" : "en_US")
    }

    /// Angka desimal di Indonesia pakai koma, ribuan pakai titik.
    var decimalMark: String { self == .indonesian ? "," : "." }
    var groupMark: String { self == .indonesian ? "." : "," }
}

/// Bahasa yang sedang dipakai.
///
/// Sengaja sebuah variabel global, bukan nilai yang dioper lewat
/// Environment: tabel teksnya dibaca juga dari luar SwiftUI (pemberitahuan,
/// nama bulan) dan dari proses widget, yang tidak punya akses ke
/// UserDefaults aplikasi. Aplikasi menyetelnya saat pilihan berubah;
/// widget menyetelnya dari kabar yang baru masuk sebelum menggambar.
enum Loc {
    static var lang: Lang = .indonesian
}

// MARK: - Pencarian teks

/// Teks untuk kunci ini dalam bahasa yang sedang dipakai.
func T(_ key: String) -> String {
    guard let pair = Str.table[key] else {
        assertionFailure("kunci terjemahan tidak ada: \(key)")
        return key
    }
    return Loc.lang == .indonesian ? pair.0 : pair.1
}

/// Sama, tapi isinya disisipkan. Persen harfiah ditulis `%%` di tabel.
func T(_ key: String, _ args: CVarArg...) -> String {
    String(format: T(key), arguments: args)
}

/// Teks berjumlah. Bahasa Indonesia tidak mengenal bentuk jamak, jadi
/// kuncinya cuma satu; bahasa Inggris mengambil kunci `<key>.one` kalau
/// jumlahnya tepat satu — supaya tidak keluar "1 models".
func TN(_ key: String, _ n: Int) -> String {
    let one = key + ".one"
    let picked = (Loc.lang == .english && n == 1 && Str.table[one] != nil) ? one : key
    return String(format: T(picked), n)
}

// MARK: - Tabel

/// Satu kunci, dua teks: (Indonesia, English).
///
/// Nama tempat, merek dan model kendaraan tidak ada di sini — itu nama
/// diri, sama di bahasa mana pun.
enum Str {
    static let table: [String: (String, String)] = [

        // MARK: Umum
        "app.ready":            ("Siap mengisi", "Ready to charge"),
        "app.charging":         ("Sedang mengisi", "Charging"),
        "app.full":             ("Sudah penuh", "Fully charged"),
        "common.view":          ("Lihat", "View"),
        "common.close":         ("Tutup", "Close"),
        "common.cancel":        ("Batal", "Cancel"),
        "common.hours24":       ("24 Jam", "24 Hours"),
        "place.open24":         ("Buka 24 Jam", "Open 24 Hours"),
        "map.tileDark":         ("Gelap", "Dark"),
        "map.tileLight":        ("Terang", "Light"),
        "pin.subtitle":         ("%1$d/%2$d konektor tersedia", "%1$d/%2$d connectors free"),
        "common.holdOn":        ("Tahan terus…", "Keep holding…"),

        // MARK: Bar bawah
        "tab.home":             ("Beranda", "Home"),
        "tab.history":          ("Riwayat", "History"),
        "tab.stations":         ("SPKLU", "Stations"),
        "tab.garage":           ("Garasi", "Garage"),
        "strip.full":           ("Sudah penuh — boleh dicabut", "Full — ready to unplug"),
        "strip.charging":       ("Sedang mengisi", "Charging"),

        // MARK: Soket
        "connector.swap":       ("Tukar Baterai", "Battery Swap"),

        // MARK: Keadaan kotak
        "status.idle":          ("Tersedia", "Available"),
        "status.busy":          ("Sedang Digunakan", "In Use"),
        "status.broken":        ("Dalam Perbaikan", "Under Repair"),

        // MARK: Jenis tempat
        "venue.hospital":       ("Rumah Sakit", "Hospital"),
        "venue.stadium":        ("Stadion", "Stadium"),
        "venue.train":          ("Stasiun", "Train Station"),
        "venue.mall":           ("Mal", "Mall"),
        "venue.restArea":       ("Rest Area", "Rest Area"),
        "venue.airport":        ("Bandara", "Airport"),
        "venue.office":         ("Perkantoran", "Office"),
        "venue.campus":         ("Kampus", "Campus"),

        // MARK: Fasilitas
        "facility.toilet":      ("Toilet", "Restroom"),
        "facility.musholla":    ("Musala", "Prayer Room"),
        "facility.minimarket":  ("Minimarket", "Minimart"),
        "facility.cafe":        ("Kafe", "Café"),
        "facility.parking":     ("Parkir", "Parking"),
        "facility.wifi":        ("WiFi", "WiFi"),
        "facility.atm":         ("ATM", "ATM"),
        "facility.restaurant":  ("Restoran", "Restaurant"),
        "facility.lounge":      ("Ruang Tunggu", "Lounge"),

        // MARK: Jenis kendaraan
        "kind.car":             ("Mobil", "Car"),
        "kind.bike":            ("Motor", "Motorbike"),
        "kind.cars":            ("Mobil Listrik", "Electric Cars"),
        "kind.bikes":           ("Motor Listrik", "Electric Bikes"),

        // MARK: Bentuk bodi
        "form.hatchback":       ("Hatchback", "Hatchback"),
        "form.suv":             ("SUV", "SUV"),
        "form.sedan":           ("Sedan", "Sedan"),
        "form.mpv":             ("MPV", "MPV"),
        "form.van":             ("Van", "Van"),
        "form.pickup":          ("Pikap", "Pickup"),
        "form.scooter":         ("Skutik", "Scooter"),
        "form.motorcycle":      ("Motor", "Motorcycle"),

        // MARK: Satuan waktu
        "dur.underMinute":      ("kurang dari semenit", "less than a minute"),
        "dur.minutes":          ("%d menit", "%d min"),
        "dur.hours":            ("%d jam", "%d h"),
        "dur.hoursMinutes":     ("%1$d jam %2$d menit", "%1$d h %2$d min"),
        "dur.tightMinutes":     ("%dm", "%dm"),
        "dur.tightHours":       ("%1$dj %2$dm", "%1$dh %2$dm"),

        // MARK: Beranda
        "home.batteryNow":      ("Baterai Sekarang", "Battery Now"),
        "home.estRange":        ("Perkiraan Jarak", "Est. Range"),
        "home.monthTitle":      ("Konsumsi Bulan Ini", "This Month"),
        "home.energyIn":        ("Listrik Masuk", "Energy In"),
        "home.spent":           ("Pengeluaran", "Spent"),
        "home.sessions":        ("Sesi", "Sessions"),
        "home.co2":             ("Emisi CO₂ yang tidak jadi keluar", "CO₂ emissions avoided"),
        "home.needCharge":      ("Butuh isi daya?", "Need a charge?"),
        "home.tileDC":          ("SPKLU DC", "DC Stations"),
        "home.tileAll":         ("Semua Lokasi", "All Locations"),
        "home.tileFree":        ("Konektor Siap", "Free Connectors"),
        "home.tileModels":      ("Model EV", "EV Models"),
        "home.nearest":         ("SPKLU Terdekat", "Nearest Stations"),
        "home.viewMap":         ("Lihat peta", "View map"),
        "home.homeCharging":    ("Pengisian di rumah", "Home charging"),
        "home.toPercent":       ("ke %@%%", "to %@%%"),
        "home.disclaimer":      ("Lokasi SPKLU di aplikasi ini contoh, bukan data operasional PLN.",
                                 "Station locations in this app are samples, not PLN operational data."),
        "home.language":        ("Bahasa", "Language"),

        // MARK: Baris SPKLU
        "place.connectors":     ("%1$d/%2$d konektor", "%1$d/%2$d connectors"),
        "place.freeOf":         ("%1$d dari %2$d konektor siap", "%1$d of %2$d connectors free"),

        // MARK: Peta
        "map.search":           ("Cari SPKLU, mal, stasiun…", "Search stations, malls, transit…"),
        "map.filterAvailable":  ("Tersedia", "Available"),
        "map.filterDC":         ("Isi Cepat DC", "DC Fast"),
        "map.filterBike":       ("Motor", "Bikes"),
        "map.nearest":          ("Stasiun Terdekat", "Nearest Stations"),
        "map.count":            ("%d lokasi", "%d locations"),
        "map.count.one":        ("%d lokasi", "%d location"),
        "map.empty":            ("Tidak ada SPKLU yang cocok dengan saringan itu.",
                                 "No stations match those filters."),
        "map.viewDetail":       ("Lihat Detail", "View Details"),

        // MARK: Pindai
        "scan.title":           ("Pindai Konektor", "Scan Connector"),
        "scan.aim":             ("Arahkan ke kode QR di badan charger",
                                 "Point at the QR code on the charger"),
        "scan.stillApprove":    ("Setelah terbaca, kamu masih diminta menyetujui dulu\nsebelum listriknya mengalir.",
                                 "Once it reads, you still have to approve\nbefore any power flows."),
        "scan.manualButton":    ("Masukkan kode konektor", "Enter connector code"),
        "scan.hintCamera":      ("Kode contoh ada di daftar kode manual.",
                                 "Sample codes are in the manual list."),
        "scan.hintNoCamera":    ("Kamera tidak tersedia di perangkat ini — pakai kode manual.",
                                 "No camera on this device — use a manual code."),
        "scan.codeTitle":       ("Kode Konektor", "Connector Code"),
        "scan.codeHelp":        ("Kode ini tercetak di stiker badan charger, di bawah kode QR-nya.",
                                 "This code is printed on the charger sticker, below its QR code."),
        "scan.nearbyCodes":     ("Konektor di sekitarmu", "Connectors near you"),
        "scan.unknown":         ("Kode %@ tidak dikenali", "Code %@ not recognised"),

        // MARK: Persetujuan
        "confirm.found":        ("Konektor terbaca", "Connector found"),
        "confirm.checkFirst":   ("Periksa dulu, baru setujui.", "Check it over, then approve."),
        "confirm.batteryNow":   ("Baterai Sekarang", "Battery Now"),
        "confirm.chargeTo":     ("Isi Sampai", "Charge To"),
        "confirm.accepts":      ("%1$@ kWh · terima %2$@ kW", "%1$@ kWh · accepts %2$@ kW"),
        "confirm.estTime":      ("Perkiraan", "Estimated"),
        "confirm.energyIn":     ("Listrik Masuk", "Energy In"),
        "confirm.rangeAdded":   ("Tambah Jarak", "Range Added"),
        "confirm.estCost":      ("Perkiraan Bayar", "Estimated Cost"),
        "confirm.plusService":  ("  +  layanan %@", "  +  service %@"),
        "confirm.hold":         ("Tahan untuk mulai mengisi", "Hold to start charging"),
        "confirm.notReady":     ("Belum bisa dimulai", "Can't start yet"),
        "confirm.consent":      ("Dengan menahan tombol, kamu setuju listrik mulai mengalir dan biayanya dihitung sejak detik itu.",
                                 "By holding the button you agree that power starts flowing and billing begins from that second."),
        "confirm.wrongPort":    ("Konektor ini %1$@, sedangkan %2$@ pakai %3$@. Pilih konektor lain.",
                                 "This connector is %1$@, but the %2$@ uses %3$@. Pick another connector."),
        "confirm.unitBusy":     ("Kotak ini %@. Coba konektor lain di lokasi yang sama.",
                                 "This unit is %@. Try another connector at the same site."),

        // MARK: Layar pengisian
        "charge.fullTitle":     ("Sudah Penuh", "Fully Charged"),
        "charge.busyTitle":     ("Sedang Mengisi", "Charging"),
        "charge.kwMax":         ("kW maks", "kW max"),
        "charge.target":        ("Target", "Target"),
        "charge.startedAt":     ("Mulai dari %@%%", "Started at %@%%"),
        "charge.rangeAdded":    ("+%d km jarak tempuh", "+%d km of range"),
        "charge.doneTitle":     ("Pengisian selesai", "Charging complete"),
        "charge.doneBody":      ("Silakan cabut konektornya supaya tidak kena biaya diam.",
                                 "Unplug the connector so idle fees don't start."),
        "charge.fullIn":        ("Penuh dalam", "Full in"),
        "charge.doneAt":        ("Perkiraan Jam", "Done At"),
        "charge.energyIn":      ("Listrik Masuk", "Energy In"),
        "charge.powerNow":      ("Daya Sekarang", "Power Now"),
        "charge.elapsed":       ("Sudah Jalan", "Elapsed"),
        "charge.batteryAdded":  ("Baterai Terisi", "Battery Added"),
        "charge.runningCost":   ("Biaya Berjalan", "Running Cost"),
        "charge.includesFee":   ("Sudah termasuk biaya layanan %@", "Includes a %@ service fee"),
        "charge.holdUnplug":    ("Tahan untuk cabut & bayar", "Hold to unplug & pay"),
        "charge.holdStop":      ("Tahan untuk hentikan", "Hold to stop"),
        "charge.footDone":      ("Kabar sudah dikirim — kendaraan boleh dijemput",
                                 "Notification sent — your vehicle is ready"),
        "charge.footBusy":      ("Boleh ditinggal. Kartunya terus menghitung di layar kunci.",
                                 "Safe to leave. The card keeps counting on your lock screen."),
        "charge.none":          ("Tidak ada pengisian berjalan", "No charging session running"),

        // MARK: Detail stasiun
        "station.bays":         ("%d Kotak Pengisian", "%d Charging Bays"),
        "station.bays.one":     ("%d Kotak Pengisian", "%d Charging Bay"),
        "station.availableOf":  ("%1$d/%2$d Tersedia", "%1$d/%2$d Available"),
        "station.directions":   ("Navigasi", "Directions"),
        "station.tabBays":      ("Kotak Pengisian", "Bays"),
        "station.tabReviews":   ("Ulasan", "Reviews"),
        "station.tabFacilities":("Fasilitas", "Amenities"),
        "station.updated":      ("Diperbarui %@", "Updated %@"),
        "station.noFit":        ("Tidak ada konektor di sini yang cocok dengan %1$@. Kendaraan itu pakai %2$@.",
                                 "No connector here fits the %1$@. That vehicle uses %2$@."),
        "station.queueHint":    ("Konektor sedang dipakai? Pindai kode QR di badan charger untuk masuk antrean.",
                                 "Connector busy? Scan the QR code on the charger to join the queue."),
        "station.reviewCount":  ("%d ulasan", "%d reviews"),
        "station.reviewCount.one": ("%d ulasan", "%d review"),
        "station.whileWaiting": ("Yang bisa dipakai sambil menunggu", "What's here while you wait"),
        "station.open24Note":   ("Lokasi ini buka 24 jam, jadi aman kalau kendaraannya ditinggal semalam.",
                                 "This site is open 24 hours, so leaving the vehicle overnight is fine."),
        "station.hoursNote":    ("Jam buka %@. Pastikan pengisiannya selesai sebelum tutup.",
                                 "Open %@. Make sure charging finishes before closing time."),
        "station.oneConnector": ("1 Konektor · %@", "1 Connector · %@"),
        "station.serviceFee":   ("Biaya Layanan : %@", "Service Fee : %@"),
        "station.estTime":      ("Perkiraan", "Est. Time"),
        "station.estEnergy":    ("Masuk", "Energy"),
        "station.estCost":      ("Bayar", "Cost"),
        "station.calcNote":     ("Dihitung untuk %1$@ dari %2$@%% ke %3$@%%, daya nyata %4$@ kW.",
                                 "Calculated for the %1$@ from %2$@%% to %3$@%%, real power %4$@ kW."),
        "station.portMismatch": ("Konektor %1$@ tidak cocok dengan %2$@.",
                                 "A %1$@ connector doesn't fit the %2$@."),
        "station.btnRunning":   ("Masih ada sesi berjalan", "A session is already running"),
        "station.btnNoFit":     ("Konektor tidak cocok", "Connector doesn't fit"),
        "station.btnChoose":    ("Pilih konektor ini", "Choose this connector"),
        "station.btnBusy":      ("Sedang digunakan", "In use"),
        "station.btnBroken":    ("Dalam perbaikan", "Under repair"),

        // MARK: Garasi
        "garage.title":         ("Garasi", "Garage"),
        "garage.subtitle":      ("%d model EV di Indonesia", "%d EV models in Indonesia"),
        "garage.subtitle.one":  ("%d model EV di Indonesia", "%d EV model in Indonesia"),
        "garage.mine":          ("Kendaraan Saya", "My Vehicle"),
        "garage.nickname":      ("Nama panggilan", "Nickname"),
        "garage.battery":       ("Baterai", "Battery"),
        "garage.range":         ("Jarak", "Range"),
        "garage.fastCharge":    ("Isi Cepat", "Fast DC"),
        "garage.search":        ("Cari merek atau model…", "Search brand or model…"),
        "garage.noMatch":       ("Tidak ada model yang cocok dengan “%@”.", "No model matches “%@”."),
        "garage.modelCount":    ("%d model", "%d models"),
        "garage.modelCount.one":("%d model", "%d model"),
        "garage.acOnly":        ("AC saja", "AC only"),
        "garage.sourceNote":    ("Spesifikasi diambil dari pabrikan dan media otomotif Indonesia. Kapasitas baterai memakai angka kotor; daya pengisian motor dihitung dari waktu pengisian yang diumumkan pabrikannya.",
                                 "Specs come from manufacturers and Indonesian motoring press. Battery figures are gross capacity; motorbike charging power is derived from the full-charge time each maker publishes."),

        // MARK: Detail kendaraan
        "vehicle.fastDC":       ("Isi Cepat DC", "DC Fast Charge"),
        "vehicle.battery":      ("Baterai", "Battery"),
        "vehicle.claimedRange": ("Jarak Klaim", "Claimed Range"),
        "vehicle.efficiency":   ("Efisiensi", "Efficiency"),
        "vehicle.acMax":        ("AC Maks", "AC Max"),
        "vehicle.dcMax":        ("DC Maks", "DC Max"),
        "vehicle.zeroToFull":   ("Isi 0–100%", "0–100% Time"),
        "vehicle.ports":        ("Soket", "Ports"),
        "vehicle.fastPort":     ("Pengisian cepat", "Fast charging"),
        "vehicle.dailyPort":    ("Pengisian harian", "Daily charging"),
        "vehicle.tableTitle":   ("Lama isi 20% → 80%", "20% → 80% charge time"),
        "vehicle.notSupported": ("tidak bisa", "not supported"),
        "vehicle.tableNote":    ("Kalau kendaraannya cuma sanggup menerima daya lebih kecil dari kotaknya, yang dipakai kemampuan kendaraannya — itu sebabnya beberapa baris waktunya sama.",
                                 "When the vehicle accepts less power than the charger can give, the vehicle's limit is what counts — that's why some rows share the same time."),
        "vehicle.isMine":       ("Ini kendaraan saya", "This is my vehicle"),
        "vehicle.makeMine":     ("Jadikan kendaraan saya", "Make this my vehicle"),

        // MARK: Riwayat
        "history.title":        ("Riwayat", "History"),
        "history.subtitle":     ("%d sesi tercatat", "%d sessions logged"),
        "history.subtitle.one": ("%d sesi tercatat", "%d session logged"),
        "history.energyUse":    ("Konsumsi Energi", "Energy Use"),
        "history.totalEnergy":  ("Total Pembelian", "Total Energy"),
        "history.spent":        ("Pengeluaran", "Spent"),
        "history.avgDuration":  ("Rata-rata Durasi", "Avg Duration"),
        "history.frequency":    ("Frekuensi", "Sessions"),
        "history.unitSession":  ("sesi", "×"),
        "history.co2Saved":     ("Hemat CO₂", "CO₂ Saved"),
        "history.monthly":      ("Riwayat Bulanan", "Monthly History"),
        "history.noChart":      ("Belum ada data grafik.", "No chart data yet."),
        "history.allSessions":  ("Semua Sesi", "All Sessions"),
        "history.emptyTitle":   ("Belum pernah mengisi.", "No charges yet."),
        "history.emptyBody":    ("Pindai konektor di SPKLU untuk mulai.",
                                 "Scan a connector at a station to get started."),
        "history.clearTitle":   ("Hapus seluruh riwayat?", "Delete all history?"),
        "history.clearConfirm": ("Hapus semua", "Delete all"),
        "history.clearBody":    ("Semua catatan pengisian akan hilang dan tidak bisa dikembalikan.",
                                 "Every charging record will be gone and can't be restored."),

        // MARK: Struk
        "receipt.title":        ("BUKTI PENGISIAN", "CHARGING RECEIPT"),
        "receipt.vehicle":      ("Kendaraan", "Vehicle"),
        "receipt.connector":    ("Konektor", "Connector"),
        "receipt.code":         ("Kode", "Code"),
        "receipt.start":        ("Mulai", "Start"),
        "receipt.end":          ("Selesai", "End"),
        "receipt.duration":     ("Lama", "Duration"),
        "receipt.battery":      ("Baterai", "Battery"),
        "receipt.energyIn":     ("Listrik Masuk", "Energy In"),
        "receipt.rangeAdded":   ("Tambah Jarak", "Range Added"),
        "receipt.rate":         ("Tarif", "Rate"),
        "receipt.serviceFee":   ("Biaya Layanan", "Service Fee"),
        "receipt.total":        ("TOTAL", "TOTAL"),
        "receipt.thanks":       ("Terima kasih sudah pakai listrik.", "Thanks for going electric."),

        // MARK: Live Activity
        "la.battery":           ("Baterai", "Battery"),
        "la.cost":              ("Biaya", "Cost"),
        "la.kwhIn":             ("%@ kWh masuk", "%@ kWh in"),
        "la.in":                ("  masuk", "  in"),
        "la.done":              ("sudah penuh", "fully charged"),
        "la.fullIn":            ("penuh dalam", "full in"),
        "la.charging":          ("mengisi…", "charging…"),
        "la.compactDone":       ("PENUH", "FULL"),
        "la.alertBody":         ("%1$@ sudah %2$@%% — boleh dicabut.", "%1$@ reached %2$@%% — ready to unplug."),

        // MARK: Pemberitahuan
        "notify.title":         ("Pengisian selesai", "Charging complete"),
        "notify.body":          ("%1$@ sudah %2$@%% di %3$@. Total %4$@.",
                                 "%1$@ reached %2$@%% at %3$@. Total %4$@."),

        // MARK: Ulasan contoh — kapan
        "review.when0":         ("2 hari lalu", "2 days ago"),
        "review.when1":         ("seminggu lalu", "a week ago"),
        "review.when2":         ("2 minggu lalu", "2 weeks ago"),
        "review.when3":         ("bulan lalu", "last month"),

        // MARK: Ulasan contoh — puas
        "review.good0":         ("Chargernya gampang dipakai, sekali tempel kartu langsung jalan. Parkirnya juga luas.",
                                 "Easy charger to use — one tap of the card and it started. Plenty of parking too."),
        "review.good1":         ("Ditinggal makan sebentar, balik-balik sudah 80%. Puas.",
                                 "Left it while I grabbed lunch and came back to 80%. Happy with that."),
        "review.good2":         ("Posisinya gampang dicari, petugasnya bantu colokin kabel.",
                                 "Easy to find, and the attendant helped plug the cable in."),
        "review.good3":         ("Dari 20% ke 80% cuma setengah jam. Tarifnya sesuai aplikasi.",
                                 "20% to 80% in just half an hour. The rate matched the app."),
        "review.good4":         ("Tempatnya teduh dan bersih, ada musala. Cocok buat nunggu lama.",
                                 "Shaded and clean, with a prayer room. Good spot for a long wait."),

        // MARK: Ulasan contoh — biasa saja
        "review.mixed0":        ("Antre lumayan karena cuma ada beberapa kotak. Datang pagi lebih aman.",
                                 "Bit of a queue since there are only a few bays. Mornings are safer."),
        "review.mixed1":        ("Satu konektor lagi diperbaiki, jadi harus gantian. Sisanya oke.",
                                 "One connector was under repair so we had to take turns. Otherwise fine."),
        "review.mixed2":        ("Kabelnya agak pendek, mobil harus mundur pas banget.",
                                 "The cable is a little short — you have to reverse in just right."),
    ]

    /// Kalimat ulasan contoh, sudah dalam bahasa yang sedang dipakai.
    static var reviewWhens: [String] { (0..<4).map { T("review.when\($0)") } }
    static var reviewGood: [String] { (0..<5).map { T("review.good\($0)") } }
    static var reviewMixed: [String] { (0..<3).map { T("review.mixed\($0)") } }
}
