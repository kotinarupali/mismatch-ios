# Mismatch — Feature Specification

> **Version:** 1.0  
> **Status:** Pre-development — scope authority  
> **Platform:** iOS host app (SwiftUI) + mobile web role cards  
> **Sources:** [APP_PLAN.md](APP_PLAN.md) (vision, API, data models), [MVP_ROADMAP.md](MVP_ROADMAP.md) (build order)

This document finalizes product scope before development begins. When [APP_PLAN.md](APP_PLAN.md) and [MVP_ROADMAP.md](MVP_ROADMAP.md) disagree on V1, **this document wins**.

---

## Core Hypothesis (V1)

> Groups of 6–12 players will prefer **QR links to private web role cards** (no player app install) over passing one phone — and will finish a full round with the host running elimination from the iOS app.

---

## Terminology Mapping

Mismatch uses original role names. This spec maps competitor terminology used in planning discussions:

| Competitor / Generic Term | Mismatch Term | Meaning |
|---------------------------|---------------|---------|
| Mr. White | **Ghost** | Wildcard role — no secret word (optional category hint) |
| Impostor / Undercover | **Mismatch** | Minority role — similar but incorrect word |
| Crew / Civilians | **Insider** | Majority role — shares the true secret word |
| Impostor + Mr. White alliance | **Ghost + Mismatch alliance mode** | Shared faction win condition (V2) |

All role names, word packs, screens, and rules are original to Mismatch.

---

## Complexity Scale

| Rating | Estimate | Meaning |
|--------|----------|---------|
| **Low** | 1–2 days | Single screen or isolated logic |
| **Medium** | 3–5 days | Multi-screen flow or moderate domain logic |
| **High** | 6+ days | Backend, cross-platform, or schema/persistence work |

Estimates assume solo iOS developer familiar with SwiftUI.

---

## Evaluated Features

### 1. QR Role Cards

**Classification:** V1 (Must Have)

**Description**

Each player slot receives a unique HTTPS URL (e.g. `https://play.mismatch.app/c/{token}`) encoded in a QR code on the host QR Grid. Players scan with their phone camera — no Mismatch app required. Scanning opens a responsive mobile web role card page. The host grid displays player name + QR/link only; it never previews roles or words. The host-player slot uses in-app **My Card** instead of self-scanning.

**User Value**

This is the core differentiator. It eliminates phone-passing friction, removes the "download the app first" barrier for guests, and lets each player privately reopen their word via bookmarked URL — solving the "what was my word again?" problem without burdening the host.

**Development Complexity:** High (~8–12 days)

- Card API backend (create session, create cards, GET card, expire session)
- Hosted web role card page (pick → flip → hold-to-reveal)
- Host app integration (API client, URL storage per slot)
- QR generation via CoreImage (URL string only)
- Token isolation and error states

**Dependencies**

- Card API deployed and reachable over HTTPS
- Web page hosted at production domain (e.g. `play.mismatch.app`)
- Network connectivity at setup time (mitigated by pass-the-phone fallback)
- Role assigner must run before card token creation

**Acceptance Criteria**

- [ ] Host distributes roles → QR Grid shows one scannable QR per non-host player slot
- [ ] Scanning QR on iOS Safari and Android Chrome opens correct player's web card
- [ ] 10-player QR setup completes in ≤ 3 minutes (playtest measured)
- [ ] `GET /cards/{token}` returns only that token's assignment; foreign tokens return 403/404
- [ ] Reopened/bookmarked URL skips card-pick screen; shows revealed card + hold-to-reveal
- [ ] QR grid cells show name + QR only — no role or word preview
- [ ] Card API unavailable → host sees clear error + one-tap pass-the-phone fallback
- [ ] Expired/invalid token shows friendly error on web page

---

### 2. Pass-the-Phone Mode

**Classification:** V1 (Must Have)

**Description**

Sequential role reveal on the host device. Flow: *"Pass to [Name]"* → card pick grid (4–6 face-down cards) → flip → hold-to-reveal → **Hide & pass** → next player. Uses the same random assignment engine as QR mode. Host is included in pass order when **I'm playing** is on (recommended: host picks last). Fully offline — no Card API required.

