# Mismatch — Manual Test Plan

> **Purpose:** Solo and small-group testing before a real friends night.  
> **Branch:** `release_1.0` · **Last updated:** June 2026

---

## Quick checklist (print this)

Use fake names **Alex**, **Blake**, **Casey** (+ **You** if host plays). **Pass-the-Phone** mode works on one device.

### Prep
- [ ] Latest build on host iPhone
- [ ] Cloud deployed (`cd cloud && npm run deploy`) — only for QR / guest voting
- [ ] Second device ready — only for Tier 3

### Tier 1 — One phone (~45 min)
- [ ] Home: Settings sheet (gear, top right) · timer on 1 min · persists after relaunch
- [ ] Home: How to Play · Profiles list
- [ ] Profiles: create 3 · edit · stats start at zero
- [ ] Lobby: 3 players · Pass-the-Phone · link 2 profiles · distribute
- [ ] Pass-the-phone: pick → flip → hold → Hide & pass for each player
- [ ] Discussion: 1-min timer · ⋯ Scores · ⋯ Check Player Role
- [ ] Voting: eliminate someone · Results · Continue until Game Over
- [ ] Session Summary: auto after game end · words · leaderboard · profile stats updated
- [ ] Play Again: skips lobby · re-deals same group
- [ ] New Game Night: back to Home
- [ ] ⋯ End Game Night mid-game → Session Summary
- [ ] ⋯ Re-pick Roles → back to Lobby

### Tier 2 — Stretch (~30 min)
- [ ] 5 players + Ghost · outsider banner · ghost guess flow
- [ ] Two players tied on points → shared rank (1, 1, 3)
- [ ] Home timer on · lobby timer off → lobby wins
- [ ] Discussion timer off → no countdown

### Tier 3 — Two devices
- [ ] QR grid · scan web card · host My Card
- [ ] Guest voting tallies on Discussion
- [ ] Tie → Start Revote · tied players excluded as targets

### Friends night (5 min before guests)
- [ ] Real names · seating order · rules summary read aloud
- [ ] Distribute within ~3 min · one test vote · know ⋯ menu

---

## Before you start

1. Build and run the latest `release_1.0` on your host iPhone. Simulator works for UI; real device is better for pass-the-phone.
2. Deploy cloud if testing **QR** or **guest voting**: `cd cloud && npm run deploy`.
3. Keep a second device (phone, iPad, or laptop browser) for Tier 3.

**Solo shortcut:** Use **Pass-the-Phone** in the lobby. Play every “player” yourself — the app does not know who is holding the phone.

---

## Tier 1 — One phone, no friends (~45 min)

### 1. Home & settings

| Step | Do this | Pass if |
|------|---------|---------|
| 1.1 | Open app → tap **Settings** (gear, top right) | Sheet opens; not inline on home |
| 1.2 | Turn **Discussion timer** on → pick **1 minute** → Done | Setting saves |
| 1.3 | Force-quit app → reopen → open Settings again | Timer still on, 1 min |
| 1.4 | Tap **How to Play** | Rules sheet opens |
| 1.5 | Tap **Profiles** | Profiles list opens (empty OK) |

### 2. Profiles (device-local)

| Step | Do this | Pass if |
|------|---------|---------|
| 2.1 | Create profile **Alex** (pick an avatar color) | Appears in list |
| 2.2 | Create **Blake** and **Casey** | 3 profiles total |
| 2.3 | Open Alex → edit name/color → **Save** | Changes persist after back navigation |
| 2.4 | Open a profile → note stats (all zeros) | Total points, games, win rate shown |

### 3. Lobby setup (Pass-the-Phone, 3 players, no ghost)

| Step | Do this | Pass if |
|------|---------|---------|
| 3.1 | **Host a Game** → add Alex, Blake, Casey | 3 players seated |
| 3.2 | Expand **Rules** → turn **I'm playing** off | Ghost toggle disabled (< 5 players) |
| 3.3 | Set **Distribution** → **Pass the phone** | Detail text matches mode |
| 3.4 | Tap person icon on **Alex** → link Alex profile | Profile badge/link shows on seat |
| 3.5 | Link Blake; leave Casey unlinked | Mixed linked/unlinked OK |
| 3.6 | Confirm lobby shows **1 min discussion timer** (from home defaults) | Timer inherited from settings |
| 3.7 | Tap **Distribute Roles** | Goes to pass-the-phone flow (not lobby again) |

### 4. Pass-the-phone distribution

| Step | Do this | Pass if |
|------|---------|---------|
| 4.1 | For each player: pick card → flip → hold to reveal → **Hide & pass** | Cannot skip hide step |
| 4.2 | Mentally note each fake player’s word/role | Words differ; one Mismatch |
| 4.3 | After last player | Lands on **Discussion** |

### 5. One full elimination round

| Step | Do this | Pass if |
|------|---------|---------|
| 5.1 | Discussion screen | 1-minute timer counts down (if enabled) |
| 5.2 | Tap **⋯** → **Scores** | Live score sheet opens |
| 5.3 | Tap **⋯** → **Check Player Role** → pick a player | Role/word revealed to host only |
| 5.4 | Continue to **Voting** → pick a player → **Confirm Vote** | Elimination confirm dialog |
| 5.5 | Confirm elimination | **Results** screen shows who was eliminated + roles |
| 5.6 | If game not over | **Continue** → back to Discussion for round 2 |

Repeat eliminations until **Game Over** (with 3 players, usually 1–2 rounds).

### 6. Natural game end → Session Summary

