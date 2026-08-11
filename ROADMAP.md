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

## 6. [ ] Feature: locked achievements show no progress

Every locked achievement row shows the same generic lock icon regardless of how close it is —
a player at 999,900/1,000,000 lifetime Oof looks identical to one at 10. Showing numeric
progress on the countable conditions (`lifetimeEarned`, `rebirths`, `totalNoobLevels`,
`streakDays`, `zoneNoobLevels`) is a well-established retention hook (seeing "almost there"
pulls people back in) and costs little to add given the data's already computed for
`conditionMet`.

## 7. [ ] Feature: no way to back up/restore a save manually

Saves are local-only JSON in the app's Documents directory with no export path. This is a
real risk *specifically* for this project's testing setup: Sideloadly's free-Apple-ID signing
expires every 7 days, and reinstalling to re-sign can wipe local app data — there's currently
no way to protect progress against that. Add an export-to-clipboard/share-sheet "backup code"
(base64 of the save JSON, or similar) and a matching import flow in Settings.

## 8. [ ] Feature: no reminder when offline-progress caps out

Idle games live and die on getting players to come back at the right moment. Right now there's
no nudge — a player who closes the app has no signal that their offline-earnings cap (8h, or
more with Extended Rest) has been reached and they're leaving value on the table. Schedule a
local notification (no server needed) for when the cap will be hit, cancel it on next
foreground/dismiss, and request notification permission the first time it's relevant rather
than on cold launch.