**User Value**

Inclusive fallback for players without phones, dead batteries, camera issues, or spotty Wi-Fi. Also enables Phase 1 development and playtesting before backend is ready. Ensures no player is excluded from the game.

**Development Complexity:** Medium (~3–5 days)

- Sequential pass-order UI
- Shared `CardPickView` component (parity with web)
- Hide & pass guard before advancing
- Integration with role assigner (same shuffle as QR mode)

**Dependencies**

- Role assigner with crypto-fair shuffle
- Card pick reveal UX (shared with web and host My Card)
- Player slot list with display names and avatar colors

**Acceptance Criteria**

- [ ] Full round (distribute → discuss → vote → reveal) completable with zero network
- [ ] Each player sees only their own card during their turn
- [ ] **Hide & pass** is required before advancing to next player
- [ ] Host included in pass order when **I'm playing** is on
- [ ] Same visual interaction as web card (pick → flip → hold-to-reveal)
- [ ] Distribution mode selectable in Lobby (QR vs pass-the-phone)

---

### 3. Player Profiles

**Classification:** V1.5 (Should Have)

**Description**

Local named player profiles persisted via SwiftData on the host device. In the Lobby, the host links each player slot to an existing profile or creates a new one. Profiles accumulate stats across sessions. Stats belong to named players, not the device owner — addressing the "host accumulates everyone's data" pain point from physical card games.

**User Value**

Meaningful for recurring friend groups who play regularly. Gives players a reason to return and compare performance across game nights without requiring accounts or cloud sync.

**Development Complexity:** High (~5–7 days)

- SwiftData schema (`PlayerProfile`, `PlayerStats`)
- Profiles List + Profile Detail screens
- Lobby profile picker/linking UI
- Stat write path at session end
- Migration strategy for schema changes

**Dependencies**

- V1 complete and playtest gate passed
- Session scoring (V1.5) to populate meaningful stats
- SwiftData (iOS 17+)

**Acceptance Criteria**

- [ ] Host can create, select, and link profiles to player slots in Lobby
- [ ] Profile stats update correctly after Session Summary
- [ ] Profiles persist across app restarts
- [ ] Unlinked slots still participate in session; no profile write for those slots
- [ ] UX copy clearly states: *"Stats saved on this device"*
- [ ] Profile CRUD does not block or slow active game session

**V1 substitute:** Anonymous player names only; no persistence beyond current session.

---

### 4. Player-Centric Scoring

**Classification:** V1.5 (Should Have)

**Description**

Per-round points with role-specific bonuses, accumulated across a multi-round session and written to linked local profiles. Proposed rules (simplified to max 4 types for V1.5 launch):

| Event | Points | Who |
|-------|--------|-----|
| Survived the round | +1 | All non-eliminated players |
| Mismatch survived | +3 | Mismatch player |
| Ghost survived | +2 | Ghost player |
| Ghost correct word guess | +5 | Ghost player |

*Deferred from V1.5 initial cut if scope pressure:* correct-vote bonus (+2 Insiders), misdirection bonus (+1 Mismatch with ≤1 vote received). Add only if per-voter tracking ships.

**User Value**

Drives replay beyond binary win/lose. Rewards skill and role-specific play. Connects individual performance to named profiles for recurring groups.

**Development Complexity:** Medium–High (~4–6 days)

- Scoring engine (mode-aware, unit-tested)
- Round Summary screen with points breakdown
- Session point accumulation across rounds
- Profile stat writes at session end

**Dependencies**

- Multi-round sessions (V1.5)
- Session Summary screen (V1.5)
- Local named profiles (V1.5) for persistent writes
- Per-voter tracking (optional — required only for correct-vote bonus)

**Acceptance Criteria**

- [ ] Points calculated correctly for all defined score events (unit tests)
- [ ] Round Summary shows points earned per player for that round
- [ ] Session totals accumulate correctly over 3+ rounds
- [ ] Linked profiles receive stat updates at Session Summary
- [ ] Unlinked slots show session totals but no profile write

