# TURF — Visual Design System & Styleguide
**Version 1.0 · Manik Chugh**

> Walk it. Own it. Hold it.

---

## 0. Design Philosophy

TURF is not a wellness app. It's not a social network. It's a territorial game that lives on city streets — and the design should make you *feel* that before you read a single word.

The visual language draws from three reference worlds:
- **Military HUD overlays** — coordinate readouts, system status indicators, zone-locked UI
- **Street culture / streetwear drops** — terse copy, heavy type, scarcity signals
- **Game economy interfaces** — stat chips, leaderboard rows, progress meters, ticker data

Every design decision should pass this single filter: **does this feel like the city or does it feel like the app store?** If it feels like the app store, strip it back.

---

## 1. Color System

### 1.1 Core Palette

| Token | Hex | Role |
|---|---|---|
| `--color-bg` | `#0A0A0A` | App background — near-black, not pure black |
| `--color-surface` | `#141414` | Cards, panels, map overlays |
| `--color-surface-raised` | `#1E1E1E` | Elevated surfaces, modals, drawers |
| `--color-border` | `#2A2A2A` | Dividers, chip outlines, row separators |
| `--color-text-primary` | `#EBEBEB` | Body text, stat values, primary labels |
| `--color-text-secondary` | `#888888` | Meta labels, timestamps, system readouts |
| `--color-text-muted` | `#444444` | Disabled states, ghost zone labels |

### 1.2 Game State Colors

These three colors carry **semantic meaning**. They are not used decoratively — every instance maps directly to a game state.

| Token | Hex | State | Usage |
|---|---|---|---|
| `--color-held` | `#39FF14` | HELD — you own this turf | Zone fill, claim badge, BP gain indicators |
| `--color-contested` | `#FF6B00` | CONTESTED — someone is challenging | Alert chips, perimeter progress bar accent, push notifications |
| `--color-ghost` | `#4A4A4A` | GHOST — unclaimed or expired | Inactive zones on map, ghost-mode indicator |

> **Rule:** Never use `--color-held` green for anything other than an owned/active state. No decorative green. No "success" green. This color means one thing.

### 1.3 Extended Palette

| Token | Hex | Usage |
|---|---|---|
| `--color-bp` | `#FFD700` | Block Points (BP) — the currency. Gold-coded. |
| `--color-danger` | `#FF3B3B` | Rent overdue, account warning, walk failed |
| `--color-hotspot` | `#A78BFA` | Hotspot active / Hotspot nearby indicator |
| `--color-map-bg` | `#111318` | Base map tile tint — desaturated, dark |

### 1.4 Opacity Variants

Use alpha variants of game-state colors for fills and overlays on the map:

- Zone fill (HELD): `rgba(57, 255, 20, 0.15)` with `2px` solid `--color-held` stroke
- Zone fill (CONTESTED): `rgba(255, 107, 0, 0.15)` with `2px` solid `--color-contested` stroke
- Zone fill (GHOST): `rgba(74, 74, 74, 0.10)` with `1px` dashed `--color-ghost` stroke

---

## 2. Typography

### 2.1 Type Roles

TURF uses three distinct type roles. Never mix them or substitute.

---

#### Display — `Space Grotesk`
Used for hero headlines, section titles, leaderboard names, large numeric stats.

```
Font: Space Grotesk
Weights: 700 (Bold), 500 (Medium)
Transform: UPPERCASE always for display use
Letter-spacing: 0.04em to 0.08em
```

Why Space Grotesk: Its ink-trap details and slightly technical character give it a HUD-adjacent quality without being novelty. Wide set at uppercase with tracked spacing reads like stencil-cut steel.

---

#### System / Data — `JetBrains Mono`
Used for all coordinate readouts, system status labels, stat chips, zone IDs, timestamps, and any string formatted in `SCREAMING_SNAKE_CASE`.

```
Font: JetBrains Mono
Weights: 400 (Regular), 600 (SemiBold)
Transform: UPPERCASE
Letter-spacing: 0.06em
Color: --color-text-secondary (#888888) for ambient reads
       --color-held (#39FF14) for live/active system states
```

This is the voice of the game engine talking to the player. Every label formatted like `SYS_STATUS: ONLINE` or `LAT: 12.9716° N` uses this face. No exceptions.

---

#### Body / UI — `Inter`
Used for descriptions, onboarding copy, instruction text, settings labels. The workhorse that stays invisible.

