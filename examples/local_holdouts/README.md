# Local Holdouts Bug Bash -- Swift SDK

## What is this?

A hands-on exploration tool for testing local holdouts in the SDK. This is
**not an automated test suite** -- it's a starting point for manual QA.

The code contains working SDK calls with commented-out blocks you can
uncomment, modify, and extend. The goal is to try unusual things and find
bugs that automated tests miss.

**Scope: Local holdouts only (single project). Cross-project holdouts are
not in scope for this bug bash.**

## How local holdouts work

Holdouts exclude users from experiments so you can measure the overall impact
of running experiments. They come in two types:

| Type | Datafile field | Behavior |
|------|---------------|----------|
| **Global** | `includedRules: null` | Applies to ALL rules on ALL flags |
| **Local** | `includedRules: ["rule_id"]` | Applies only to the specified rules |
| **Empty local** | `includedRules: []` | Targets nothing, effectively disabled (NOT global) |

**Evaluation priority** (highest to lowest):
1. Global holdouts -- flag-level, before any rule evaluation
2. Forced decisions (`setForcedDecision`) -- per-rule, overrides everything below
3. Local holdouts -- per-rule, after forced decisions
4. Normal experiment/rollout bucketing

**When a user is held out**, the decision looks like this:
- `decision.ruleKey` = the holdout key (e.g. `"my_holdout"`)
- `decision.variationKey` = `"ho_off_key"`
- `decision.enabled` = `false`
- Impression event metadata: `rule_type: "holdout"`, `campaign_id: ""`

## 1. Set up your Optimizely project

Create or reuse a project in your Optimizely environment:

1. **Create a custom audience:**
   - Name: `audience1`
   - Condition: custom attribute `country` equals `"us"`

2. **Create flags with rules:**

   | Flag Key | Rule Key (A/B Test) | Variations | Traffic | Audience |
   |----------|---------------------|------------|---------|----------|
   | `flag1` | `ab1` | on, off | 100% | Everyone |
   | `flag2` | `ab2` | on, off | 100% | Everyone |

3. **Create holdouts:**

   | Holdout Name | Type | Targeted Rules | Traffic | Audience |
   |--------------|------|----------------|---------|----------|
   | `local_holdout` | Local | `ab1` only | 50% | Everyone |
   | `global_holdout` | Global | All rules | 10% | Everyone |

4. Activate all rules and holdouts.

5. Copy your **SDK Key** from Settings > Environments.

## 2. Run the bug bash

There are two ways to run. Pick whichever works for you.

---

### Option A: Command line (no Xcode needed)

This is the easiest way. You only need the Swift compiler (comes with
macOS Command Line Tools).

```bash
git clone git@github.com:optimizely/swift-sdk.git
cd swift-sdk
git checkout matjaz/local-holdouts-bug-bash
cd examples/local_holdouts
```

Edit `Sources/main.swift`:
- Set `SDK_KEY` to your SDK key (line 22)
- If using a **staging/inte/prep** environment, the code already points to
  the staging CDN. For **production** SDK keys, comment out the two
  `datafileHandler` lines

Run:
```bash
swift run
```

Edit `Sources/main.swift` to uncomment test cases, then `swift run` again.

---

### Option B: Xcode (iOS demo app)

Use this if you have Xcode installed and want to run the iOS demo app.

```bash
git clone git@github.com:optimizely/swift-sdk.git
cd swift-sdk
git checkout matjaz/local-holdouts-bug-bash
pod update
```

Open `OptimizelySwiftSDK.xcworkspace` in Xcode:
1. Set the scheme to **DemoSwiftiOS**
2. Edit `DemoSwiftApp/AppDelegate.swift`:
   - Set `sdkKey` to your SDK key (line 76)
   - If using a staging/inte environment, add a `datafileHandler` pointing
     to the staging CDN (see `main.swift` for the pattern)
3. **Build & Run** (`Cmd+R`) -- check the Xcode console for output, ignore
   the phone emulator

Edit `AppDelegate.swift` to uncomment test cases, then Build & Run again.

---

## 3. Explore