**V1 substitute:** Reveal screen shows round winner text only (e.g. *"Insider side wins"*) — no points, no Round Summary screen.

---

### 5. Mr. White Modes (Ghost)

**Classification:** Split — V1 (core) + V1.5 (enhancements)

Mismatch uses **Ghost** instead of Mr. White. This feature spans multiple sub-capabilities:

| Sub-feature | Classification |
|-------------|----------------|
| Ghost role toggle (default **off**) | V1 |
| Auto Ghost count by player count when toggle on | V1 |
| Classic Ghost (no word on card) | V1 |
| Category Hint mode (Ghost receives category clue) | V1.5 |
| Ghost word-guess win bonus on reveal | V1.5 |

**Description**

**V1:** Host enables **Ghost** in Lobby. When on, the rules engine assigns Ghost slots per the player-count distribution table (never manually chosen). Classic Ghost receives no word — player must bluff from discussion context. When off (default), all special slots are Insider + Mismatch only — simpler first sessions.

**V1.5:** **Category Hint** sub-mode gives Ghost a category label derived from word pair metadata (e.g. *"Category: Places"*). **Word-guess win** allows Ghost to claim the common word on the Reveal screen for bonus points / alternate win.

**User Value**

Ghost adds strategic depth and genre appeal. Category Hint fixes the "Ghost feels random" feedback. Word-guess gives Ghost a concrete win path beyond survival.

**Development Complexity**

- V1 Classic Ghost: **Medium** (included in role assigner + web/host card UI) (~0 incremental days beyond core)
- V1.5 Category Hint: **Low** (~1 day)
- V1.5 Word-guess UI on Reveal: **Low–Medium** (~2 days)

**Dependencies**

- Role assigner with player-count distribution table
- Web role card Ghost UI (no-word copy, hint display)
- Reveal screen (V1.5 word-guess prompt)
- Word pair `category` metadata in bundled JSON

**Acceptance Criteria (V1)**

- [ ] Ghost toggle default **off** in Lobby
- [ ] Ghost off → 0 Ghosts at all player counts (4–16)
- [ ] Ghost on → distribution matches table (e.g. 8 players → 1 Ghost, 1 Mismatch, rest Insiders)
- [ ] Web card and pass-the-phone show appropriate no-word copy for Ghost
- [ ] Ghost count never manually editable by host

**Acceptance Criteria (V1.5)**

- [ ] Category Hint displays category label on Ghost card after flip
- [ ] Host can enter Ghost's word guess on Reveal screen
- [ ] Correct guess triggers Ghost win / bonus per scoring rules
- [ ] Incorrect guess has no penalty beyond normal elimination outcome

---

### 6. Impostor + Mr. White Alliance Mode (Ghost + Mismatch Alliance)

**Classification:** V2 (Future)

**Description**

A variant game mode where Ghost and Mismatch share a faction win condition — e.g. both win if Mismatch survives AND Ghost correctly guesses the common word, or if neither is eliminated. Requires new win conditions, scoring rules, and tutorial copy. Distinct from Classic mode's independent role goals.

**User Value**

High strategy for experienced groups who have mastered Classic mode. Differentiates Mismatch for repeat players seeking depth.

**Development Complexity:** High (~1–2 weeks)

- New `GameMode` implementation with alliance win logic
- Mode selector in Create Game / Lobby
- Extended How to Play content
- Playtesting at 10–12+ players (rules explanation burden)

**Dependencies**

- `GameMode` protocol + registry (V2)
- Classic mode proven and stable
- Documented playtest demand from V1.5 users
- Design doc + playtest script (required before build starts)

**Acceptance Criteria**

- [ ] Deferred — acceptance criteria written in design doc after V1.5 PMF validation
- [ ] Mode explainable in ≤ 60 seconds by host without confusion
- [ ] Win conditions unambiguous on Reveal screen

---

### 7. Game History