```
Font: Inter
Weights: 400 (Regular), 500 (Medium)
Transform: Sentence case
Letter-spacing: 0
```

---

### 2.2 Type Scale

| Step | Size | Weight | Face | Usage |
|---|---|---|---|---|
| `--text-hero` | 56–72px | 700 | Space Grotesk | Full-screen claim banners, hero stat |
| `--text-h1` | 36px | 700 | Space Grotesk | Screen titles |
| `--text-h2` | 24px | 700 | Space Grotesk | Section headers |
| `--text-h3` | 18px | 500 | Space Grotesk | Card headers, leaderboard names |
| `--text-stat` | 48px | 700 | Space Grotesk | Large standalone numbers (BP, Rep Score, Turfs) |
| `--text-sys-lg` | 13px | 600 | JetBrains Mono | Primary system labels (`SYS_STATUS`, `ZONE_ID`) |
| `--text-sys-sm` | 11px | 400 | JetBrains Mono | Ambient readouts (coordinates, timestamps) |
| `--text-body` | 15px | 400 | Inter | Descriptions, help copy |
| `--text-caption` | 12px | 400 | Inter | Subtext, fine print |

### 2.3 Naming Convention — System Labels

All system labels and UI strings use `SCREAMING_SNAKE_CASE` in JetBrains Mono. This is not decoration — it's a design choice that makes the interface feel like a live system, not a consumer product.

**Examples:**
```
SYS_STATUS: ONLINE
ZONE_ID: BLK_0047
CLAIM_WALK: IN_PROGRESS
PERIMETER: 73%
REP_SCORE: 847
HUSTLE_STREAK: 11 DAYS
RENT_DUE: 2 DAYS
HOTSPOT: ACTIVE
LAT: 12.9716° N · LNG: 77.5946° E
LAST_CLAIM: 14H AGO
```

---

## 3. Iconography & Symbols

### 3.1 Icon Style
- **Style:** Line icons, 1.5px stroke, square caps — no rounded softness
- **Grid:** 24×24px, 20px visible area with 2px padding
- **Color:** Inherits text color by default. Game-state icons use their semantic color.

### 3.2 Signature Symbols

These symbols appear throughout the UI as shorthand:

| Symbol | Meaning |
|---|---|
| `✦` | Claim confirmed / turf owned |
| `⬡` | Hexagonal zone marker (map layer) |
| `//` | Section divider in UI and copy (code-comment style) |
| `→` | Directional CTA, progress |
| `·` | Separator in inline metadata strings |
| `▲` | Leaderboard rank up |
| `▼` | Rank drop, contested |

---

## 4. Spacing & Layout

### 4.1 Base Unit
All spacing derives from an **8px base unit**.

```
--space-1:  4px
--space-2:  8px
--space-3:  12px
--space-4:  16px
--space-5:  24px
--space-6:  32px
--space-7:  48px
--space-8:  64px
--space-9:  96px
--space-10: 128px
```

### 4.2 Layout Grid (Mobile-first)

- **Mobile:** Single column, 16px horizontal gutters
- **Content max-width:** 390px (designed for iPhone 14-class screens)
- **Section padding:** 32px vertical minimum
- **Card padding:** 16px internal, 12px between cards
- **Bottom nav clearance:** 80px (safe area + nav bar)

### 4.3 Layout Patterns

**Map View** — Full bleed. The map is the interface. UI elements float over it as HUD overlays. No white cards. No rounded bottom sheets that look like a normal app.

**List/Leaderboard View** — Full-width rows, 1px `--color-border` separators, no card elevation. Rows read like database entries.

**Stat Dashboard** — Large number dominant, small label above or below in monospace. Stats are never buried.

---

## 5. Component Library

### 5.1 Buttons

**Primary CTA**
```
Background: --color-held (#39FF14)
Text: #000000 (black — maximum contrast on green)
Font: Space Grotesk, 700, UPPERCASE, 0.06em tracking
Padding: 14px 24px
Border-radius: 0px (no radius — this is not soft)
Height: 52px
```

**Secondary / Ghost Button**
```
Background: transparent
Border: 1px solid --color-border (#2A2A2A)
Text: --color-text-primary
Font: Space Grotesk, 500, UPPERCASE
Padding: 12px 20px
Border-radius: 0px
```

