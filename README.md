# Zetrum

A charging meter for electric cars and motorbikes. Pick your vehicle, find a
charging station on the map, scan the connector, approve, then walk away —
battery percentage, kWh delivered, running cost and the countdown to full
stay visible on the Lock Screen through a Live Activity.

A sample app, not a PLN product. The station coordinates are real places, but
the charger brands, bay numbers and availability are invented.

## Running it

```bash
python3 Tools/genproj.py          # regenerates Zetrum.xcodeproj
open Zetrum.xcodeproj             # ▶︎ to any simulator, iOS 17+
```

The Live Activity only shows up in full once a session has started: lock the
screen (`Cmd+L`) for the Lock Screen card, or use a simulator with a Dynamic
Island.

## The flow

1. **Garage** — 57 electric cars and 30 motorbikes sold in Indonesia, each
   with battery capacity, socket type, AC/DC intake and a 20→80% table per
   charger class. Pick one as your vehicle.
2. **Stations** — an OpenStreetMap view with pins at hospitals, stadiums,
   train stations, malls, rest areas, airports, offices and campuses.
   Filterable by venue type, availability and connector.
3. **Station detail** — every bay written out plainly: charger brand, socket,
   power, tariff, service fee and status (available / in use / under repair).
   Plus reviews and on-site facilities.
4. **Scan** — the centre button opens the camera for the QR code on the
   charger. Scanning does **not** start charging: it opens an approval sheet.
5. **Approve** — check the vehicle, connector, current percentage, target and
   estimated cost, then **hold** the button. Only then is current considered
   to be flowing.
6. **Charging / full** — a single screen that shifts from volt green to ice
   blue the moment the target is reached.

## What's inside

| File | Contents |
| --- | --- |
| `Shared/Charging.swift` | Closed-form charging curve, cost, power |
| `Shared/Places.swift` | Sockets, bays, venue types, facilities |
| `Shared/PlaceData.swift` | 26 Zetrum station locations with real coordinates |
| `Shared/Vehicles.swift` | Vehicle data shape |
| `Shared/Catalog.swift` | Catalogue of 87 Indonesian EV models |
| `Shared/Strings.swift` | Runtime translation table (Indonesian / English) |
| `Shared/Glyphs.swift` | Socket drawings (Type 2, CCS2, CHAdeMO, GB/T) and vehicle silhouettes |
| `Shared/Palette.swift` | Colours, the Zetrum bolt, battery cell indicator |
| `Shared/Odometer.swift` | Rolling digits, like an electricity meter |
| `Shared/TicketShape.swift` | Ticket shape for the receipt |
| `Zetrum/ChargeStore.swift` | The single source of state + the Live Activity |
| `Zetrum/Components/OSMMapView.swift` | MKMapView with OpenStreetMap tiles |
| `Zetrum/Views/` | The nine app screens |
| `ZetrumWidget/` | Live Activity: Lock Screen + Dynamic Island |
| `Tools/genproj.py` | `project.pbxproj` generator |
| `Tools/fetchphotos.py` | Pulls vehicle photos from Wikimedia Commons |

## The charging curve

Power is not flat. Below 80% the current runs at full rate; above it the
curve tapers so the cells aren't damaged:

```
below 80%:   dSoC/dt = A
above it:    dSoC/dt = A · (1 − b·u),   u = SoC − 80
solution:    u(t) = (1/b)·(1 − e^(−A·b·t))
```

`A = 100·kW/kWh` and `b = (1 − floor)/20`. The floor follows the bay's power —
a 200 kW charger tapers far more sharply than a 7.4 kW wallbox.

The closed form was chosen not because it is tidy but because it inverts: the
finish time is known **from the first second**. That is what lets the Lock
Screen countdown run on its own without waking the app, and lets the "fully
charged" notification be scheduled up front.

