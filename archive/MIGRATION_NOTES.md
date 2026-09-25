# Migration notes (historical)

> Kept for history: the checklist used while porting the Flutter app in
> `flutter-app/` to the native Android app at the repository root. Paths such
> as `../lib/` refer to the Flutter code as it was then. The current design
> (Wonderous style, Phosphor icons, Arabic/English) replaced the Kimi style
> described below.


Source of truth: `../lib/` (Flutter). This list covers every Flutter feature
**except the recitation plan**. No UI migration: English-only, default
Material3 light theme, no custom fonts/colors/spacing.

Out of scope: recitation plan tab, `RakaPlan`/`DailyRecitationPlan`/
`MonthlyRecitationPlan` models, recitation storage, calendar-grid UI
(`../lib/screens/recitation_plan_screen.dart`, `../lib/models/recitation_plan.dart`).
Also out of scope: Arabic/RTL localization, custom fonts (ElMessiri/Qahiri),
custom colors/spacing/theme port, dark mode, and (dormant in Flutter, no UI —
do not port unless requested) per-prayer departure reminder, per-prayer travel
times, `darkMode` flag (`../lib/models/settings.dart`).

## ✅ Phase 0 — Scaffold (done)
- [x] Gradle project, `:app` module, `com.example.prayernotifier`
- [x] `MainActivity` with `enableEdgeToEdge()` + `WindowInsets.safeDrawing`
- [x] Placeholder `HomeScreen` (TopAppBar outside `LazyColumn`)
- [x] Launcher icon, manifest permissions, README build notes

## Phase 1 — API: Aladhan calendar API (decided ✅ implemented + tested)
- [x] Client for `GET https://api.aladhan.com/v1/calendar/{year}/{month}?latitude={lat}&longitude={lng}`
      (`data/AladhanApi.kt`: Retrofit + kotlinx.serialization, 15s timeouts;
      same endpoint/params as Flutter `PrayerService`)
- [x] Parse into `PrayerTimings` (Fajr/Dhuhr/Asr/Maghrib/Isha, `HH:mm`,
      timezone suffix stripped), `HijriDate`, `PrayerDay`
      (`data/PrayerModels.kt`, `PrayerRepository`; cf. `../lib/models/prayer_times.dart`)
- [x] Tests: `PrayerRepositoryTest` (MockWebServer: mapping + request
      path/query + non-200 error) and `AladhanLiveTest` (real API: Sept 2026
      Mecca → 30 days, all times `HH:mm`) — `./gradlew :app:testDebugUnitTest` green

## Phase 2 — App shell & navigation (`../lib/screens/main_shell.dart`)
- [x] 2-tab shell (Home, Settings) — floating pill nav instead of a bottom
      bar (Kimi style: no full-width bars); no recitation tab, English labels
      (`ui/AppShell.kt`)
- [x] Portrait orientation (`AndroidManifest.xml`)
- [x] State preservation across tabs (both tabs stay composed — IndexedStack
      equivalent, `TabRoot`)

## Phase 3 — Data layer
- [ ] Aladhan client (see Phase 1) with retry (3x, backoff, 15s
      timeout) + JSON parsing (`PrayerTimings`, `HijriDate`, `PrayerDay`;
      cf. `../lib/services/prayer_service.dart`, `../lib/models/prayer_times.dart`)
- [x] Location: FusedLocationProvider, permission handling (cf.
      `../lib/services/location_service.dart`): current fix, reverse-geocode
      place name (English), cached current location, saved-locations list
      (add/update/delete by rounded coords) — `data/location/` (service,
      fused + geocoder providers, prefs/in-memory storage), 13 unit tests green
- [x] Persistence (SharedPreferences for settings, Room for prayer cache;
      local-only, backup disabled): `AppSettings` (per-prayer notif settings,
      time adjustments, hijri offset), prayer-month cache (10-year window, 120
      months), locations — `data/persistence/` (`KeyValueStore` seam so
      encryption can slot in later), tested
