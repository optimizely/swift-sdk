# Local Holdout Feature Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Suppress local holdout logic behind a feature gate so the feature-rollout release ships without local holdout support. When the backend is ready, flip the gate to `true`.

**Architecture:** Add a standalone `FeatureGates` struct with a `static var localHoldouts` flag (default `false`). Guard the two local holdout evaluation blocks in `DefaultDecisionService.swift` behind this flag. Test setUp/tearDown overrides the flag to `true` so all existing tests pass without modification.

**Tech Stack:** Swift, XCTest

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Sources/Utils/FeatureGates.swift` | Create | Standalone `FeatureGates` struct with `localHoldouts` flag |
| `Sources/Implementation/DefaultDecisionService.swift` | Modify | Guard local holdout checks in experiment and delivery rule methods behind gate |
| `Tests/OptimizelyTests-Common/DecisionServiceTests_LocalHoldouts.swift` | Modify | Override gate to `true` in setUp/tearDown |
| `Tests/OptimizelyTests-DataModel/HoldoutConfigTests.swift` | Modify | Override gate to `true` in setUp/tearDown |
| `Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_Holdouts.swift` | Modify | Override gate to `true` in setUp/tearDown |
| `Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_With_Holdouts_Reasons.swift` | Modify | Override gate to `true` in setUp/tearDown |
| `Tests/OptimizelyTests-Common/DecisionListenerTest_Holdouts.swift` | Modify | Override gate to `true` in setUp/tearDown |

---

### Task 1: Create `FeatureGates` struct

**Files:**
- Create: `Sources/Utils/FeatureGates.swift`

- [ ] **Step 1: Create the FeatureGates file**

Create `Sources/Utils/FeatureGates.swift`:

```swift
//
// Copyright 2026, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct FeatureGates {
    static var localHoldouts = false
}
```

- [ ] **Step 2: Build to verify no compilation errors**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/Utils/FeatureGates.swift
git commit -m "feat: add FeatureGates struct with localHoldouts flag

Default false to suppress local holdout logic until backend is ready.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Guard local holdout checks in DefaultDecisionService

**Files:**
- Modify: `Sources/Implementation/DefaultDecisionService.swift:660-674` (experiment rule local holdout block)
- Modify: `Sources/Implementation/DefaultDecisionService.swift:718-732` (delivery rule local holdout block)

- [ ] **Step 1: Guard experiment rule local holdout block**

In `getVariationFromExperimentRule()`, wrap the local holdout block (lines 660-674) with the feature gate.

Replace:

```swift
        // check local holdouts targeting this rule
        let localHoldouts = config.getHoldoutsForRule(ruleId: rule.id)
        for holdout in localHoldouts {
            let holdoutDecision = getVariationForHoldout(config: config,
                                                         flagKey: flagKey,
                                                         holdout: holdout,
                                                         user: user,
                                                         options: options)
            reasons.merge(holdoutDecision.reasons)
            if let variation = holdoutDecision.result {
                // User is in holdout — return holdout variation immediately, skip this rule
                let variationDecision = VariationDecision(variation: variation, holdout: holdout)
                return DecisionResponse(result: variationDecision, reasons: reasons)
            }
        }
```

With:

```swift
        // check local holdouts targeting this rule
        if FeatureGates.localHoldouts {
            let localHoldouts = config.getHoldoutsForRule(ruleId: rule.id)
            for holdout in localHoldouts {
                let holdoutDecision = getVariationForHoldout(config: config,
                                                             flagKey: flagKey,
                                                             holdout: holdout,
                                                             user: user,
                                                             options: options)
                reasons.merge(holdoutDecision.reasons)
                if let variation = holdoutDecision.result {
                    // User is in holdout — return holdout variation immediately, skip this rule
                    let variationDecision = VariationDecision(variation: variation, holdout: holdout)
                    return DecisionResponse(result: variationDecision, reasons: reasons)
                }
            }
        }
```

- [ ] **Step 2: Guard delivery rule local holdout block**

In `getVariationFromDeliveryRule()`, wrap the local holdout block (lines 718-732) with the same gate.

Replace:

```swift
        // check local holdouts targeting this delivery rule
        let localHoldouts = config.getHoldoutsForRule(ruleId: rule.id)
        for holdout in localHoldouts {
            let holdoutDecision = getVariationForHoldout(config: config,
                                                         flagKey: flagKey,
                                                         holdout: holdout,
                                                         user: user,
                                                         options: options)
            reasons.merge(holdoutDecision.reasons)
            if let variation = holdoutDecision.result {
                // User is in holdout — return holdout variation with holdout info
                let decision = DeliveryRuleDecision(variation: variation, skipToEveryoneElse: skipToEveryoneElse, holdout: holdout)
                return DecisionResponse(result: decision, reasons: reasons)
            }
        }
```

With:

```swift
        // check local holdouts targeting this delivery rule
        if FeatureGates.localHoldouts {
            let localHoldouts = config.getHoldoutsForRule(ruleId: rule.id)
            for holdout in localHoldouts {
                let holdoutDecision = getVariationForHoldout(config: config,
                                                             flagKey: flagKey,
                                                             holdout: holdout,
                                                             user: user,
                                                             options: options)
                reasons.merge(holdoutDecision.reasons)
                if let variation = holdoutDecision.result {
                    // User is in holdout — return holdout variation with holdout info
                    let decision = DeliveryRuleDecision(variation: variation, skipToEveryoneElse: skipToEveryoneElse, holdout: holdout)
                    return DecisionResponse(result: decision, reasons: reasons)
                }
            }
        }
