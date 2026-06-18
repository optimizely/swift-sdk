/*
 Local Holdouts Bug Bash -- Swift SDK (Xcode version)

 See examples/local_holdouts/README.md for full setup instructions,
 how local holdouts work, and the list of 27 scenarios to try.

 HOW TO RUN:
   1. Open OptimizelySwiftSDK.xcworkspace in Xcode
   2. Set scheme to "DemoSwiftiOS"
   3. Set your SDK key below
   4. Build & Run (Cmd+R) -- check Xcode console, ignore the emulator
   5. Uncomment test cases below one by one, re-build & run
*/

import UIKit
import Optimizely

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ============================================================
    // CONFIGURATION -- Update these for your environment
    // ============================================================

    let sdkKey = "YOUR_SDK_KEY_HERE"

    // Flags and rules -- must match your project setup
    let FLAG1 = "flag1"
    let FLAG2 = "flag2"

    // Audience attribute
    let ATTR_KEY   = "country"
    let ATTR_MATCH = "us"

    var window: UIWindow?
    var optimizely: OptimizelyClient!

    func applicationDidFinishLaunching(_ application: UIApplication) {
        runBugBash()
    }

    // ============================================================
    // BUG BASH -- Modify the code below to explore holdouts
    // ============================================================
    //
    // This is your sandbox. The SDK client is created with polling enabled
    // (refreshes datafile every 30 seconds). Make changes in the Optimizely
    // UI, wait ~30s, then re-run to see the updated behavior.
    //
    // Uncomment sections below to try different things. Modify freely.

    func runBugBash() {

        guard sdkKey != "YOUR_SDK_KEY_HERE" else {
            print("ERROR: Set your SDK key in the sdkKey constant at the top of AppDelegate.swift")
            return
        }

        // Initialize the SDK with polling (30s refresh) and immediate event dispatch
        let eventDispatcher = DefaultEventDispatcher(timerInterval: 0)
        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      eventDispatcher: eventDispatcher,
                                      periodicDownloadInterval: 30,
                                      defaultLogLevel: .debug)

        optimizely.start { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initialization failed: \(error)")
                return
            case .success:
                print("Optimizely SDK initialized successfully!")
            @unknown default:
                print("Optimizely SDK initialization failed with unknown result")
                return
            }

            // Build rule key lookup for isHoldout() helper
            self.buildKnownRuleKeys()

            // Show current project state (flags, rules, holdouts)
            self.inspectProject()

            // ----------------------------------------------------------
            // BASIC: Decide on a flag and see what happens
            // ----------------------------------------------------------
            print("\n--- Basic decide ---")
            let user = self.optimizely.createUserContext(userId: "user_123")
            let d = user.decide(key: self.FLAG1, options: [.includeReasons])
            self.printDecision(label: "user_123 on \(self.FLAG1)", decision: d)

            // ----------------------------------------------------------
            // TRY DIFFERENT USERS: Some will be held out, some won't
            // ----------------------------------------------------------
            print("\n--- Try multiple users ---")
            for i in 1...20 {
                let uid = "user_\(i)"
                let uc = self.optimizely.createUserContext(userId: uid)
                let d = uc.decide(key: self.FLAG1)
                let tag = self.isHoldout(d) ? "HOLDOUT:\(d.ruleKey ?? "")" : "normal"
                print("  \(uid.padding(toLength: 15, withPad: " ", startingAt: 0))\(tag.padding(toLength: 30, withPad: " ", startingAt: 0))var=\(d.variationKey ?? "nil")  enabled=\(d.enabled)")
            }

            // ----------------------------------------------------------
            // DECIDE WITH ATTRIBUTES: Test audience-targeted holdouts
            // ----------------------------------------------------------
            // print("\n--- With audience attributes ---")
            // let userWithAttr = self.optimizely.createUserContext(userId: "user_123",
            //                                                      attributes: [self.ATTR_KEY: self.ATTR_MATCH])
            // let d2 = userWithAttr.decide(key: self.FLAG1, options: [.includeReasons])
            // self.printDecision(label: "user_123 with country=us", decision: d2)
            //
            // // Same user WITHOUT the attribute -- should NOT hit audience holdout
            // let userNoAttr = self.optimizely.createUserContext(userId: "user_123")
            // let d3 = userNoAttr.decide(key: self.FLAG1)
            // self.printDecision(label: "user_123 without attribute", decision: d3)

            // ----------------------------------------------------------
            // FORCED DECISIONS: Override holdout at flag level
            // ----------------------------------------------------------
            // print("\n--- Forced decision (flag level) ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            //
            // // Normal decision first
            // let before = uc.decide(key: self.FLAG1)
            // self.printDecision(label: "Before forced decision", decision: before)
            //
            // // Force variation to "on" -- should bypass holdout
            // let ctx = OptimizelyDecisionContext(flagKey: self.FLAG1)
            // let fd = OptimizelyForcedDecision(variationKey: "on")
            // _ = uc.setForcedDecision(context: ctx, decision: fd)
            //
            // let forced = uc.decide(key: self.FLAG1)
            // self.printDecision(label: "With forced decision", decision: forced)
            //
            // // Remove forced decision -- holdout should return
            // _ = uc.removeForcedDecision(context: ctx)
            // let after = uc.decide(key: self.FLAG1)
            // self.printDecision(label: "After removing forced decision", decision: after)

            // ----------------------------------------------------------
            // FORCED DECISIONS: Override at rule level (more specific)
            // ----------------------------------------------------------
            // print("\n--- Forced decision (rule level) ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // let ruleCtx = OptimizelyDecisionContext(flagKey: self.FLAG1, ruleKey: "ab1")
            // let ruleFD = OptimizelyForcedDecision(variationKey: "on")
            // _ = uc.setForcedDecision(context: ruleCtx, decision: ruleFD)
            // let d = uc.decide(key: self.FLAG1)
            // self.printDecision(label: "Rule-level forced decision", decision: d)
            // _ = uc.removeAllForcedDecisions()

            // ----------------------------------------------------------
            // DECIDE ALL: See holdouts across all flags at once
            // ----------------------------------------------------------
            // print("\n--- DecideAll ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // let all = uc.decideAll()
            // for (fk, d) in all {
            //     let tag = self.isHoldout(d) ? " [HOLDOUT]" : ""
            //     print("  \(fk.padding(toLength: 15, withPad: " ", startingAt: 0))rule=\((d.ruleKey ?? "").padding(toLength: 20, withPad: " ", startingAt: 0))var=\(d.variationKey ?? "nil")  enabled=\(d.enabled)\(tag)")
            // }

            // ----------------------------------------------------------
            // DECIDE FOR KEYS: Check subset of flags
            // ----------------------------------------------------------
            // print("\n--- DecideForKeys ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // let subset = uc.decide(keys: [self.FLAG1, self.FLAG2])
            // for (fk, d) in subset {
            //     print("  \(fk): rule=\(d.ruleKey ?? "") var=\(d.variationKey ?? "") enabled=\(d.enabled)")
            // }

            // ----------------------------------------------------------
            // ENABLED FLAGS ONLY: Held-out flags should be excluded
            // ----------------------------------------------------------
            // print("\n--- EnabledFlagsOnly (holdout = enabled=false, should be excluded) ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
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
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // let d1 = uc.decide(key: self.FLAG1)                                           // fires impression
            // let d2 = uc.decide(key: self.FLAG1, options: [.disableDecisionEvent])          // no impression
            // print("  With event:    rule=\(d1.ruleKey ?? "") var=\(d1.variationKey ?? "")")
            // print("  Without event: rule=\(d2.ruleKey ?? "") var=\(d2.variationKey ?? "") (should be same decision, no impression sent)")

            // ----------------------------------------------------------
            // TRACK EVENT: Send conversion for a held-out user
            // ----------------------------------------------------------
            // print("\n--- Track after holdout ---")
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // let d = uc.decide(key: self.FLAG1)
            // self.printDecision(label: "Decision before track", decision: d)
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
            // _ = self.optimizely.notificationCenter?.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            //     if let data = try? JSONSerialization.data(withJSONObject: decisionInfo, options: []),
            //        let json = String(data: data, encoding: .utf8) {
            //         print("  LISTENER: user=\(userId) type=\(type) info=\(json)")
            //     }
            // }
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // _ = uc.decide(key: self.FLAG1)

            // ----------------------------------------------------------
            // TRACK LISTENER: Verify conversion events for held-out users
            // ----------------------------------------------------------
            // print("\n--- Track listener ---")
            // _ = self.optimizely.notificationCenter?.addTrackNotificationListener { (eventKey, userId, attributes, eventTags, event) in
            //     print("  TRACK: event=\(eventKey) user=\(userId)")
            // }
            // let uc = self.optimizely.createUserContext(userId: "user_123")
            // _ = uc.decide(key: self.FLAG1)
            // try? uc.trackEvent(eventKey: "my_event")

            // ----------------------------------------------------------
            // DISTRIBUTION CHECK: Verify holdout traffic percentage
            // ----------------------------------------------------------
            // print("\n--- Distribution (1000 users) ---")
            // var counts: [String: Int] = [:]
            // for i in 1...1000 {
            //     let uid = "dist_\(i)"
            //     let uc = self.optimizely.createUserContext(userId: uid)
            //     let d = uc.decide(key: self.FLAG1)
            //     let key = self.isHoldout(d) ? "HOLDOUT:\(d.ruleKey ?? "")" : "\(d.ruleKey ?? "")/\(d.variationKey ?? "")"
            //     counts[key, default: 0] += 1
            // }
            // for (key, count) in counts.sorted(by: { $0.key < $1.key }) {
            //     print("  \(key.padding(toLength: 35, withPad: " ", startingAt: 0))\(String(count).padding(toLength: 5, withPad: " ", startingAt: 0))(\(String(format: "%.1f", Double(count) / 10.0))%)")
            // }

            // ----------------------------------------------------------
            // WAIT FOR DATAFILE REFRESH: Keep SDK alive to test UI changes
            // ----------------------------------------------------------
            // Use this when testing UI mutations. Make a change in the UI,
            // then wait for the SDK to pick it up via polling.
            //
            // print("\n--- Waiting for datafile refresh (stop the app to quit) ---")
            // print("Make a change in the UI, then watch for decision changes.")
            // let uid = "watch_user_42"
            // var lastRule: String? = nil
            // Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            //     let uc = self.optimizely.createUserContext(userId: uid)
            //     let d = uc.decide(key: self.FLAG1)
            //     if d.ruleKey != lastRule {
            //         let formatter = DateFormatter()
            //         formatter.dateFormat = "HH:mm:ss"
            //         print("  [\(formatter.string(from: Date()))] CHANGED: rule=\(d.ruleKey ?? "") var=\(d.variationKey ?? "") enabled=\(d.enabled)")
            //         lastRule = d.ruleKey
            //     }
            // }
            // RunLoop.current.run()

            // ----------------------------------------------------------
            // CONCURRENT DECIDE CALLS: Test thread safety
            // ----------------------------------------------------------
            // print("\n--- Concurrent decide calls ---")
            // DispatchQueue.concurrentPerform(iterations: 50) { i in
            //     let uid = "concurrent_\(i)"
            //     let uc = self.optimizely.createUserContext(userId: uid)
            //     let d = uc.decide(key: self.FLAG1)
            //     let tag = self.isHoldout(d) ? "HOLDOUT" : "normal"
            //     print("  \(uid): \(tag) var=\(d.variationKey ?? "nil")")
            // }
            // print("  Concurrent test complete -- no crashes = good")
        }
    }

    // ============================================================
    // SCENARIO IDEAS: see examples/local_holdouts/README.md
    //
    // LOG BUGS HERE:
    // https://episerver99-my.sharepoint.com/:x:/g/personal/matjaz_pirnovar_optimizely_com/IQCkcX_sg-ZeS7uNrKPc6wf8AVKqgPsQJrSjciNNJy035KM?e=E1XPcA
    // ============================================================

    // ============================================================
    // HELPERS -- Used by the code above, no need to modify
    // ============================================================

    var knownRuleKeys: Set<String> = []

    func buildKnownRuleKeys() {
        guard let config = try? optimizely.getOptimizelyConfig() else { return }
        for (_, feat) in config.featuresMap {
            for rule in feat.experimentRules { knownRuleKeys.insert(rule.key) }
            for rule in feat.deliveryRules  { knownRuleKeys.insert(rule.key) }
        }
    }

    func isHoldout(_ d: OptimizelyDecision) -> Bool {
        guard !d.enabled, let rk = d.ruleKey else { return false }
        return !knownRuleKeys.contains(rk)
    }

    func printDecision(label: String, decision d: OptimizelyDecision) {
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

    func inspectProject() {
        print("\n============================================================")
        print("  Current Project State")
        print("============================================================")

        guard let optConfig = try? optimizely.getOptimizelyConfig() else {
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

        // Holdout details: sample users to see which holdouts are active
        print("\n  Holdout check (sampling 50 users on each flag):")
        for fk in optConfig.featuresMap.keys.sorted() {
            var holdoutKeys = Set<String>()
            for i in 1...50 {
                let uc = optimizely.createUserContext(userId: "inspect_\(i)")
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

    // MARK: - AppDelegate (required)

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}
}
