# Cover — Product Requirements Document (Flutter)

Cover is a privacy vault app that **disguises itself as a calculator** while protecting user content with **on-device encryption**, **decoy vaults**, **intruder defense**, and **Remote-Config-driven product control**. The UX target is “Apple-level”: calm, minimal, fluid, and fast.

## 1) Non‑Negotiable Principles
- **On-device only privacy**: no cloud backup, no accounts, no server-side storage of user content.
- **Security-first defaults**: lock-on-background, least-privilege permissions, secure storage.
- **Remote Config first**: user-facing limits, paywall behavior, UI experiments, and feature toggles controlled via Firebase Remote Config, with safe local defaults.
- **Decoy parity**: decoy vault must look/behave identical to the real vault.
- **Performance**: smooth 60–120fps interactions on modern devices; graceful behavior on low-end devices.

## 1.5 UI/UX Excellence Mandate (Apple‑Level Quality)

### Design Benchmark
Every screen, transition, and interaction must meet or exceed iOS native app quality. Reference apps: Apple Photos, Apple Notes, 1Password, Signal.

### Motion & Animation Standards
- **Page Transitions**: 300ms spring curve (Curves.elasticOut or custom spring: damping=0.85, stiffness=200)
- **Tab Switches**: Shared axis transition (horizontal slide, 250ms)
- **Micro-interactions**: 
  - Button tap: Scale 0.97 → spring back to 1.0 (150ms)
  - List item tap: Background flash + subtle scale
  - Success states: Lottie confetti or checkmark animation
- **Haptic Feedback Map**:
  - Light: Calculator key press, toggle switch
  - Medium: Tab switch, item selection
  - Heavy: Unlock success, purchase complete
  - Warning: Failed PIN, intruder alert

### Visual Language
- **Typography**: SF Pro Display (iOS) / Inter (Android) via Google Fonts
- **Corner Radius System**:
  - Small (buttons, chips): 8dp
  - Medium (cards, sheets): 16dp
  - Large (modals): 24dp
