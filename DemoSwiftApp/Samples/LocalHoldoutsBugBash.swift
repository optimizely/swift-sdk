/*
============================================================
Local Holdouts Bug Bash -- Swift SDK
============================================================

OVERVIEW:
Local holdouts target specific experiment/delivery rules rather than applying
globally to all rules across all flags. This bug bash validates that the SDK
correctly evaluates local holdouts, handles UI changes (datafile updates),
and doesn't break under edge cases.

HOW LOCAL HOLDOUTS WORK:

  Evaluation priority (highest to lowest):
    1. Global holdouts  -- flag-level, before any rule evaluation
    2. Forced decisions  -- per-rule, SetForcedDecision overrides everything below
    3. Local holdouts    -- per-rule, after forced decisions
    4. Normal experiment/rollout bucketing

  Holdout types (determined by includedRules field in datafile):
    - Global:  includedRules = null     --> applies to ALL rules on ALL flags
    - Local:   includedRules = ["5001"] --> applies only to rule 5001
    - Empty:   includedRules = []       --> local holdout targeting nothing (effectively disabled, NOT global)

  When a user is held out:
    - decision.variationKey = "ho_off_key"
    - decision.enabled      = false
    - decision.ruleKey      = the holdout key (e.g. "my_local_holdout")
    - Impression event:  rule_type = "holdout", campaign_id = ""

OPTIMIZELY PROJECT SETUP:

  1. Create or reuse a project in your Optimizely environment.
  2. Create a custom audience:
     - Name: "Custom Attr Audience"
     - Condition: custom attribute "customattr" equals "yes"
  3. Create flags with A/B test rules:

     Flag Key   | Rule Key (A/B Test) | Variations | Traffic | Audience
     -----------|---------------------|------------|---------|----------
     flag_a     | rule_a              | on, off    | 100%    | Everyone
     flag_b     | rule_b              | on, off    | 100%    | Everyone

  4. Create holdouts:

     Holdout Name     | Type   | Targeted Rules   | Traffic | Audience
     -----------------|--------|------------------|---------|-------------------
     local_holdout    | Local  | rule_a only      | 50%     | Everyone
     global_holdout   | Global | All rules        | 10%     | Everyone

  5. Activate all rules and holdouts.
  6. Copy your SDK Key from Settings -> Environments.
  7. Update the sdkKey constant below.

RUNNING:
  This file is a self-contained class. Call LocalHoldoutsBugBash.run() from your
  AppDelegate or a test harness after the SDK is initialized. Alternatively, paste
  the contents of run() into a playground or command-line tool.

============================================================
*/

import Foundation
import Optimizely

class LocalHoldoutsBugBash {

    // ============================================================
    // CONFIGURATION -- Update these for your environment
    // ============================================================
    static let sdkKey = "YOUR_SDK_KEY_HERE"

    // Flags and rules -- must match your project setup
    static let flagA = "flag_a"
    static let flagB = "flag_b"

    // Audience attribute
    static let attrKey = "customattr"
    static let attrMatch = "yes"