**Classification:** V2 (Future)

**Description**

Persist completed sessions locally (last 20) with round-by-round outcomes, eliminations, and participants. Viewable from a Session History screen. Complements profile stats with full session replay context.

**User Value**

Low-frequency but high delight for recurring groups — settling disputes, reminiscing, tracking group dynamics. Not required to validate the core QR hypothesis.

**Development Complexity:** Medium (~3–4 days)

- SwiftData session history model
- Session History list + detail screens
- Write path at session end

**Dependencies**

- SwiftData persistence (V1.5 profiles establish schema patterns)
- Multi-round sessions with structured round data (V1.5)
- Session completion flow

**Acceptance Criteria**

- [ ] Last 20 completed sessions listed chronologically
- [ ] Tap session → see round-by-round eliminations and outcomes
- [ ] History survives app restart
- [ ] Does not block V1.5 launch if deferred within V2

---

### 8. Custom Word Packs

**Classification:** V2 (Future)

**Description**

Two potential paths (not both required for first V2 release):

1. **IAP themed packs** — Office, Travel, Food, etc. (StoreKit)
2. **Local custom pairs** — Host creates/edits word pairs on device (Host Pro candidate)

Both require a word pack loader abstraction and content QA pipeline.

**User Value**

Replayability beyond the bundled general pack. Natural monetization path after product-market fit. Lets hosts tailor content to their group context.

**Development Complexity:** High

- Local editor: ~1 week (CRUD UI, validation, import/export)
- IAP pipeline: +1–2 weeks (StoreKit, pack delivery, App Store review)
- Content authoring and playtesting rubric for quality

**Dependencies**

- Word pack loader abstraction (bundled JSON in V1)
- Product-market fit validation
- Content pipeline for IAP packs
- Optional StoreKit integration

**Acceptance Criteria**

- [ ] V2 first release ships IAP packs **or** local editor — product decision at V2 planning
- [ ] Custom/IAP pairs pass ambiguity rubric (no confusing pairs in playtest)
- [ ] Active word pack selectable in Lobby
- [ ] Bundled general pack always available (free)

---

### 9. Statistics

**Classification:** V1.5 (basic) / V2 (advanced)

**Description**

**V1.5 — Basic stats** on Profile Detail:

- Games played
- Wins as Insider / Mismatch / Ghost
- Total points
- Win rate (computed)

**V2 — Advanced stats:**

- Current win streak / best streak
- MVP score (aggregate performance metric)
- Session history analytics
- Export stats (CSV/PDF) — Host Pro candidate

**User Value**

V1.5 stats give recurring groups lightweight progression. V2 analytics serve power users and potential monetization (Host Pro export).

**Development Complexity**

- V1.5 basic: **Medium** (~3–4 days, bundled with profiles)
- V2 advanced: **Medium–High** (+1 week)

**Dependencies**

- V1.5: Player profiles, session scoring, Session Summary
- V2: Game history, extended scoring events, export infrastructure

**Acceptance Criteria (V1.5)**

- [ ] Profile Detail shows games played, wins by role, total points, win rate
- [ ] Stats increment correctly after each session (unit tested)
- [ ] Win rate handles edge cases (0 games → 0% or N/A)

**Acceptance Criteria (V2)**

- [ ] Streak increments on win, resets on loss
- [ ] Export produces readable CSV or PDF of session/profile stats

**V1 substitute:** No statistics — anonymous names only, no persistence.

---

### 10. Voting System

**Classification:** V1 (MVP) + V1.5 (enhanced)

**Description**

**V1 — Host consensus vote:** After discussion, host opens Voting screen showing avatar grid of non-eliminated players. Host taps the eliminated player → confirmation dialog → submit. Single elimination per round. Host records the group's verbal consensus — not a secret ballot. Large touch targets (≥ 44pt) for 16-player scale.

**V1.5 enhancements:**

- Tie vote detection → revote prompt (exclude tied players from revote, or host breaks tie — configurable)
- Per-voter tracking (optional) — records which player each voter chose, enabling correct-vote scoring bonus