- **Spacing Grid**: 4dp base unit (4, 8, 12, 16, 24, 32, 48)
- **Shadows**: Subtle, layered (use BoxShadow with low opacity, never harsh black)
- **Glassmorphism**: BackdropFilter with blur sigma 10-20 for modals and sheets
- **Dark Theme**: True black (#000000) for OLED battery savings, #121212 for surfaces

### Bottom Navigation Bar Specifications
- Height: 80dp (includes safe area)
- Active item: SF Symbol filled variant, accent color background (capsule shape, 8dp padding horizontal, 4dp vertical)
- Inactive items: SF Symbol regular variant, 60% opacity white/gray
- Labels: 12sp, medium weight, visible only on active item (optional via RC)
- Indicator: Smooth sliding pill that animates between tabs (spring physics)

### Empty States
- Custom vector illustration centered
- Friendly, non-technical copy
- Clear primary CTA button with accent color

### Loading States
- Shimmer effect for thumbnails (never blank squares)
- Skeleton screens for list items during initial load
- Progress indicators for imports use determinate circular progress with percentage

### Accessibility Requirements
- Minimum touch target: 48x48dp
- Color contrast: WCAG 2.1 AA (4.5:1 for text)
- Dynamic Type: Support up to 200% font scale without breaking layouts
- VoiceOver/TalkBack: All interactive elements must have semantic labels

### Implementation Checklist (Per Screen)
- [ ] Haptics integrated on all tappable elements
- [ ] Spring animations used (no linear curves)
- [ ] Touch targets ≥ 48dp
- [ ] Dark theme verified (OLED black where appropriate)
- [ ] Empty/loading/error states handled
- [ ] Backdrop blur used on overlays
- [ ] Semantic labels added

## 2) Target Platforms
- **Android**: primary (supports more stealth features).
- **iOS**: fully supported, with platform constraints documented.

## 3) Personas & Jobs-To-Be-Done
### Personas
- **Privacy-conscious user**: wants to hide sensitive photos/videos/files.
- **Casual user**: wants a simple “secret folder” that’s easy to use.
- **High-risk user**: needs decoy vault and intruder evidence.

### Core Jobs
- Unlock vault discreetly.
- Import content quickly.
- View/manage content without leaving traces.
- Recover from mistakes safely (export, restore, backups are local-only).
- Defend against guessing/forced access (decoy, lockout, intruder capture).

## 4) Core User Journeys
### 4.1 First Run
- User sees calculator.
- Optional onboarding overlay (Remote Config) explains “PIN via calculator pattern”.
- User sets:
  - **Primary PIN** (real vault)
  - **Decoy PIN** (optional but strongly encouraged)
  - Optional biometrics

### 4.2 Unlock
- User types pattern (e.g., `{pin}+0=`) inside calculator.
- Correct PIN → vault opens.
- Decoy PIN → decoy vault opens.
- Wrong attempts → lockout and optional intruder capture.

### 4.3 Import
- Gallery import (multi-select) and file import.
- App copies content into encrypted app-private storage.
- App generates encrypted thumbnails/previews.
- App removes traces (best-effort; platform limitations disclosed).

### 4.4 View/Manage
- Bottom nav: Gallery, Files, Notes, Passwords, Contacts, Settings (tabs can be RC-hidden).
- Search (within allowed/implemented constraints).
- Export/share requires explicit confirmation; temporary decrypted artifacts are cleaned up.

### 4.5 Intruder Event
- After configurable wrong attempts, silently capture front camera photo(s) + timestamp.
- Optional location capture if obtained quickly.
- User sees “intruder reports” inside Settings.

### 4.6 Panic / Emergency Close
- Configurable gesture (shake) closes vault instantly → calculator.

## 5) Functional Requirements (by Module)

## 5.1 Security & Cryptography
### Requirements
- AES‑256‑GCM for content encryption.
- PBKDF2 for PIN-derived keys (iterations RC-controlled; sensible default).
- Keys stored in platform secure storage (Keystore/Keychain) where possible.
- Encrypted DB using Drift + SQLCipher.

### Notes / Constraints
- “Secure delete” is **best-effort** on mobile storage; document limitations (journaling/SSD wear-leveling).

### Remote Config (Security)
```json
{
  "encryption_algorithm": "AES-256-GCM",
  "key_derivation_iterations": 100000,
  "min_pin_length": 4,
  "max_pin_length": 12,
  "lock_on_background": true,
  "auto_lock_inactivity_seconds": 30,
  "clipboard_timeout_seconds": 20,
  "deny_screenshots_android": true,
  "blur_app_switcher_ios": true
}
```

## 5.2 Calculator Camouflage
### Requirements
- Real working calculator UI.
- PIN entry via equation syntax (pattern RC-controlled).
- No visual tell when unlocking.
- Advanced calculator features toggled via RC.

### Remote Config (Calculator)
```json
{
  "pin_pattern": "{pin}+0=",
  "decoy_pin_pattern": "{pin}+1=",
  "enable_advanced_calculator": true,
  "calculator_style": "ios",
  "max_pin_attempts_before_lockout": 3,
  "lockout_duration_minutes": 15
}
```

## 5.3 Vault Shell + Navigation
### Requirements
- Persistent bottom navigation.
- State preservation per tab.
- Smooth transitions and haptics.

### Default Tabs
- **Gallery** (photos/videos)
- **Files**
- **Notes**
- **Passwords**
- **Contacts**
- **Settings**

### Remote Config (Navigation/UI)
```json
{
  "bottom_nav_style": "labeled",
  "animation_duration_ms": 300,
  "enable_haptic_feedback": true,
  "vault_grid_columns": 3,
  "show_tutorial_on_first_launch": true,
  "tabs_enabled": {
    "gallery": true,
    "files": true,
    "notes": true,
    "passwords": true,
    "contacts": true
  }
}
```

## 5.4 Content Hiding — Photos & Videos
### Requirements
- Multi-select import.
- Encrypted storage with randomized filenames.
- Encrypted thumbnails.
- Viewer decrypts to memory; avoids writing plaintext to disk.

### Remote Config (Media)
```json
{
  "thumbnail_quality": 80,
  "max_import_batch_size": 100,
  "secure_delete_passes": 3
}
```

## 5.5 Content Hiding — Files
### Requirements
- Import any file type.
- Encrypted tree view / folders.
- Open-in viewer by type where possible (PDF, images); otherwise export-to-open flow.

## 5.6 Secure Notes
### Requirements
- Create/read/update/delete notes.
- Optional folders/tags.
- Search strategy documented:
  - Default: title-only search or local decrypted index with clear risk notes.

### Remote Config (Notes)
```json
{
  "notes_enabled": true,
  "notes_search_mode": "title_only"
}
```

## 5.7 Password Vault
### Requirements
- Store entries: title, username, password, URL, notes.
- Password generator.
- Clipboard copy with timeout.
- Autofill: **document feasibility per OS** (may be later phase).

### Remote Config (Passwords)
```json
{
  "passwords_enabled": true,
  "password_generator_min": 12,
  "password_generator_max": 32
}
```

## 5.8 Private Contacts
### Requirements
- Store encrypted contacts.
- Display and search.
- Optional external intent actions (call/SMS) with explicit warning: leaving vault may expose metadata.

### Remote Config (Contacts)
```json
{
  "contacts_enabled": true,
  "contacts_allow_external_intents": false
}
```

## 5.9 Intruder Defense
### Requirements
- Wrong attempt counter.
- After threshold: capture front camera image(s) + timestamp.
- Optional location capture with short timeout.
- Intruder report screen.

### Remote Config (Intruder)
```json
{
  "intruder_enabled": true,
  "max_attempts_before_capture": 2,
  "capture_count_per_attempt": 2,
  "location_timeout_seconds": 5,
  "enable_screenshot_detection": true,
  "shake_sensitivity": 2.5
}
```

## 5.10 Biometrics (A/B Tested)
### Requirements
- Available to all users.
- Always retain PIN fallback.
- RC controls prompt timing and UI placement.

### Remote Config (Biometrics Experiments)
```json
{
  "biometrics_enabled": true,
  "biometrics_prompt_variant": "after_first_unlock",
  "biometrics_paywall_variant": "none"
}
```

## 5.11 Monetization
### Subscriptions
- Monthly, yearly, lifetime.
- Entitlements verified on startup; cached locally.

### Ads
- Banner/interstitial/rewarded.
- Premium removes ads.
- Frequency capping RC-controlled.

### Remote Config (Monetization)
```json
{
  "max_free_items": 50,
  "max_free_vaults": 1,
  "upsell_trigger_items_remaining": 10,
  "upsell_trigger_after_days": 3,
  "banner_enabled": true,
  "interstitial_enabled": true,
  "rewarded_enabled": true,
  "interstitial_min_interval_minutes": 10
}
```

## 5.12 Remote Config System
### Requirements
- Safe defaults embedded in app.
- Config fetch on cold start + resume with caching.
- Versioning + kill switches.

### Remote Config (System)
```json
{
  "config_fetch_interval_minutes": 60,
  "config_minimum_fetch_interval": 15,
  "enable_realtime_config": true,
  "config_version": "1.0.0",
  "kill_switch_app_disabled": false
}
```

## 6) Non‑Functional Requirements
- **Reliability**: no data loss on crash; atomic writes; recovery paths.
- **Accessibility**: touch targets, semantics, dynamic text.
- **Privacy**: analytics is event-minimized; never logs sensitive content.
- **Compliance**: camera/location permissions clearly explained; region/legal constraints acknowledged.

## 7) Analytics (Privacy-Aware)
Track only what’s needed to iterate:
- `app_open`, `calculator_used`, `unlock_success`, `unlock_fail`, `decoy_unlock`, `import_started`, `import_completed`, `export_started`, `purchase_viewed`, `purchase_completed`, `ad_impression`.

## 8) Risks & Constraints
- Secure delete and “remove traces” are best-effort.
- iOS restrictions limit app-hiding/launcher tricks.
- Intruder capture legality varies; behavior may be region-configured.

## 9) Technical Stack (Flutter)
- Flutter 3.19+ / Dart 3.3+
- Drift + SQLCipher
- `encrypt`, `cryptography`, `flutter_secure_storage`
- `photo_manager`, `file_picker`, `camera`, `geolocator`
- `firebase_remote_config`, analytics/crash/perf
- `in_app_purchase`, `google_mobile_ads`
- `go_router` navigation

## 10) 27-Phase Delivery Roadmap (small, safe increments)
Each phase should end with:
- A demoable slice
- Tests for the slice
- RC keys integrated (where relevant)
- Regression checklist updated

### Phase 0 — Project Setup & CI
- Flutter project baseline, architecture skeleton, Codemagic debug pipeline.

### Phase 1 — Crypto Primitives
- AES-GCM utilities, PBKDF2 derivation, test vectors.

### Phase 2 — Secure Key Storage
- Master key storage in Keystore/Keychain; rotation strategy documented.

### Phase 3 — Encrypted Database
- Drift + SQLCipher, entities, migrations scaffolding.

### Phase 4 — Secure Storage Manager
- Encrypted file write/read APIs, UUID naming, directory layout.

### Phase 5 — Calculator UI MVP
- Core calculator interactions + rendering style.

### Phase 6 — PIN Pattern Detection
- Pattern parser, state machine, lockout behavior.

### Phase 7 — Decoy Vault Plumbing
- Separate vault namespace/data; parity checks.

### Phase 8 — Vault Shell + Bottom Nav (5 days)

#### Deliverables
- [ ] `VaultScreen` with `Scaffold` + `BottomNavigationBar`
- [ ] Custom bottom nav widget (not default Material; build custom for Apple feel)
- [ ] 4 tabs: Gallery, Files, Notes(passwords also), Settingsl, RC-gated)
- [ ] `PageView` or `IndexedStack` for tab content with state preservation (`AutomaticKeepAliveClientMixin`)
- [ ] Shared axis transition between tabs (horizontal slide, spring curve)
- [ ] Sliding pill indicator that animates between tabs
- [ ] Haptics on tab selection (`Haptics.medium()`)
- [ ] Deep link support: calculator PIN can route directly to specific tab (RC-controlled)
- [ ] Back button behavior: first back returns to calculator, second back minimizes app