    static func run() {
        // ============================================================
        // Modify the code below to explore holdouts
        // ============================================================
        //
        // This is your sandbox. The SDK client is created with polling enabled
        // (refreshes datafile every 30 seconds). Make changes in the Optimizely
        // UI, wait ~30s, then re-run to see the updated behavior.
        //
        // Uncomment sections below to try different things. Modify freely.

        guard sdkKey != "YOUR_SDK_KEY_HERE" else {
            print("ERROR: Set your SDK key in the sdkKey constant at the top of LocalHoldoutsBugBash.swift")
            return
        }

        let optimizely = createLiveClient(sdkKey: sdkKey)

        // Show current project state (flags, rules, holdouts)
        inspectProject(optimizely)

        // ----------------------------------------------------------
        // BASIC: Decide on a flag and see what happens
        // ----------------------------------------------------------
        print("\n--- Basic decide ---")
        let user = optimizely.createUserContext(userId: "user_123")
        let d = user.decide(key: flagA, options: [.includeReasons])
        printDecision(label: "user_123 on \(flagA)", decision: d)

        // ----------------------------------------------------------
        // TRY DIFFERENT USERS: Some will be held out, some won't
        // ----------------------------------------------------------
        print("\n--- Try multiple users ---")
        for i in 1...20 {
            let uid = "user_\(i)"
            let uc = optimizely.createUserContext(userId: uid)
            let d = uc.decide(key: flagA)
            let tag = isHoldout(d) ? "HOLDOUT:\(d.ruleKey ?? "")" : "normal"
            print(String(format: "  %-15s %-30s var=%-10s enabled=%@",
                         uid, tag, d.variationKey ?? "nil", d.enabled ? "true" : "false"))
        }

        // ----------------------------------------------------------
        // DECIDE WITH ATTRIBUTES: Test audience-targeted holdouts
        // ----------------------------------------------------------
        // print("\n--- With audience attributes ---")
        // let userWithAttr = optimizely.createUserContext(userId: "user_123",
        //                                                 attributes: [attrKey: attrMatch])
        // let d2 = userWithAttr.decide(key: flagA, options: [.includeReasons])
        // printDecision(label: "user_123 with customattr=yes", decision: d2)
        //
        // // Same user WITHOUT the attribute -- should NOT hit audience holdout
        // let userNoAttr = optimizely.createUserContext(userId: "user_123")
        // let d3 = userNoAttr.decide(key: flagA)
        // printDecision(label: "user_123 without attribute", decision: d3)

        // ----------------------------------------------------------
        // FORCED DECISIONS: Override holdout at flag level
        // ----------------------------------------------------------
        // print("\n--- Forced decision (flag level) ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        //
        // // Normal decision first
        // let before = uc.decide(key: flagA)
        // printDecision(label: "Before forced decision", decision: before)
        //
        // // Force variation to "on" -- should bypass holdout
        // let ctx = OptimizelyDecisionContext(flagKey: flagA)
        // let fd = OptimizelyForcedDecision(variationKey: "on")
        // _ = uc.setForcedDecision(context: ctx, decision: fd)
        //
        // let forced = uc.decide(key: flagA)
        // printDecision(label: "With forced decision", decision: forced)
        //
        // // Remove forced decision -- holdout should return
        // _ = uc.removeForcedDecision(context: ctx)
        // let after = uc.decide(key: flagA)
        // printDecision(label: "After removing forced decision", decision: after)

        // ----------------------------------------------------------
        // FORCED DECISIONS: Override at rule level (more specific)
        // ----------------------------------------------------------
        // print("\n--- Forced decision (rule level) ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let ruleCtx = OptimizelyDecisionContext(flagKey: flagA, ruleKey: "rule_a")
        // let ruleFD = OptimizelyForcedDecision(variationKey: "on")
        // _ = uc.setForcedDecision(context: ruleCtx, decision: ruleFD)
        // let d = uc.decide(key: flagA)
        // printDecision(label: "Rule-level forced decision", decision: d)
        // _ = uc.removeAllForcedDecisions()

        // ----------------------------------------------------------
        // DECIDE ALL: See holdouts across all flags at once
        // ----------------------------------------------------------
        // print("\n--- DecideAll ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let all = uc.decideAll()
        // for (fk, d) in all {
        //     let tag = isHoldout(d) ? " [HOLDOUT]" : ""
        //     print(String(format: "  %-15s rule=%-20s var=%-10s enabled=%@%@",
        //                  fk, d.ruleKey ?? "", d.variationKey ?? "nil",
        //                  d.enabled ? "true" : "false", tag))
        // }

        // ----------------------------------------------------------
        // DECIDE FOR KEYS: Check subset of flags
        // ----------------------------------------------------------
        // print("\n--- DecideForKeys ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let subset = uc.decide(keys: [flagA, flagB])
        // for (fk, d) in subset {
        //     print("  \(fk): rule=\(d.ruleKey ?? "") var=\(d.variationKey ?? "") enabled=\(d.enabled)")
        // }

        // ----------------------------------------------------------
        // ENABLED FLAGS ONLY: Held-out flags should be excluded
        // ----------------------------------------------------------
        // print("\n--- EnabledFlagsOnly (holdout = enabled=false, should be excluded) ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let allDecisions = uc.decideAll()
        // let enabledOnly = uc.decideAll(options: [.enabledFlagsOnly])
        // print("  All flags: \(allDecisions.count) | EnabledFlagsOnly: \(enabledOnly.count)")
        // for (fk, d) in allDecisions {
        //     let inEnabled = enabledOnly[fk] != nil
        //     print("  \(fk)  enabled=\(d.enabled)  in_enabled_only=\(inEnabled)")
        // }

        // ----------------------------------------------------------
        // DISABLE DECISION EVENT: Holdout decision without impression
        // ----------------------------------------------------------
        // print("\n--- DisableDecisionEvent ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let d1 = uc.decide(key: flagA)                                           // fires impression
        // let d2 = uc.decide(key: flagA, options: [.disableDecisionEvent])          // no impression
        // print("  With event:    rule=\(d1.ruleKey ?? "") var=\(d1.variationKey ?? "")")
        // print("  Without event: rule=\(d2.ruleKey ?? "") var=\(d2.variationKey ?? "") (should be same decision, no impression sent)")

        // ----------------------------------------------------------
        // TRACK EVENT: Send conversion for a held-out user
        // ----------------------------------------------------------
        // print("\n--- Track after holdout ---")
        // let uc = optimizely.createUserContext(userId: "user_123")
        // let d = uc.decide(key: flagA)
        // printDecision(label: "Decision before track", decision: d)
        // do {
        //     try uc.trackEvent(eventKey: "my_event", eventTags: ["revenue": 100])
        //     print("  TrackEvent: success")
        // } catch {
        //     print("  TrackEvent error: \(error)")
        // }

        // ----------------------------------------------------------
        // DECISION LISTENER: See holdout metadata in notifications
        // ----------------------------------------------------------
        // print("\n--- Decision listener ---")
        // _ = optimizely.notificationCenter?.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
        //     if let data = try? JSONSerialization.data(withJSONObject: decisionInfo, options: []),
        //        let json = String(data: data, encoding: .utf8) {
        //         print("  LISTENER: user=\(userId) type=\(type) info=\(json)")
        //     }
        // }
        // let uc = optimizely.createUserContext(userId: "user_123")
        // _ = uc.decide(key: flagA)

        // ----------------------------------------------------------
        // DISTRIBUTION CHECK: Verify holdout traffic percentage
        // ----------------------------------------------------------
        // print("\n--- Distribution (1000 users) ---")
        // var counts: [String: Int] = [:]
        // for i in 1...1000 {
        //     let uid = "dist_\(i)"
        //     let uc = optimizely.createUserContext(userId: uid)
        //     let d = uc.decide(key: flagA)
        //     let key = isHoldout(d) ? "HOLDOUT:\(d.ruleKey ?? "")" : "\(d.ruleKey ?? "")/\(d.variationKey ?? "")"
        //     counts[key, default: 0] += 1
        // }
        // for (key, count) in counts.sorted(by: { $0.key < $1.key }) {
        //     print(String(format: "  %-35s %4d (%.1f%%)", key, count, Double(count) / 10.0))
        // }

        // ----------------------------------------------------------
        // WAIT FOR DATAFILE REFRESH: Keep SDK alive to test UI changes
        // ----------------------------------------------------------
        // Use this when testing UI mutations. Make a change in the UI,
        // then wait for the SDK to pick it up via polling.
        //
        // print("\n--- Waiting for datafile refresh (Ctrl+C to stop) ---")
        // print("Make a change in the UI, then watch for decision changes.")
        // let uid = "watch_user_42"
        // var lastRule: String? = nil
        // Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
        //     let uc = optimizely.createUserContext(userId: uid)
        //     let d = uc.decide(key: flagA)
        //     if d.ruleKey != lastRule {
        //         let formatter = DateFormatter()
        //         formatter.dateFormat = "HH:mm:ss"
        //         print("  [\(formatter.string(from: Date()))] CHANGED: rule=\(d.ruleKey ?? "") var=\(d.variationKey ?? "") enabled=\(d.enabled)")
        //         lastRule = d.ruleKey
        //     }
        // }
        // RunLoop.current.run()
    }