**User Value**

V1: Structured elimination at scale; replaces chaotic verbal "who are we voting for?" moments. V1.5: Fairness on ties; scoring accuracy for Insider correct-vote bonus.

**Development Complexity**

- V1 MVP: **Medium** (~3 days)
- V1.5 tie logic: **Medium** (+2 days)
- V1.5 per-voter tracking: **Medium** (+2–3 days)

**Dependencies**

- Player slots with display names, avatar colors, elimination state
- Discussion phase completion trigger
- Reveal screen (receives eliminated player ID)

**Acceptance Criteria (V1)**

- [ ] Avatar grid renders correctly for 4–16 active players
- [ ] Eliminated players visually distinct / not selectable (or clearly marked if re-vote scenario)
- [ ] Confirmation dialog prevents accidental elimination
- [ ] Host can select themselves (**You** slot labeled)
- [ ] All touch targets ≥ 44×44 pt
- [ ] Vote result flows to Reveal screen with correct player

**Acceptance Criteria (V1.5)**

- [ ] Tie detected when multiple players receive equal votes
- [ ] Revote flow excludes tied players or prompts host tiebreak
- [ ] Per-voter records stored when feature enabled (for scoring)

---

### 11. Discussion Timer

**Classification:** V1 (fixed) + V1.5 (configurable)

**Description**

**V1:** Fixed 3-minute countdown during Discussion phase. Visible timer on host screen. **End Early** button lets host skip to voting. No haptics in V1.

**V1.5:** Configurable duration (1–5 minutes) via Lobby inline setting. Haptic pulse warnings at 30 seconds and 10 seconds remaining. Default timer value configurable in Settings screen.

**User Value**

Keeps party energy high; prevents discussion drift. Configurability lets hosts tune pace to group personality (quick rounds vs. deep debate).

**Development Complexity**

- V1 fixed timer: **Low** (~1 day)
- V1.5 configurable + haptics: **Low** (+1 day)

**Dependencies**

- Discussion screen (V1)
- Lobby inline settings (V1.5 for configurability)
- Settings screen (V1.5 for default)

**Acceptance Criteria (V1)**

- [ ] Timer starts at 3:00 when Discussion phase begins
- [ ] Timer counts down accurately (verified over full 3 minutes)
- [ ] **End Early** transitions to Voting immediately
- [ ] Timer visible throughout Discussion phase

**Acceptance Criteria (V1.5)**

- [ ] Host can set timer 1–5 min in Lobby before round start
- [ ] Haptic feedback fires at 30s and 10s remaining
- [ ] Settings screen persists default timer preference

---

### 12. Session Leaderboards

**Classification:** V1.5 (Should Have)

**Description**

At Session Summary (end of multi-round session), display a ranked leaderboard of all players by total accumulated points. Shows rank, name, avatar, and point total. Handles ties gracefully (shared rank or alphabetical — product decision at implementation).

**User Value**

Answers the top post-session question: *"Who won tonight?"* Critical retention hook for party games — groups need a clear winner to generate replay demand and word-of-mouth.

**Development Complexity:** Medium (~2–3 days, including Session Summary screen)

**Dependencies**

- Multi-round sessions (V1.5)
- Player-centric scoring engine (V1.5)
- Session Summary screen (V1.5)

**Acceptance Criteria**

- [ ] Leaderboard ranks players by total session points descending
- [ ] Correct after 3+ rounds with mixed outcomes
- [ ] Ties handled consistently (document chosen behavior)
- [ ] Displayed on Session Summary screen
- [ ] Unlinked anonymous slots appear by display name

**V1 substitute:** Reveal screen shows single-round winner text only. **Play Again** / **New Game** — no cumulative ranking.

---

## Supporting V1 Features

These features are required for a shippable V1 but were not in the explicit evaluation list.

### Host-as-Player ("I'm playing")

**Classification:** V1