#### UI/UX Acceptance Criteria
- [ ] Tab switch animation is butter-smooth at 120fps on ProMotion devices
- [ ] Active tab pill slides with spring physics (not linear)
- [ ] Tab bar respects safe area on all devices (notch/dynamic island compatible)
- [ ] State preserved when switching tabs (scroll position, entered text)
- [ ] Dark theme verified (OLED black background)

### Phase 9 — Remote Config Manager
- Defaults, fetch strategy, typed config wrapper.

### Phase 10 — Feature Gating + Free Limits
- Limits by RC, paywall trigger points (non-invasive).

### Phase 11 — Media Import MVP
- Import photos/videos → encrypted storage + DB records.

### Phase 12 — Thumbnail Pipeline
- Generate encrypted thumbnails; caching strategy.

### Phase 13 — Secure Media Viewer
- Image viewer + video viewer decrypt-to-memory.

### Phase 14 — Files Import MVP
- File picker → encrypted storage + DB.

### Phase 15 — Files Viewer/Export
- Open supported types; otherwise export-to-open with cleanup.

### Phase 16 — Export/Share Hardening
- Temp file lifecycle, confirmations, deletion guarantees best-effort.

### Phase 17 — Intruder Detection Core
- Attempt counter, log entity, UI to view logs.