**Danger / Alert Button**
```
Background: transparent
Border: 1px solid --color-danger (#FF3B3B)
Text: --color-danger
```

> **Rule:** Zero border-radius on all buttons. A rounded button says "friendly." TURF is not friendly.

---

### 5.2 Stat Chip

A compact badge showing a single game value.

```
┌─────────────────────┐
│ ZONE_ID · BLK_0047  │
│ REP 847 ↑  12 TURFS │
└─────────────────────┘
```

```
Background: --color-surface (#141414)
Border: 1px solid --color-border
Label: JetBrains Mono, 11px, #888888
Value: Space Grotesk, 700, #EBEBEB
State dot: 6px circle in game-state color
Padding: 10px 12px
Border-radius: 2px (barely there — just to prevent jagged corners)
```

---

### 5.3 Zone Card

Shown in the "My Turf" list view and leaderboard.

```
┌──────────────────────────────────────┐
│ ✦ HELD                  BLK_0047     │
│                                      │
│ KORAMANGALA 4TH BLOCK                │
│ Bengaluru                            │
│                                      │
│ BP +320  ·  RENT DUE: 2 DAYS        │
│ LAST_CLAIM: 6H AGO                   │
└──────────────────────────────────────┘
```

- Left accent bar: 3px solid `--color-held` / `--color-contested` / `--color-ghost`
- Background: `--color-surface`
- Title: Space Grotesk 700, 18px
- Meta row: JetBrains Mono 11px, `--color-text-secondary`
- No box shadow — elevation is communicated by color, not shadow

---

### 5.4 Leaderboard Row

```
┌─────────────────────────────────────────┐
│ 01   @GHOST_WALKER   LANDLORD   REP 1,204│
│ 02   @NEON_BRUISER   HUSTLER    REP  891 │
│ 03   @MANIK          SCOUT      REP  847 │
└─────────────────────────────────────────┘
```

- Row height: 56px
- Rank: JetBrains Mono, 600, `--color-text-muted`, zero-padded (`01`, `02`)
- Username: Space Grotesk, 500, `--color-text-primary`
- Role tag: JetBrains Mono, 11px, `--color-text-secondary`, `[ ]` brackets
- REP value: Space Grotesk, 700, `--color-text-primary`
- Current user row highlighted: `--color-surface-raised` bg + `--color-held` left accent

---

### 5.5 Perimeter Progress Bar

Shows walk completion during an active Claim Walk.

```
PERIMETER ─────────────────────── 73%
           ████████████░░░░░░░░░
           0%                  100%
```

- Track: 4px height, `--color-border` fill
- Fill: `--color-held` (green) for normal progress, `--color-contested` (orange) if challenged mid-walk
- Label: JetBrains Mono, 11px, above left
- Percentage: JetBrains Mono, 600, above right
- No border-radius on the fill bar

---

### 5.6 System Status Bar (Ambient HUD)

A persistent ambient element shown on map screens. Reads like a terminal.

```
SYS_STATUS: ONLINE · LAT: 12.9716° N · LNG: 77.5946° E · LIVE_PLAYERS: 312
```

- Font: JetBrains Mono, 10px, `--color-text-muted`
- Color shifts to `--color-held` when a claim walk is active
- Scrolls horizontally on mobile like a ticker
- Positioned at top of map view, below status bar

---

### 5.7 Hotspot Indicator

```
◉ HOTSPOT: ACTIVE
  SIGNAL STRENGTH: ████░░ HIGH
  BONUS: +2X BP
```