Host occupies a **You** player slot (default **on**). In QR mode, host uses in-app **My Card** (not self-scanning). In pass-the-phone, host is in pass order. Host can be eliminated and continues moderating. **Complexity:** Medium (~2 days, shared CardPickView).

### Card Pick Reveal UX

**Classification:** V1

Grid of 4–6 face-down cards → tap → flip animation → optional role badge (if **Show role on card** on) → hold-to-reveal for word. Shared interaction on web, pass-the-phone, and host My Card. **Complexity:** Medium (~3–4 days).

### Show Role on Card Toggle

**Classification:** V1 (default **off**)

When off, cards show word/hint only — players infer team from discussion. When on, flip shows Insider/Mismatch/Ghost badge. API omits `role` from JSON when off. **Complexity:** Low (~1 day).

### Secret Isolation

**Classification:** V1

One token = one card. Host UI never previews other players' words before elimination reveal. Pass-the-phone requires Hide & pass. See [APP_PLAN.md § Secret isolation](APP_PLAN.md) for full surface matrix. **Complexity:** Medium (architectural discipline, ~0 incremental if enforced from day one).

### Classic Mode Role Assignment

**Classification:** V1

Hardcoded distribution table by player count. Cryptographically fair shuffle mapped to slots. Ghost count from table when enabled. No manual role selection. **Complexity:** Medium (~2–3 days + unit tests).

### Bundled Word Pack (30 pairs)

**Classification:** V1 (expand to 60+ in V1.5)

Original word pairs in bundled `general.json`. One active pack for V1. **Complexity:** Low (~2 days content + loader).

### Inline Rules (First Launch)

**Classification:** V1

Three bullet rules on first app launch — not full tutorial. **Complexity:** Low (~0.5 day).

### API Outage Fallback

**Classification:** V1

When Card API unreachable, host sees error + one-tap switch to pass-the-phone. **Complexity:** Low (~0.5 day).

### App Icon + TestFlight Readiness

**Classification:** V1

App icon, launch screen, privacy compliance for TestFlight beta. **Complexity:** Low (~1 day).

### Explicitly Cut (All Tiers)

- Standalone player iOS app (Join Game, QR Scanner in app)
- Deep links (`mismatch://`)
- Encrypted payloads in QR (QR = plain HTTPS URL)
- Separate Create Game / Game Settings / Settings screens (merged into Lobby for V1)
- `GameMode` protocol / registry (V2)
- Automated SMS (Twilio) — share sheet in V1.5 instead

---

# V1 Scope

**Goal:** Smallest version that validates the core QR web card hypothesis.

**Timeline:** ~3–4 weeks focused solo development

**One sentence:** Host runs the iOS app (and can play) → guests scan QR links to web role cards (no install) → host runs elimination in app → nobody asks anyone to re-reveal a word.

## Host iOS App (8 screens)

| Screen | Purpose |
|--------|---------|
| Home | Host Game entry; inline rules on first launch |
| Lobby | Players, **I'm playing**, **Ghost** (off default), **Show role on card** (off default), 3-min timer, distribution mode, Distribute Roles, Start Round |
| QR Grid | Name + QR per player; **You** row → View My Card; tap to enlarge; copy link |
| My Card | Host-player: card pick → flip → hold-to-reveal; accessible from Discussion/Voting |
| Pass-the-Phone Reveal | Sequential card pick UX; Hide & pass |
| Discussion | 3-min countdown; End Early; My Card if playing |
| Voting | Avatar grid; select eliminated player + confirm |
| Reveal + End | Role + word reveal; round winner text; Play Again / New Game |

## Web (1 page)

- Mobile-responsive role card: pick → flip → hold-to-reveal
- Bookmarkable URL; reopen skips pick
- Expired/invalid token error states

## Card API

- `POST /sessions` — create session
- `POST /sessions/{id}/cards` — create card tokens per player
- `GET /cards/{token}` — serve assignment (role omitted when `showRoleOnCard` false)
- Session expiry / invalidation on end

See [APP_PLAN.md § Card URL & QR Design](APP_PLAN.md) for full API contract.

## Game Rules (V1)