    // ============================================================
    // SCENARIO IDEAS -- Things to try during the bug bash
    // ============================================================
    //
    // These are NOT automated tests. They are ideas for manual exploration.
    // Use the code blocks above as building blocks, combine them, modify them.
    //
    // ---- UI MUTATION SCENARIOS ----
    // (Make changes in the Optimizely UI while the SDK is running)
    //
    // 1. DELETE A RUNNING HOLDOUT
    //    - Run the distribution check, note which users are held out
    //    - Delete the holdout in the UI, wait for datafile refresh
    //    - Re-run: previously held-out users should now get normal decisions
    //    - What if you delete a GLOBAL holdout? Do all flags recover?
    //
    // 2. CHANGE HOLDOUT TRAFFIC
    //    - Start with 50%, run distribution check
    //    - Change to 0% in UI --> everyone should get normal decisions
    //    - Change to 100% --> everyone should be held out
    //    - Change to 1% --> only ~1% held out
    //    - Does the SDK re-bucket correctly each time?
    //
    // 3. SWITCH LOCAL <-> GLOBAL
    //    - Start with a local holdout targeting rule_a only
    //    - Verify flag_b is NOT affected
    //    - Switch it to global in the UI
    //    - After refresh: flag_b should NOW be affected too
    //    - Switch back to local: flag_b should stop being affected
    //
    // 4. ADD/REMOVE AUDIENCE ON HOLDOUT
    //    - Holdout with audience: only users with customattr=yes get held out
    //    - Remove the audience: ALL users should now get held out
    //    - Add it back: only matching users get held out again
    //    - Try changing the attribute value in the audience condition
    //
    // 5. DELETE THE RULE A HOLDOUT TARGETS
    //    - Local holdout targets rule_a
    //    - Delete rule_a from the flag in the UI
    //    - Does the SDK crash? Panic? Or gracefully ignore the holdout?
    //
    // 6. PAUSE A HOLDOUT
    //    - Running holdout with 50% traffic
    //    - Pause it in the UI
    //    - After refresh: NO users should be held out
    //    - Re-activate: users should be held out again
    //
    // 7. ADD A HOLDOUT TO A RUNNING EXPERIMENT
    //    - Experiment running with no holdouts, users getting normal decisions
    //    - Create a new local holdout targeting that experiment
    //    - After refresh: some users should now be held out
    //
    // ---- FEATURE INTERACTION EDGE CASES ----
    //
    // 8. FORCED DECISION BEATS HOLDOUT
    //    - Find a user who IS held out (run distribution check)
    //    - setForcedDecision for that user --> should get forced variation, NOT holdout
    //    - removeForcedDecision --> holdout should return
    //    - Try both flag-level and rule-level forced decisions
    //
    // 9. DECIDE ALL WITH GLOBAL HOLDOUT
    //    - User hits global holdout
    //    - decideAll should show holdout on EVERY flag
    //    - decide(keys:) for a subset should match decideAll for those keys
    //
    // 10. ENABLED FLAGS ONLY + HOLDOUT
    //     - Holdout sets enabled=false
    //     - decideAll with .enabledFlagsOnly should EXCLUDE held-out flags
    //     - Verify the excluded flags are exactly the held-out ones
    //
    // 11. DECISION LISTENER METADATA
    //     - Register a decision notification listener
    //     - Make a decide call that hits a holdout
    //     - Check: does the listener fire? What's in decisionInfo?
    //     - Expected: experiment_id = holdout_id, rule_type = "holdout"
    //
    // 12. TRACK AFTER HOLDOUT
    //     - User is held out, then trackEvent is called
    //     - Does the conversion event fire? (it should)
    //     - Check the event payload for correct metadata
    //
    // 13. DISABLE DECISION EVENT + HOLDOUT
    //     - Decide with .disableDecisionEvent option
    //     - Decision result should be the same (holdout still applies)
    //     - But no impression event should be dispatched
    //
    // ---- STRESS & BOUNDARY SCENARIOS ----
    //
    // 14. MANY HOLDOUTS ON SAME RULE
    //     - Create 10+ local holdouts all targeting the same rule
    //     - Each with different traffic (5%, 10%, 15%, ...)
    //     - Are they evaluated in datafile order? First match wins?
    //     - Run distribution check -- does total holdout rate make sense?
    //
    // 15. LARGE PROJECT WITH HOLDOUTS
    //     - Use a project with 100+ flags
    //     - Add local holdouts targeting a few rules
    //     - Does decision performance degrade? Any timeouts?
    //
    // 16. HOLDOUT WITH 0% TRAFFIC
    //     - Create holdout with traffic set to 0%
    //     - Should NEVER hold out any user
    //     - Verify across 1000+ users
    //
    // 17. EMPTY INCLUDED RULES (includedRules: [])
    //     - This is a local holdout that targets NOTHING
    //     - Should NOT be treated as global
    //     - Should have NO effect on any flag
    //
    // 18. RAPID DATAFILE CHANGES
    //     - Use the "wait for datafile refresh" code block
    //     - Make 5 changes in rapid succession in the UI
    //     - Does the SDK eventually settle on the correct state?
    //     - Any race conditions or stale decisions?
    //
    // 19. CONCURRENT DECIDE CALLS
    //     - Spin up multiple DispatchQueue.concurrentPerform calls
    //     - Any crashes, data races, or inconsistent results?
    //
    // 20. HOLDOUT + SAME USER DIFFERENT ATTRIBUTES
    //     - Same user ID, first decide with no attributes
    //     - Then decide WITH attributes that match a holdout audience
    //     - Does the holdout correctly activate only with matching attributes?
    //
    // 21. VERY LONG USER IDS / SPECIAL CHARACTERS
    //     - User ID with 1000+ characters
    //     - User ID with unicode, emojis, spaces
    //     - Does bucketing still work? Any crashes?
    //
    // 22. MULTIPLE FLAGS, ONE GLOBAL HOLDOUT
    //     - 5+ flags, one global holdout at 10%
    //     - For a given user, if they're held out on flag_a, are they also
    //       held out on flag_b, flag_c, etc? (they should be -- same bucketing)
    //
    // 23. HOLDOUT ON A FLAG WITH NO RULES
    //     - Create a flag with no experiment rules
    //     - Create a holdout (global or local targeting a non-existent rule)
    //     - What does decide return? Should be default off without crash
    //
    // ============================================================