- [x] Connectivity observer (online/offline status flow, cf.
      `../lib/services/connectivity_service.dart`) — `data/connectivity/`
      (probe + monitor + system callback glue), tested

## Phase 4 — Home screen (`../lib/screens/home_screen.dart`, `../lib/widgets/`)
- [x] Prayer math (pure, tested): time adjust ±min with midnight wrap,
      next-prayer, countdown incl. tomorrow-Fajr rollover, Hijri offset —
      `data/PrayerMath.kt`, 21 tests green
- [x] Header: floating location pill (tappable → saved places sheet),
      online/offline qualifier, action circles (refresh location, date picker)
      — Kimi floating controls, no top bar (`ui/home/HomeScreen.kt`)
- [x] Date selection: Material3 date picker dialog (2020–2030) + Today chip
      (jump-to-today)
- [x] Hijri date (with adjustment offset) + Gregorian date, English month names
- [x] Prayer list (Fajr/Dhuhr/Asr/Maghrib/Isha) with adjusted times and
      **next-prayer highlight** (blue time + dot) in a floating white card
- [x] Live countdown hero (1s ticker) to next prayer, rolls to tomorrow's Fajr
      after Isha (cf. `PrayerCountdown`)
- [x] Error/empty states: location-required, offline-no-data, generic
      load-error — Kimi empty-state pattern (black primary + tonal secondary)
- [x] Apply per-prayer manual time adjustments everywhere (list, countdown,
      next-prayer, notifications); Home reloads settings on resume

## Phase 5 — Offline support (`../lib/services/prayer_service.dart:119`)
- [x] Month cache in Room, cache-first load (`data/PrayerTimesRepository`:
      saved first, download only when missing, clear offline-no-data error)
- [x] Bulk download ~10 years (prev year → +8, 120 months) with progress (skip cached,
      throttle), success/error dialogs — user-initiated only, no background sync
- [x] Reuse cached location for instant offline startup (`HomeViewModel`: saved
      location first, GPS fix only when nothing is cached)

## Phase 6 — Notifications (`../lib/services/prayer_notitfication_service.dart`)
- [x] Copied `notification.mp3` → `res/raw/`, wired as channel sound
- [x] Channel, high importance, custom sound, no vibration (plain notification —
      no full-screen alarm UI; exact alarms are only the on-time mechanism)
- [x] Schedule today's prayers as exact alarms at `prayerTime − preReminder`;
      skip past times; cancel-all → reschedule; daily 00:01 re-plan alarm;
      re-plan on reboot — `data/notifications/`, 29 tests green
- [ ] Runtime permission flow in UI (POST_NOTIFICATIONS + exact-alarm on
      Android 12+; scheduler already reports denial)
      - Done (2026-09-25): location permission launcher on Home; Settings shows
        a banner opening system notification settings when POST_NOTIFICATIONS
        or exact-alarm is denied (re-checked on resume).

## Phase 7 — Settings screen (`../lib/screens/settings_screen.dart`)
- [x] Hijri correction stepper (−2…+2 days, live save) — bottom-sheet editor
- [x] Per-prayer time correction steppers (±30 min, live save) — bottom-sheet
      editors
- [x] Offline data status card: location name, `x/120 months`, years range,
      progress bar, download button
- [x] Per-prayer notification rows: on/off switch (blue accent) + editor sheet
      (enable switch + 0–60 min reminder slider in 5-min steps + Save/Cancel);
      every save re-plans today's alarms
- Kimi grouped-list style throughout: white ~20dp cards on `#F5F5F5`, 56dp
  rows, outline icons, thin dividers, black primary + tonal secondary buttons.

## Phase 8 — Polish & QA
- [x] Cloud backup disabled (`allowBackup=false`): all data stays on the phone
- [ ] Verify countdown/next-prayer edge cases (after Isha, DST/midnight
      adjustments, negative offsets)
- [ ] Verify notification reschedule matrix (time/location/hijri/reminder change)
- [ ] Device test: offline cold start, permission denials, exact-alarm denied
- [ ] Release build + versioning