- **Classic mode only** — hardcoded, no `GameMode` protocol
- Roles: Insider + Mismatch; Ghost toggle (default off, auto-count when on)
- 30 original word pairs in bundled JSON
- Random shuffle at Distribute Roles — no manual assignment
- Round winner text on Reveal — no scoring engine
- Single round per session (Play Again starts fresh)

## V1 Explicit Exclusions

- SwiftData / player profiles / statistics
- Scoring engine / session leaderboard / Session Summary
- Multi-round accumulated sessions
- Ghost Category Hint / word-guess win
- PIN lock on web card
- Full How to Play tutorial / Settings screen
- Share via Messages (copy link only in V1)
- Tie vote automation
- Configurable timer (fixed 3 min)
- `GameMode` protocol / registry

## V1 Success Gate (required before V1.5)

| Metric | Target |
|--------|--------|
| Playtest groups that finish a session | ≥ 3 |
| Session completion rate | ≥ 80% |
| Host re-reveal requests per session | ≤ 1 |
| Setup to first round (10 players, QR) | ≤ 3 minutes |
| Unprompted "play again" | ≥ 2 of 3 groups |

---

# V1.5 Scope

**Goal:** Retention and replay — build only after V1 success gate is met.

**Timeline:** ~2–3 weeks after V1 gate

**Gate principle:** Do not start V1.5 until all V1 success criteria are met.

## Features (priority order)

1. **Multi-round sessions** — Continue after Reveal; accumulated session state
2. **Session Summary screen** — Final results destination
3. **Simplified scoring** — Max 4 score rule types (see Feature §4)
4. **Session leaderboard** — Ranked by total session points
5. **Local named profiles (SwiftData)** — Link in Lobby; basic stats on Profile Detail
6. **Ghost Category Hint mode** — If Ghost feedback says "too random"
7. **Ghost word-guess win** — Reveal screen prompt + scoring
8. **Share card link via Messages** — iOS share sheet per player
9. **Configurable timer (1–5 min)** — Lobby inline setting
10. **Haptic timer warnings** — 30s and 10s remaining
11. **Tie vote / revote logic** — If confusion reported in playtests
12. **Scan status indicators** — If large-group setup pain confirmed
13. **Late player QR regeneration** — Add player post-distribute; regen single QR
14. **How to Play** — Full tutorial screen
15. **Settings screen** — Timer default, haptics toggle, PIN default
16. **PIN lock on web card** — If shoulder-surfing reported
17. **Expand word pack to 60+ pairs** — If repetition complaints
18. **16-player UI hardening** — If target segment confirmed
19. **Accessibility pass** — VoiceOver, Dynamic Type, 44pt targets audit
20. **Session snapshot recovery** — If host backgrounding loses games

## V1.5 Conditional Features

Ship only if playtest feedback demands:

| Feature | Trigger |
|---------|---------|
| Ghost enabled by default | Playtesters miss the Ghost role |
| Per-voter vote tracking | Correct-vote scoring bonus desired |
| Automated SMS (Twilio) | Share sheet insufficient |

---

# V2 Scope

**Goal:** Extensibility, monetization, and platform expansion — post product-market fit.

## Game Modes & Rules

- `GameMode` protocol + registry
- Second game mode (TBD — location-based, faction-based, etc.)
- **Ghost + Mismatch alliance mode**
- Custom role relationships editor

## Content & Monetization

- Word pack IAP (themed packs)
- Local custom word pair creation (Host Pro)
- User-generated word packs (moderation pipeline)

## Platform & Sync

- Cloud accounts + cross-device profile sync
- Simultaneous multi-device voting (network layer)
- Multipeer Connectivity evaluation
- Host handoff / co-host
- Localization
- iPad-optimized layout
- Android (separate product decision)

## Analytics & History

- Game history viewer (last 20 sessions)
- Advanced statistics (streaks, MVP score)
- Export stats (CSV/PDF) — Host Pro
- Win streaks beyond local profile

## Explicitly Deferred / Rejected