| Step | Do this | Pass if |
|------|---------|---------|
| 6.1 | On final Results | Auto-navigates to **Session Summary** (no ghost guess in this run) |
| 6.2 | Check content | Winner headline, insider/mismatch words, leaderboard |
| 6.3 | Check linked profiles | Open **Alex** and **Blake** profiles → games/points updated; Casey unchanged |
| 6.4 | Summary copy | Stats-saved-on-device note if shown |
| 6.5 | **Party Personas** (if button appears) | Sheet opens with persona cards |

### 7. Play Again vs New Game Night

| Step | Do this | Pass if |
|------|---------|---------|
| 7.1 | Tap **Play Again** | Skips lobby → straight to pass-the-phone (same 3 names + profile links) |
| 7.2 | Finish distribution → play one quick round → end game | Session Summary again; games played count increases |
| 7.3 | Tap **New Game Night** | Returns to **Home**; fresh session |

### 8. Host early end (Session Summary without natural win)

| Step | Do this | Pass if |
|------|---------|---------|
| 8.1 | Host again → 3 players → distribute → reach **Discussion** | In-game |
| 8.2 | **⋯** → **End Game Night** → confirm | Session Summary (may lack winner headline if no game finished) |
| 8.3 | Leaderboard still sensible | Points from partial play shown correctly |

### 9. Re-pick roles

| Step | Do this | Pass if |
|------|---------|---------|
| 9.1 | Mid-game **⋯** → **Re-pick Roles** → confirm | Back to **Lobby**, assignments cleared |
| 9.2 | **Distribute Roles** again | New words/roles |

---

## Tier 2 — Stretch tests on one phone (~30 min)

### 10. Ghost + alliance (5+ players)

Add **Dana** and **Ellis** (5 total). Turn **Ghost** on.

- [ ] Outsider counts banner shows 1 Mismatch + 1 Ghost (for 5 players).
- [ ] Play to game end where **Ghost survives**.
- [ ] Results prompt **Ghost word guess** before Session Summary.
- [ ] Wrong guess → still goes to summary after submit.
- [ ] Correct guess → bonus points reflected in leaderboard.

### 11. Shared-rank leaderboard

Play a short session where two linked profiles finish with the **same total points**.

- [ ] Session Summary shows **“tied for 1st”** (or both names sharing rank).
- [ ] Ranks use competition style: 1, 1, 3 — not 1, 2, 3.

### 12. Discussion timer off

Home Settings → timer **off** → new game night → lobby.

- [ ] Discussion has no countdown.
- [ ] You can advance to voting manually when ready.

### 13. Lobby overrides home defaults

Home: timer **on, 3 min**. Lobby: timer **off**.

- [ ] That session uses lobby choice, not home default.

---

## Tier 3 — Two devices (you + one spare)

Required before trusting QR / cloud features with friends.

### 14. QR distribution

Lobby: **Distribution → QR codes**, 4+ players, **I'm playing** on.

- [ ] QR grid shows one code per non-host player.
- [ ] Scan one QR with second device → web card loads (pick → flip → hold).
- [ ] Host uses **My Card** in app (no self-scan).
- [ ] **Check Player Role** on host still works.
- [ ] Complete one round end-to-end.

### 15. Guest voting on phones

Same QR session; enable **Guest voting on phones** in lobby.

- [ ] During **Discussion**, guest vote tallies appear on host.
- [ ] Vote from 2+ web cards for **different** players.
- [ ] Host still confirms elimination on **Voting** screen.

### 16. Revote on tie (needs cloud deploy + 3+ voters)

Use 2–3 real devices or friends:

- [ ] Two guests vote for **Player A**, two for **Player B** (tie).
- [ ] Host sees tie banner + **Start Revote**.
- [ ] After revote, tied players cannot be vote targets on web cards.
- [ ] Second vote breaks tie; host confirms elimination.

---

## Tier 4 — Friends night smoke (5 min before guests)

- [ ] Home → **Host a Game** → real names in seating order.
- [ ] Link profiles for regulars (optional).
- [ ] Rules: player count, ghost on/off, QR vs pass-the-phone, guest voting — **read summary line aloud**.
- [ ] **Distribute Roles** → everyone has a card within ~3 minutes.
- [ ] One test vote (or guest vote) to confirm network/cloud.
- [ ] Know where **⋯ → Scores / Re-pick / End Game Night** live.

---

## Common failures

| Symptom | Likely cause |
|---------|----------------|
| QR scan fails | Cloud not deployed; bad network; wrong URL |
| No guest vote tallies | Guest voting off; not QR/cloud mode; votes not submitted |
| No **Start Revote** | Tie not detected; cloud not updated; only 1 voter |
| Profile stats unchanged | Seat not linked to profile; summary opened twice (stats already applied) |
| **Play Again** goes to lobby | Bug — should skip lobby and re-deal |
| Session Summary in lobby | Bug — should only appear after game end or **End Game Night** |
| Timer wrong | Check home defaults vs lobby Rules override |

---

## Minimum time paths

| Time | Sections |
|------|----------|
| **20 min** | Quick checklist Tier 1 only (through Play Again) |
| **Before QR night** | Tier 1 + Tier 3 (14–16) |
| **Before profiles matter** | Tier 1 sections 2 + 6.3 |

---

## Related docs

- [FEATURE_SPEC.md](FEATURE_SPEC.md) — acceptance criteria
- [MVP_ROADMAP.md](MVP_ROADMAP.md) — build order
- [cloud/README.md](cloud/README.md) — deploy and API