```

- [ ] **Step 3: Build to verify no compilation errors**

Run: `swift build 2>&1 | tail -5`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Sources/Implementation/DefaultDecisionService.swift
git commit -m "feat: guard local holdout evaluation behind FeatureGates.localHoldouts

Both experiment rule and delivery rule local holdout checks are now
gated. When false, these blocks are skipped entirely. Global holdout
evaluation in getDecisionForFlag() is unaffected.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Override feature gate in test setUp/tearDown

**Files:**
- Modify: `Tests/OptimizelyTests-Common/DecisionServiceTests_LocalHoldouts.swift:53-61`
- Modify: `Tests/OptimizelyTests-DataModel/HoldoutConfigTests.swift:19`
- Modify: `Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_Holdouts.swift:46`
- Modify: `Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_With_Holdouts_Reasons.swift:45`
- Modify: `Tests/OptimizelyTests-Common/DecisionListenerTest_Holdouts.swift:62`

- [ ] **Step 1: Add gate override to DecisionServiceTests_LocalHoldouts**

Add `FeatureGates.localHoldouts = true` at the start of `setUp()`, and add a `tearDown()` method to reset it. This class has no existing `tearDown`.

The existing `setUp()` becomes:

```swift
    override func setUp() {
        super.setUp()
        FeatureGates.localHoldouts = true

        // Load a real datafile for testing
        optimizely = OTUtils.createOptimizely(datafileName: "decide_datafile",
                                             clearUserProfileService: true)
        config = optimizely.config!
        decisionService = optimizely.decisionService as? DefaultDecisionService
    }

    override func tearDown() {
        FeatureGates.localHoldouts = false
        super.tearDown()
    }
```

- [ ] **Step 2: Add gate override to HoldoutConfigTests**

This class has no existing `setUp`/`tearDown`. Add them right after the class declaration (line 19):

```swift
class HoldoutConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
        FeatureGates.localHoldouts = true
    }

    override func tearDown() {
        FeatureGates.localHoldouts = false
        super.tearDown()
    }

    func testEmptyHoldouts_shouldHaveEmptyMaps() {
        // ... existing code unchanged
```

- [ ] **Step 3: Add gate override to OptimizelyUserContextTests_Decide_Holdouts**

Add the gate override at the start of the existing `setUp()` (after `super.setUp()`) and add a `tearDown()`. The class has no existing `tearDown`.

```swift
    override func setUp() {
        super.setUp()
        FeatureGates.localHoldouts = true
        // ... rest of existing setUp code unchanged
    }

    override func tearDown() {
        FeatureGates.localHoldouts = false
        super.tearDown()
    }
```

- [ ] **Step 4: Add gate override to OptimizelyUserContextTests_Decide_With_Holdouts_Reasons**

Add the gate override at the start of the existing `setUp()` (after `super.setUp()`) and add a `tearDown()`. The class has no existing `tearDown`.

```swift
    override func setUp() {
        super.setUp()
        FeatureGates.localHoldouts = true
        // ... rest of existing setUp code unchanged
    }

    override func tearDown() {
        FeatureGates.localHoldouts = false
        super.tearDown()
    }
```

- [ ] **Step 5: Add gate override to DecisionListenerTests_Holdouts**

Add the gate override at the start of the existing `setUp()` (after `super.setUp()`) and add a `tearDown()`. The class has no existing `tearDown`.

```swift
    override func setUp() {
        super.setUp()
        FeatureGates.localHoldouts = true
        // ... rest of existing setUp code unchanged
    }

    override func tearDown() {
        FeatureGates.localHoldouts = false
        super.tearDown()
    }
```

- [ ] **Step 6: Build and run tests**

Run: `swift test 2>&1 | tail -20`
Expected: All tests pass. Local holdout tests pass because the gate is overridden to `true` in setUp. Non-holdout tests are unaffected because the gate defaults to `false`.

- [ ] **Step 7: Commit**

```bash
git add Tests/OptimizelyTests-Common/DecisionServiceTests_LocalHoldouts.swift \
       Tests/OptimizelyTests-DataModel/HoldoutConfigTests.swift \
       Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_Holdouts.swift \
       Tests/OptimizelyTests-Common/OptimizelyUserContextTests_Decide_With_Holdouts_Reasons.swift \
       Tests/OptimizelyTests-Common/DecisionListenerTest_Holdouts.swift
git commit -m "test: override FeatureGates.localHoldouts in holdout test setUp/tearDown

All holdout test classes set the gate to true in setUp and reset to false
in tearDown. Existing test methods are unchanged — they pass because the
gate enables the local holdout code paths during test execution.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Verify end-to-end behavior

**Files:** None (verification only)

- [ ] **Step 1: Verify global holdouts still work with gate off**

Run the global holdout tests specifically:

```bash
xcodebuild test \
  -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:OptimizelyTests-Common-iOS/DecisionServiceTests_Holdouts 2>&1 | tail -20
```

Expected: All global holdout tests pass (they don't depend on the local holdout gate).

- [ ] **Step 2: Run full test suite**

```bash
xcodebuild test \
  -workspace OptimizelySwiftSDK.xcworkspace \
  -scheme OptimizelySwiftSDK-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "Test Suite|Executed|failed"
```

Expected: All test suites pass with 0 failures.

---

## Future: Enabling Local Holdouts

When the backend is ready, the only change needed is:

```swift
// In FeatureGates.swift
struct FeatureGates {
    static var localHoldouts = true  // ← flip from false to true
}
```

Then remove the `setUp`/`tearDown` overrides from the 5 test files (they become no-ops but are unnecessary cleanup).