    // ============================================================
    // HELPERS -- Used by the code above, no need to modify
    // ============================================================

    static func isHoldout(_ d: OptimizelyDecision) -> Bool {
        return d.variationKey == "ho_off_key" && !d.enabled
    }

    static func printDecision(label: String, decision d: OptimizelyDecision) {
        print("\n  \(label):")
        print("    flag_key:      \(d.flagKey)")
        print("    rule_key:      \(d.ruleKey ?? "")")
        print("    variation_key: \(d.variationKey ?? "")")
        print("    enabled:       \(d.enabled)")
        let vars = d.variables.toMap()
        if !vars.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: vars, options: []),
           let json = String(data: data, encoding: .utf8) {
            print("    variables:     \(json)")
        }
        if !d.reasons.isEmpty {
            print("    reasons:")
            for r in d.reasons {
                print("      - \(r)")
            }
        }
    }

    static func inspectProject(_ client: OptimizelyClient) {
        print("\n============================================================")
        print("  Current Project State")
        print("============================================================")

        guard let optConfig = try? client.getOptimizelyConfig() else {
            print("  Could not get OptimizelyConfig")
            return
        }

        print("\n  Revision: \(optConfig.revision)")
        print("  Flags (\(optConfig.featuresMap.count)):")
        for (fk, feat) in optConfig.featuresMap {
            print("    \(fk):")
            for rule in feat.experimentRules {
                let vars = Array(rule.variationsMap.keys)
                print("      experiment: \(rule.key) (id=\(rule.id)) variations=\(vars)")
            }
            for rule in feat.deliveryRules {
                print("      delivery:   \(rule.key) (id=\(rule.id))")
            }
        }

        // Holdout details require internal config access. Use a quick decide
        // scan to infer which holdouts are active — a user hitting a holdout
        // will get ruleKey = holdout key, variationKey = "ho_off_key".
        print("\n  Holdout check (sampling 50 users on each flag):")
        for fk in optConfig.featuresMap.keys {
            var holdoutKeys = Set<String>()
            for i in 1...50 {
                let uc = client.createUserContext(userId: "inspect_\(i)")
                let d = uc.decide(key: fk)
                if isHoldout(d), let rk = d.ruleKey {
                    holdoutKeys.insert(rk)
                }
            }
            if !holdoutKeys.isEmpty {
                print("    \(fk): holdouts seen = \(holdoutKeys.sorted())")
            } else {
                print("    \(fk): no holdouts hit in sample")
            }
        }
        print()
    }

    // ============================================================
    // CLIENT CREATION
    // ============================================================

    static func createLiveClient(sdkKey: String) -> OptimizelyClient {
        let optimizely = OptimizelyClient(sdkKey: sdkKey,
                                          periodicDownloadInterval: 30,
                                          defaultLogLevel: .debug)

        let semaphore = DispatchSemaphore(value: 0)
        print("Waiting for datafile...")
        optimizely.start(resourceTimeout: 10) { result in
            switch result {
            case .success:
                print("Client ready.")
            case .failure(let error):
                print("Error starting client: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()

        return optimizely
    }
}
