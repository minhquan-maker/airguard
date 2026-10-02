# AirGuard

Personal carbon tracker for everyday trips — native iOS app built with Swift and SwiftUI.

AirGuard turns each trip into a number you can act on. Log a commute (or let the app detect it), pick the vehicle, and see how many kilograms of CO₂ it cost against a daily budget.

## Features

- **Trip logging** — enter distance and vehicle manually, or record a GPS trip with a route map and summary.
- **Automatic trip detection** — Core Motion plus a GPS speed fallback (motorbikes often never report "automotive") start and end trips for you. Opt-in, with a default vehicle you choose.
- **Daily CO₂ budget** — compare each day against a global reference (6.8 kg CO₂) or a Vietnam default (9.6 kg CO₂), with a stricter mode in Settings.
- **14 vehicle types** — petrol and electric motorbikes, small/medium/large/diesel/hybrid/electric cars, diesel and electric buses, taxi, metro, diesel train and walking.
- **History and stats** — trip history, plus weekly totals with a week-over-week comparison and a last-7-days chart.
- **Live Activity** — a Lock Screen / Dynamic Island widget while a trip is being tracked.
- **Trip-completed notifications** — tap one to open that trip's summary.

## How emissions are calculated

Each trip's CO₂ is `distance (km) × tank-to-wheel emission factor (kg CO₂/km)` for the chosen vehicle. The factors and the research behind them (Vietnamese-language write-up covering the FJCU/ITRI dataset, international comparisons and sources) live in [`dataset_research.html`](dataset_research.html). The values are encoded in [`AirGuard/Core/EmissionEngine.swift`](AirGuard/Core/EmissionEngine.swift).

## Project structure

| Path | What it holds |
| --- | --- |
| `AirGuard/Core/` | Emission engine, theme, trip-summary routing |
| `AirGuard/Models/` | `TripEntry`, `UserProfile` |
| `AirGuard/Services/` | Trip store, motion/GPS auto-tracker, notifications, Live Activity manager |
| `AirGuard/ViewModels/` | Home, log trip, history, stats and settings view models |
| `AirGuard/Views/` | SwiftUI screens and components |
| `AirGuardWidgetExtension/` | Live Activity widget |

## Run it

Requirements: Xcode and an iOS 17.0+ device or simulator. Auto-detection and Live Activities work best on a real device.

```bash
git clone https://github.com/minhquan-maker/airguard.git
cd airguard
open AirGuard.xcodeproj
```

Select the **AirGuard** scheme, choose a device, and press Run. The app asks for location, motion and notification permissions the first time you enable tracking.

## Tech

Swift · SwiftUI · Core Motion · Core Location · ActivityKit / WidgetKit · UserNotifications
