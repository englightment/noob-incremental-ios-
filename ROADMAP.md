# Noob Incremental — Roadmap

Working list of the next bugs/features to tackle, based on the current state of the game.
Checked off items include the commit that shipped them.

## 1. [x] Bug: save loading isn't resilient to schema changes

`SaveManager.load()` relies on `GameState`'s synthesized `Decodable` conformance, which
requires every stored key to be present. Any future field addition to `GameState` (which has
happened many times already this session) means a save file written *before* that field
existed will fail to decode — and `load()` silently falls back to `.newGame`, wiping the
player's progress with no warning. Fix: give `GameState` a custom `init(from:)` that decodes
each field with `decodeIfPresent(...) ?? default` instead of an all-or-nothing decode, so
adding fields going forward never nukes an existing save.

## 2. [x] Bug: achievements list renders eagerly instead of lazily

`MoreSheet.achievementsSection` builds all ~30 achievement rows inside a plain `VStack` +
`ForEach` every time the sheet is opened, instead of a `LazyVStack`. Harmless today, but it'll
only get worse as more achievements are added. Switch it to lazy rendering.

## 3. [x] Feature: no way to extend the offline-progress cap

`GameBalance.maxOfflineProgressDuration` is a hardcoded 8 hours with no upgrade path — a
classic idle-game gap players expect to be able to close. Add a way to extend it (e.g. a new
Rebirth-shop upgrade using a new `offlineCapBonus` effect).

## 4. [x] Feature: no first-launch onboarding

Brand-new players are dropped straight into the game with zero explanation of the core loop
(buy Noobs, watch Oof grow, eventually Rebirth). Add a lightweight one-time first-launch
overlay/tip that explains this in a few seconds, then never shows again.

## 5. [x] Polish: no Reduce Motion support

The app leans heavily on decorative animation (ambient background blobs, glow pulses, spring
transitions on tab/world switches) with no way to tone it down. Respect
`UIAccessibility.isReduceMotionEnabled` (via `@Environment(\.accessibilityReduceMotion)`) to
disable or shorten the purely-decorative animations for players who want/need it — also an
App Store accessibility best practice.

## 6. [x] Feature: locked achievements show no progress

Every locked achievement row shows the same generic lock icon regardless of how close it is —
a player at 999,900/1,000,000 lifetime Oof looks identical to one at 10. Showing numeric
progress on the countable conditions (`lifetimeEarned`, `rebirths`, `totalNoobLevels`,
`streakDays`, `zoneNoobLevels`) is a well-established retention hook (seeing "almost there"
pulls people back in) and costs little to add given the data's already computed for
`conditionMet`.

## 7. [x] Feature: no way to back up/restore a save manually

Saves are local-only JSON in the app's Documents directory with no export path. This is a
real risk *specifically* for this project's testing setup: Sideloadly's free-Apple-ID signing
expires every 7 days, and reinstalling to re-sign can wipe local app data — there's currently
no way to protect progress against that. Add an export-to-clipboard/share-sheet "backup code"
(base64 of the save JSON, or similar) and a matching import flow in Settings.

## 8. [x] Feature: no reminder when offline-progress caps out

Idle games live and die on getting players to come back at the right moment. Right now there's
no nudge — a player who closes the app has no signal that their offline-earnings cap (8h, or
more with Extended Rest) has been reached and they're leaving value on the table. Schedule a
local notification (no server needed) for when the cap will be hit, cancel it on next
foreground/dismiss, and request notification permission the first time it's relevant rather
than on cold launch.

## 9. [x] Feature: achievement list has no sense of priority