- Apple Watch companion — no clear value
- Ads — disrupts party flow
- Subscription model — episodic use pattern
- Pay-to-win mechanics

---

# Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Card API unavailable at party time** | High | Pass-the-phone one tap away; cache web card after first load; test on real mobile networks before V1 sign-off |
| **Rules engine over-engineering** | High | Hardcode Classic in V1; extract `GameMode` protocol only when mode #2 is designed |
| **Scope creep (APP_PLAN vs roadmap)** | High | This document is scope authority; V1.5 gated on metrics, not assumptions |
| **QR scan friction** (lighting, permissions) | Medium | Copy link per player in V1; share sheet in V1.5 |
| **Link forwarding / shoulder surfing** | Medium | Hold-to-reveal; Hide & pass; optional PIN in V1.5 |
| **SwiftData migration pain** | Medium | Defer to V1.5; version models early; migration tests in CI |
| **Solo dev timeline slip** | Medium | V1 capped at 18 features; no scoring/profiles until gate passed |
| **Word pack quality / repetition** | Medium | 30 pairs in V1; expand based on playtest feedback; ambiguity rubric |
| **Large-group UI at 16 players** | Medium | Test at 10 for V1; dedicated UI pass in V1.5 |
| **Backend scope creep** | Medium | Card API is card-delivery only — not full game sync |
| **Genre / trademark confusion** | Low | Original terminology; no competitor names in App Store copy |

---

# Simplifications

Deliberate cuts to ship V1 fast and validate the hypothesis:

1. **Hardcoded Classic rules** — no `GameMode` protocol until V2
2. **In-memory session only** — no SwiftData until V1.5
3. **Round winner text replaces scoring** — merge Round Summary into Reveal for V1
4. **Fixed 3-min timer** — no Settings screen in V1
5. **30 word pairs** — not 50–100; quality over volume for first sessions
6. **Ghost off by default** — Insider vs Mismatch only for first-time hosts
7. **Show role on card off by default** — word-only cards; closer to genre feel
8. **Lobby-only configuration** — no separate Create Game / Game Settings screens
9. **Host records consensus vote** — not secret ballot or multi-device voting
10. **QR = plain HTTPS URL** — no encryption, no deep links, no in-app scanner
11. **Card API is card-delivery only** — not full game state sync
12. **Inline rules (3 bullets)** — not full How to Play until V1.5
13. **Single round per session in V1** — Play Again resets; multi-round in V1.5
14. **Copy link in V1** — share sheet deferred to V1.5

---

# Recommended Launch Scope

| Milestone | Audience | Scope | Rationale |
|-----------|----------|-------|-----------|
| **TestFlight (V1)** | 2–3 friend groups | Full V1 scope | Validate QR web card hypothesis with minimal backend risk |
| **App Store (V1.5)** | Public launch | V1 + retention pack | Party games need "who won tonight?", profiles, and polish for word-of-mouth |
| **V2** | Post-PMF users | Modes, IAP, platform | Extensibility and monetization after retention proven |

## Why not App Store on V1 alone?

Party games are episodic. V1 proves distribution works, but groups will ask *"who won overall?"* after the first round. Launching publicly without session scoring, leaderboards, and profiles risks low retention and weak App Store reviews — even if the core mechanic delights.

## Recommended build order

See [MVP_ROADMAP.md § MVP Development Order](MVP_ROADMAP.md) for phased implementation:

1. **Phase 1 (Days 1–7):** Pass-the-phone playable loop — offline, no backend
2. **Phase 2 (Days 8–9):** Playtest gate — is the game fun?
3. **Phase 3 (Days 10–18):** Web cards + QR + Card API
4. **Phase 4 (Days 17–20):** TestFlight prep

Do not start Phase 3 until Phase 2 playtest passes.

## Data models reference

V1 in-memory models and Card API models are defined in [APP_PLAN.md § Data Models](APP_PLAN.md). V1.5 adds `PlayerProfile`, `PlayerStats`, `ScoreEvent` via SwiftData.

---

*End of FEATURE_SPEC.md*