The power actually used is the smaller of what the bay can deliver and what
the vehicle can take. So a Wuling Air ev on a 200 kW charger still charges at
6.6 kW — exactly as it would in real life.

For example, a BYD Atto 3 Superior (60.48 kWh) from 20% to 80%:

| Bay | Real power | Duration |
| --- | --- | --- |
| Home wallbox 7.4 kW | 7.4 kW | 4 h 54 m |
| AC Type 2 22 kW | 7 kW | 5 h 11 m |
| DC 60 kW | 60 kW | 36 m |
| DC 200 kW | 88 kW | 24 m |

### Time compression

Those are real-world durations, and nobody wants to watch four hours of
charging. `Charge.Plan.speed` compresses **the wall clock only**: `soc()`
multiplies the elapsed time, `time()` divides it. The two remain exact
inverses, so the finish time the Live Activity relies on stays correct.

What is **not** compressed: power, kWh, rupiah and the shape of the curve.
All of them are derived from battery percentage rather than from the clock,
so the numbers on screen are the real ones.

The compressor is a single constant, `Charge.demoSpeed`, with no control in
the interface: this is a sample app and there is nothing to gain from waiting
four hours. The spec table on the vehicle screen uses `speed: 1` so it still
quotes genuine durations.

## Language

Indonesian and English, switchable at runtime from the `ID | EN` pill in the
Home header. The choice is not Apple's String Catalog but a plain table in
`Shared/Strings.swift`, for two reasons: the switch has to take effect
instantly without relaunching, and the widget runs in its own process with no
App Group, so it cannot read the app's settings — the language travels with
each Live Activity update instead.

Numbers, dates and durations follow suit: `Rp 20.000` / `Rp 20,000`,
`19,0 kWh` / `19.0 kWh`, `2j 15m` / `2h 15m`.

## The data

**Vehicles.** Battery capacity uses the manufacturers' gross (nominal)
figures — not one Indonesian source publishes usable capacity, so being
consistent about which kind of number is used is more honest than mixing the
two. Car charging power uses the manufacturer's global spec where the
Indonesian arm doesn't publish one. For motorbikes, almost nobody states
charger power, so the figures are derived from the published full-charge
time — treat them as estimates, not quotes.

Deliberately left out: **Tesla** (no official distributor in Indonesia, grey
imports only), the **Yamaha E01** and **NEO's** (never sold here), and the
**Yamaha Fazzio Hybrid** — that is a 124.8 cc petrol bike with a three-second
electric start assist, not an EV.

**Tariffs.** Follows the PLN scheme: Rp 2,466.78/kWh, plus a service fee for
bays above 50 kW.

**Photos.** Taken from Wikimedia Commons via `Tools/fetchphotos.py` and used
under their licences; the list is in `CREDITS-PHOTOS.md`. Models with no
freely licensed photo — mostly local electric motorbikes — are drawn as
silhouettes by body shape. So if you see a drawing, there genuinely is no
photo; it isn't a failed load.

**Maps.** OpenStreetMap tiles in two styles: dark (CARTO over OSM data) and
light (official OSM tiles). Switchable from a button on the map. Tile
requests carry a clear User-Agent as the OSM usage policy requires, and the
attribution sits in the map's corner.

## Worth knowing

The Live Activity here is updated from inside the app (`activity.update`),
not over push notifications. While the app is still alive in the background
the numbers keep moving — and when charging finishes it fires an
`AlertConfiguration`, so the Dynamic Island expands by itself with a
notification-style banner.

iOS grants roughly 30 seconds of background runtime after the app is
backgrounded. A DC session at the compressed clock finishes well inside that
window. If iOS does kill the process first, the percentage, kWh and cost stop
at their last values — but **the countdown stays correct**, because it is
drawn by `Text(timerInterval:)` against a finish date computed up front, and
the card still learns it is done through its `staleDate` (the system
re-renders it lazily, measured at roughly 90 seconds after the finish time).

A real charging app uses push notifications from its own server for this.