Now that locked achievements show progress (#6), the list itself still renders in raw catalog
order — a 90%-done achievement can sit below a 2%-done one with no way to tell at a glance
what's actually close. Sort so unlocked achievements settle to the bottom (or top, TBD by feel)
and locked ones order by proximity-to-completion, so the list reads as "here's what to chase
next" instead of a fixed static list.

## 10. [x] Feature: no in-app purchase scaffolding

`GameState.purchasedProductIDs` has sat as an unused stub since early in the project —
clearly the intent was always to add IAP eventually, and every comparable incremental game
has some (remove ads, a starter/support pack, etc). Build the StoreKit 2 product-fetch and
purchase flow against Apple's public test product IDs (same "test now, swap for real App
Store Connect config before release" pattern already used for the AdMob integration), gated
behind a simple entitlement check (e.g. an "ads removed" flag derived from
`purchasedProductIDs`).

## 11. [x] Polish: no way to opt out of the offline-cap reminder notification specifically

The reminder added in #8 is all-or-nothing via the OS-level permission prompt — a player who
wants every other feature but finds this one nagging has to fully revoke notification
permission in iOS Settings to stop it. Add an in-app Settings toggle that gates whether
`GameViewModel.stop()` schedules the reminder at all, independent of OS permission.

## 12. [x] Bug: purchased non-consumables have no restore path if local data is lost

`GameState.purchasedProductIDs` (see #10) is currently the *only* record of IAP ownership.
This is a real risk for the exact reason #7 exists: Sideloadly's free-Apple-ID signing
expires every 7 days, and reinstalling to re-sign can wipe local app data. A player who paid
for the Supporter Pack would lose the entitlement with no way to get it back in-app, even
though StoreKit itself still knows they own it. Add a "Restore Purchases" action that
reconciles `GameState` against `Transaction.currentEntitlements` and reapplies any owned
non-consumables via `IAPSystem.applyPurchase`.

## 13. [x] Polish: primary controls have no VoiceOver labels

The UI relies entirely on visual layout (icons, color, position) with no `accessibilityLabel`/
`accessibilityValue` on the highest-traffic controls (currency display, generator buy buttons,
the tab bar, the rebirth button) — unusable with VoiceOver despite #5 already covering Reduce
Motion. Add labels to the controls a player touches most.

## 14. [x] Polish: fixed-size fonts ignore Dynamic Type

Nearly all text uses fixed `.font(...)` sizes with no accommodation for the user's preferred
text size — another App Store accessibility gap alongside #5 and #13. Audit the highest-traffic
screens and let their text scale with Dynamic Type instead of clipping/truncating.

## 15. [x] Polish: More sheet controls still lack VoiceOver labels

#13 scoped itself to the main gameplay loop (currency display, buy buttons, tab bar, rebirth)
and explicitly deferred the More sheet's ad-boost, IAP, backup, redeem-code, and settings
controls to keep that change reviewable. Finish the sweep: add accessibilityLabel/Value/Hint
to the "Watch Ad" buttons, the Supporter Pack / Rune Shard pack buttons, Restore Purchases,
Copy/Restore backup code, Redeem, and the Sound/Haptics/Offline Reminder toggles.

## 16. [x] Polish: unlock moments have no VoiceOver announcement

Achievement toasts, the daily-reward banner, and milestone confetti are all purely visual —
a VoiceOver user gets no signal that something just happened, unlike a sighted player who
sees the toast animate in. Post a `UIAccessibility.post(notification: .announcement, ...)`
alongside each of these so the moment doesn't just silently pass by.

## 17. [x] Feature: no App Store review prompt

Standard practice for this genre — asking at a well-earned moment (after a rebirth, a
handful of achievements) rather than on cold launch. Missing entirely right now. Add a pure
"should we ask" function (mirroring OnboardingSystem's shape) gating a call to StoreKit's
`AppStore.requestReview(in:)`, with a one-shot guard so it only ever fires once per
reasonable window (Apple also rate-limits this itself, but the app shouldn't rely solely on
that).

## 18. [x] Feature: no way to share progress

Every comparable incremental game has some kind of "brag" mechanic. Add a native `ShareLink`
somewhere reachable (Stats section of the More sheet is the natural spot) that shares a short
plain-text summary — lifetime Oof earned, rebirth count, achievements unlocked. The summary
string itself should be a pure, testable function.

## 19. [x] Bug: two views still ignore Reduce Motion despite #5's sweep

Found while working on #18: `FloatingTextItemView` (the "+X" VFX text that plays on every
single buy/rebirth — likely the single most frequent animation in the whole app) and
`OnboardingOverlay`'s fade-in both call `withAnimation`/`.animation` unconditionally, with no
`@Environment(\.accessibilityReduceMotion)` check. Both were added around the same time as
#4's onboarding work, before #5's Reduce Motion audit landed, and slipped through.

## 20. [x] Polish: Redeem Code button doesn't disable on an empty field

Tapping "Redeem" with an empty code field just round-trips to "Invalid code." instead of
being disabled outright — inconsistent with the backup "Restore" button a few sections down,
which already disables on `importCodeText.isEmpty`.

## 21. [x] Feature: Zone 4, a new endgame frontier

Zones 2 (Overworks) and 3 (Ascension Spire) each shipped 3-5 new Noob tiers plus matching
achievements, and both have been fully built out for a while now — meanwhile #17/#18 added
IAP and sharing, which only matter if there's fresh content to earn/brag about. Add a fourth
zone following the same pattern: new `GeneratorDefinition`s in the new zone, a `WorldCatalog`
entry, zone-completion achievements (mirroring `allZoneNoobsOwned`), and balance numbers that
continue the existing cost/output curve rather than restarting it.

## 22. [x] Feature: a Zone 4-themed Minion

Zone 3's launch included two matching Minions (#58) to keep that reward system's pacing
consistent with new content. Zone 4 (#21) shipped without one — add at least one
Void-Expanse-themed Minion, unlocked via a Zone 4 achievement (e.g. `voidbound` or
`void_master`), following the existing MinionCatalog/MinionSystem pattern.

## 23. [x] Balance: verify GeneratorMilestoneSystem thresholds still make sense for Zone 4

`GeneratorMilestoneSystem`'s per-level multiplier thresholds were presumably tuned against
Zones 1-3's level-up pace. Zone 4 (#21) has a noticeably steeper cost curve than earlier
zones (each tier costs ~15x the previous, up from Zone 1's ~9-11x jumps) - check whether the
existing milestone thresholds still land at reasonable points for Zone 4 Noobs, or whether
they need their own tuning so late-game milestone bonuses don't feel out of reach.

**Finding: no change needed.** The premise didn't hold up once I actually read the code.
Milestone thresholds (`[25, 50, 100, 250, 500, 1_000]`) are pure *level counts*, and every
generator - Zone 4's included - levels up along the exact same `Formulas.levelCost` curve
(`growthRate: 1.12`, no per-zone override; confirmed in `GeneratorStore.cost`). A Zone 4
Noob's baseCost/baseOutput being ~15x steeper per *tier* has no bearing on how many
purchases it takes to go from level 24 to 25 on any single Noob - that's governed entirely
by the shared growth rate, not the starting cost. The system was already zone-agnostic by
design; there was nothing to tune.

## 24. [x] Feature: Game Center integration (achievements + a leaderboard)

Missing entirely, and standard for the genre. Add GameKit scaffolding following the same
"test now, verify what I can't on a real device before release" pattern already used for
AdMob (#52, prior session) and StoreKit (#10): authenticate the local player on launch,
report `GKAchievement` progress alongside the existing achievement-unlock flow (mirroring,
not replacing, the in-app AchievementStore/toast system), and add one leaderboard for
lifetime Oof earned. Needs the Game Center capability enabled in project.yml's Info.plist
entries; the actual authentication UI and leaderboard rendering can't be verified without a
signed-in device, same caveat as RewardedAdManager/IAPManager.