Both files have the same structure:
- **Visible code** runs on startup: project inspection, basic decide, try 20 users
- **Commented-out blocks** -- uncomment one at a time to test:
  - Decide with attributes (audience-targeted holdouts)
  - Forced decisions (flag-level and rule-level)
  - DecideAll / DecideForKeys
  - EnabledFlagsOnly
  - DisableDecisionEvent
  - Track event after holdout
  - Decision listener / Track listener
  - Distribution check (1000 users)
  - Wait for datafile refresh (keep SDK alive for UI changes)
  - Concurrent decide calls (thread safety)

Combine blocks, change user IDs, add your own logic. The SDK polls every
30 seconds, so changes in the Optimizely UI are picked up automatically.

## Scenario ideas

These are things to try during the bug bash. They are NOT prescriptive
scripts -- use them as inspiration for exploration.

### UI mutation scenarios
Make changes in the Optimizely UI while the SDK is running (use the "wait
for datafile refresh" code block to keep the SDK alive).

| # | What to try | What could break |
|---|------------|-----------------|
| 1 | **Delete a running holdout** -- note held-out users, delete holdout, re-check | SDK crashes, stale holdout still applied, users don't recover |
| 2 | **Change holdout traffic** -- try 50%->0%, 50%->100%, 10%->90% | Wrong distribution, users not re-bucketed |
| 3 | **Switch local to global** -- local holdout on ab1, switch to global | flag2 not affected when it should be |
| 4 | **Switch global to local** -- global holdout, switch to local targeting one rule | Other flags still incorrectly held out |
| 5 | **Add audience to holdout** -- holdout with Everyone, add audience condition | Users without attribute still held out |
| 6 | **Remove audience from holdout** -- audience holdout, remove audience | Holdout doesn't expand to all users |
| 7 | **Delete the rule a holdout targets** -- local holdout targets ab1, delete ab1 | Crash, nil reference, or holdout leaks to other rules |
| 8 | **Pause a holdout** -- running holdout at 50%, pause it | Holdout still applied after pause |
| 9 | **Add holdout to running experiment** -- experiment with no holdouts, add one | New holdout not picked up |

### Flag interaction edge cases

| # | What to try | Expected |
|---|------------|----------|
| 10 | **Forced decision on held-out user** -- find held-out user, `setForcedDecision` | Forced variation wins, holdout bypassed. Remove forced decision: holdout returns. |
| 11 | **Rule-level forced decision** -- force at rule level, not flag level | Overrides holdout for that rule only |
| 12 | **DecideAll with global holdout** -- user hits global holdout | ALL flags show holdout decision |
| 13 | **DecideForKeys vs DecideAll** -- compare results for same user | Identical decisions for requested flags |
| 14 | **EnabledFlagsOnly + holdout** -- held-out flags have enabled=false | Held-out flags excluded from results |
| 15 | **Decision listener metadata** -- register listener, trigger holdout | Listener fires with holdout ID and rule_type="holdout" |
| 16 | **Track after holdout** -- user held out, then `trackEvent` | Conversion event fires successfully |
| 17 | **DisableDecisionEvent + holdout** -- decide with option | Same decision, no impression dispatched |

### Stress and boundary scenarios

| # | What to try | What could break |
|---|------------|-----------------|
| 18 | **10+ holdouts on same rule** -- different traffic each | Wrong evaluation order, incorrect cumulative rate |
| 19 | **Large project** (100+ flags) -- add holdouts | Performance degradation, timeouts |
| 20 | **0% traffic holdout** -- should never apply | Holdout incorrectly applied |
| 21 | **Empty includedRules []** -- local holdout targeting nothing | Incorrectly treated as global |
| 22 | **Rapid UI changes** -- 5 changes in 60 seconds | Stale decisions, race conditions |
| 23 | **Concurrent decide calls** -- multiple threads | Crashes, data races |
| 24 | **Same user, different attributes** -- decide without, then with attributes | Audience holdout activates only with matching attributes |
| 25 | **Long/special user IDs** -- 1000+ chars, unicode, emojis | Bucketing breaks, crashes |
| 26 | **Global holdout consistency** -- user held out on flag1, check flag2 | Same user should be held out on all flags |
| 27 | **Holdout on flag with no rules** -- create holdout targeting non-existent rule | Should return default off without crash |

## Log bugs here

https://episerver99-my.sharepoint.com/:x:/g/personal/matjaz_pirnovar_optimizely_com/IQCkcX_sg-ZeS7uNrKPc6wf8AVKqgPsQJrSjciNNJy035KM?e=E1XPcA