### Phase 18 — Intruder Camera Capture
- Front camera silent capture (where legal), encrypt + store.

### Phase 19 — Intruder Location Capture
- Timeout-based location logging + permission UX.

### Phase 20 — Emergency Close (Panic)
- Shake gesture + instant return to calculator; RC sensitivity.

### Phase 21 — Biometrics Unlock
- `local_auth` integration + A/B prompt variants.

### Phase 22 — Subscriptions + Entitlements
- `in_app_purchase`, tier model, restore purchases.

### Phase 23 — Ads + Frequency Capping
- Ad units, premium removal, RC caps. Properly integrate banner, inerstitial, rewarded ads strategically without ux friction. Use admob test ids now.

### Phase 24 — Secure Notes
- CRUD + encryption + minimal search mode.

### Phase 25 — Password Vault
- Entries + generator + clipboard timeout; autofill feasibility report.

### Phase 26 — Private Contacts
- Encrypted contacts + optional external intents (RC default off).

### Phase 27 — UX/QA/Launch Readiness
- Animation/haptics pass, accessibility audit, performance profiling, security review checklist.

## 11) Success Metrics
- Day-7 retention
- Conversion rate
- Import completion rate
- Intruder feature activation rate
- Crash-free sessions

## 12) Build/Dev Constraint (Preserved)
- No local builds.
- Codemagic builds only.
- Debug APK only for next 6 months.



I REPEAT AGAIN THAT THE APP'S WHOLE DESIGN, UI, UX MUST BE LOOK LIKE IT IS MADE BY SOME GIANTS COMPANY LIKE APPLE OR MICROSOFT. MY CORE BUSINESS IS DEPENDING ON USERS'S IMPRESSIONS AND IT IS TOTALLY ON DESIGN AND UI/UX.