- Pulsing purple dot: `--color-hotspot` (#A78BFA), 8px, 2s pulse animation
- Background: `rgba(167, 139, 250, 0.08)` tint
- Border: 1px solid `rgba(167, 139, 250, 0.3)`

---

## 6. Map Layer Design

The map is TURF's core surface. It should feel like mission control, not Google Maps.

### 6.1 Base Map Style
- **Tile style:** Dark, desaturated. Use Mapbox `dark-v11` or equivalent.
- Further suppress: green park fills → near-black, blue water → `#0D1117`, road labels → muted
- Remove: POI markers, transit lines, building labels
- Keep: Street grid lines (subtle `#1E1E1E`), major street labels in `JetBrains Mono` if possible

### 6.2 Zone Overlays

Three visual states, always consistent:

| State | Fill | Stroke | Stroke style |
|---|---|---|---|
| HELD | `rgba(57, 255, 20, 0.15)` | `#39FF14` 2px | Solid |
| CONTESTED | `rgba(255, 107, 0, 0.15)` | `#FF6B00` 2px | Solid |
| GHOST | `rgba(74, 74, 74, 0.08)` | `#4A4A4A` 1px | Dashed |

### 6.3 Map HUD Elements

All UI elements overlaid on the map float as **borderless panels** — no card shadows, no white backgrounds.

- Coordinate readout: bottom-left, JetBrains Mono 10px
- Claim button: bottom-center, full-width primary CTA
- Zone owner tag: appears on tap of zone, anchored to zone centroid
- Compass/zoom: top-right, minimal — single-line, no chrome

---

## 7. Motion & Animation

### 7.1 Principles

Motion in TURF should feel like data — purposeful, fast, never decorative.

- **Duration:** UI transitions 150–200ms. Feedback animations 300–400ms. Never over 500ms.
- **Easing:** `cubic-bezier(0.4, 0, 0.2, 1)` — sharp in, smooth out.
- **Rule:** If removing an animation wouldn't make the UI confusing, remove it.

### 7.2 Signature Moments

**Claim Confirmed**
When a walk is completed and turf is claimed: the zone fill sweeps from `--color-ghost` → `--color-held` over 600ms with a `✦ TURF CLAIMED` stamp that scales in from 0.8 → 1.0.

**Active Walk Pulse**
While a perimeter walk is in progress: a slow 3s pulse on the zone stroke, oscillating between `--color-held` full opacity and 40% opacity. Signals the walk is live.

**Contested Alert**
When a zone is being challenged: zone fill flickers to `--color-contested`, and a push notification chip slides in from the top with a 200ms ease.

**BP Earned**
`+BP` floats up from the zone, fades out over 800ms. Font: Space Grotesk 700, color `--color-bp`.

### 7.3 Reduced Motion

All pulse, float, and sweep animations must respect `prefers-reduced-motion`. Replace with instant state switches.

---

## 8. Voice & Copy

### 8.1 Tone

Terse. Territorial. Present tense. Second person. No corporate warmth, no gamified cheerfulness. The UI talks like the city.

**Do:**
- "WALK IT. OWN IT. HOLD IT."
- "YOUR TURF IS BEING CONTESTED."
- "PAY RENT OR GO GHOST."
- "CLAIM WALK: IN PROGRESS"

**Don't:**
- "Great job! You've claimed a new zone! 🎉"
- "Looks like someone is challenging your turf. Check it out!"
- "Keep walking to complete your claim."

### 8.2 Error States

Errors are blunt. No apology.

```
WALK_FAILED
You left the perimeter.
RESTART CLAIM →
```

```
RENT_OVERDUE
Pay now or this block goes GHOST.
PAY NOW →
```

### 8.3 Empty States

Empty is an invitation, not an apology.

```
NO TURF YET.
Find a block. Walk the perimeter. Make it yours.
START CLAIMING →
```

---

## 9. Visual Direction Summary

| Axis | Direction |
|---|---|
| **Mood** | Dark, territorial, game-coded |
| **Primary metaphor** | Military HUD meets street game |
| **Color** | Near-black base, green/orange/gray semantic states, gold for currency |
| **Type** | Space Grotesk (display) + JetBrains Mono (system) + Inter (body) |
| **Shape language** | Zero radius on interactive elements. Slight radius (2px) on data chips only. |
| **Motion** | Fast, purposeful, data-like. One signature moment per major action. |
| **Copy tone** | Terse, uppercase, directive. No emoji. No friendliness. |
| **What it's not** | Rounded, pastel, congratulatory, consumer-soft, app-store safe |

---

## 10. Anti-Patterns (Never Do)

These break the visual contract.

- ❌ Rounded buttons (border-radius > 4px on any CTA)
- ❌ White or light-mode surfaces
- ❌ Green used for anything other than HELD state
- ❌ Soft drop shadows (box-shadow with blur > 4px)
- ❌ Emoji in UI copy
- ❌ Exclamation marks in system labels
- ❌ Gradient backgrounds (the city doesn't have gradients)
- ❌ Sans-serif system labels in Inter — must be JetBrains Mono
- ❌ Celebratory micro-copy ("You did it!", "Amazing!")
- ❌ Card elevation through shadow — use color and border only

---

*TURF Styleguide v1.0 · Last updated June 2026*
