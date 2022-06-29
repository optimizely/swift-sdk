//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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
import Optimizely
import UIKit

class SamplesForAPI {
    
    static func checkAPIs(optimizely: OptimizelyClient) {

        let attributes: [String: Any] = [
            "device": "iPhone",
            "lifetime": 24738388,
            "is_logged_in": true
            ]
        let tags: [String: Any] = [
            "category": "shoes",
            "count": 2
            ]

        // MARK: - activate

        do {
            let variationKey = try optimizely.activate(experimentKey: "my_experiment_key",
                                                       userId: "user_123",
                                                       attributes: attributes)
            print("[activate] \(variationKey)")
        } catch {
            print(error)
        }

        // MARK: - getVariationKey

        do {
            let variationKey = try optimizely.getVariationKey(experimentKey: "my_experiment_key",
                                                              userId: "user_123",
                                                              attributes: attributes)
            print("[getVariationKey] \(variationKey)")
        } catch {
            print(error)
        }

        // MARK: - getForcedVariation

        if let variationKey = optimizely.getForcedVariation(experimentKey: "my_experiment_key", userId: "user_123") {
            print("[getForcedVariation] \(variationKey)")
        }

        // MARK: - setForcedVariation

        if optimizely.setForcedVariation(experimentKey: "my_experiment_key",
                                         userId: "user_123",
                                         variationKey: "some_variation_key") {
            print("[setForcedVariation]")
        }

        // MARK: - isFeatureEnabled

        let enabled = optimizely.isFeatureEnabled(featureKey: "my_feature_key",
                                                          userId: "user_123",
                                                          attributes: attributes)
        print("[isFeatureEnabled] \(enabled)")

        // MARK: - getFeatureVariable

        do {
            let featureVariableValue = try optimizely.getFeatureVariableDouble(featureKey: "my_feature_key",
                                                                               variableKey: "double_variable_key",
                                                                               userId: "user_123",
                                                                               attributes: attributes)
            print("[getFeatureVariableDouble] \(featureVariableValue)")
        } catch {
            print(error)
        }

        // MARK: - getEnabledFeatures

        let enabledFeatures = optimizely.getEnabledFeatures(userId: "user_123", attributes: attributes)
        print("[getEnabledFeatures] \(enabledFeatures)")

        // MARK: - track

        do {
            try optimizely.track(eventKey: "my_purchase_event_key", userId: "user_123", attributes: attributes, eventTags: tags)
            print("[track]")
        } catch {
            print(error)
        }
        
    }
    
    // MARK: - OptimizelyUserContext (Decide API)
    
    static func checkOptimizelyUserContext(optimizely: OptimizelyClient) {
        let attributes: [String: Any] = [
            "location": "NY",
            "device": "iPhone",
            "lifetime": 24738388,
            "is_logged_in": true
            ]
        let tags: [String: Any] = [
            "category": "shoes",
            "count": 2
            ]

        let user = optimizely.createUserContext(userId: "user_123", attributes: attributes)
        
        var decision = user.decide(key: "show_coupon", options: [.includeReasons])
        
        if let variationKey = decision.variationKey {
            print("[decide] flag decision to variation: \(variationKey)")
            print("[decide] flag enabled: \(decision.enabled) with variables: \(decision.variables.toMap())")
            print("[decide] reasons: \(decision.reasons)")
        } else {
            print("[decide] error: \(decision.reasons)")
        }
        
        do {
            try user.trackEvent(eventKey: "my_purchase_event_key", eventTags: tags)
            print("[track] success")
        } catch {
            print("[track] error: \(error)")
        }
        
        // Forced Decisions
        
        let context1 = OptimizelyDecisionContext(flagKey: "flag-1")
        let context2 = OptimizelyDecisionContext(flagKey: "flag-1", ruleKey: "ab-test-1")
        let context3 = OptimizelyDecisionContext(flagKey: "flag-1", ruleKey: "delivery-1")
        let forced1 = OptimizelyForcedDecision(variationKey: "variation-a")
        let forced2 = OptimizelyForcedDecision(variationKey: "variation-b")
        let forced3 = OptimizelyForcedDecision(variationKey: "on")
        
        // (1) set a forced decision for a flag

        _ = user.setForcedDecision(context: context1, decision: forced1)
        decision = user.decide(key: "flag-1")

        // (2) set a forced decision for an ab-test rule

        _ = user.setForcedDecision(context: context2, decision: forced2)
        decision = user.decide(key: "flag-1")

        // (3) set a forced variation for a delivery rule

        _ = user.setForcedDecision(context: context3,
                                         decision: forced3)
        decision = user.decide(key: "flag-1")

        // (4) get forced variations

        let forcedDecision = user.getForcedDecision(context: context1)
        print("[ForcedDecision] variationKey = \(forcedDecision!.variationKey)")

        // (5) remove forced variations

        _ = user.removeForcedDecision(context: context2)
        _ = user.removeAllForcedDecisions()
    }
    
    // MARK: - OptimizelyConfig
    
    static func checkOptimizelyConfig(optimizely: OptimizelyClient) {
        let optConfig = try! optimizely.getOptimizelyConfig()
        
        print("[OptimizelyConfig] revision = \(optConfig.revision)")
        print("[OptimizelyConfig] sdkKey = \(optConfig.sdkKey)")
        print("[OptimizelyConfig] environmentKey = \(optConfig.environmentKey)")

        print("[OptimizelyConfig] attributes:")
        optConfig.attributes.forEach { attribute in
            print("[OptimizelyConfig]   -- (id, key) = (\(attribute.id), \(attribute.key))")
        }
        print("[OptimizelyConfig] audiences:")
        optConfig.audiences.forEach { audience in
            print("[OptimizelyConfig]   -- (id, name, conditions) = (\(audience.id), \(audience.name), \(audience.conditions))")
        }
        print("[OptimizelyConfig] events:")
        optConfig.events.forEach { event in
            print("[OptimizelyConfig]   -- (id, key, experimentIds) = (\(event.id), \(event.key), \(event.experimentIds))")
        }

        //let features = optConfig.featureFlagsMap.values
        let featureKeys = optConfig.featuresMap.keys
        print("[OptimizelyConfig] all feature keys = \(featureKeys)")

        // enumerate all features (experiments, variations, and assocated variables)
        
        featureKeys.forEach { featKey in
            print("[OptimizelyConfig] featureKey = \(featKey)")
            
            // enumerate feature experiments

            let feature = optConfig.featuresMap[featKey]!
            
            let experimentRules = feature.experimentRules
            let deliveryRules = feature.deliveryRules
            
            experimentRules.forEach { experiment in
                print("[OptimizelyConfig]   - experiment rule-key = \(experiment.key)")
                print("[OptimizelyConfig]   - experiment audiences = \(experiment.audiences)")

                let variationsMap = experiment.variationsMap
                let variationKeys = variationsMap.keys
                
                variationKeys.forEach { varKey in
                    let variation = variationsMap[varKey]!
                    print("[OptimizelyConfig]       -- variation = { key: \(varKey), id: \(variation.id), featureEnabled: \(String(describing: variation.featureEnabled))")
                    
                    let variablesMap = variationsMap[varKey]!.variablesMap
                    let variableKeys = variablesMap.keys
                    
                    variableKeys.forEach { variableKey in
                        let variable = variablesMap[variableKey]!
                        
                        print("[OptimizelyConfig]           --- variable: \(variableKey), \(variable)")
                    }
                }
            }
            
            deliveryRules.forEach { delivery in
                print("[OptimizelyConfig]   - delivery rule-key = \(delivery.key)")
                print("[OptimizelyConfig]   - delivery audiences = \(delivery.audiences)")

                // use delivery rule data here...
            }
            
            // enumerate all feature-variables

            let variablesMap = optConfig.featuresMap[featKey]!.variablesMap
            let variableKeys = variablesMap.keys
            
            variableKeys.forEach { variableKey in
                let variable = variablesMap[variableKey]!

                print("[OptimizelyConfig]   - (feature)variable: \(variableKey), \(variable)")
            }
        }
        
        // listen to NotificationType.datafileChange to get updated data

        _ = optimizely.notificationCenter?.addDatafileChangeNotificationListener { (_) in
            if let newOptConfig = try? optimizely.getOptimizelyConfig() {
                print("[OptimizelyConfig] revision = \(newOptConfig.revision)")
            }
        }

    }
    
    // MARK: - AudienceSegments
    
    static func checkAudienceSegments(optimizely: OptimizelyClient) {
        // override the default handler if cache size and timeout need to be customized
        let optimizely = OptimizelyClient(sdkKey: "FCnSegiEkRry9rhVMroit4",
                                          periodicDownloadInterval: 60,
                                          odpConfig: OptimizelyODPConfig(segmentsCacheSize: 12,
                                                                         segmentsCacheTimeoutInSecs: 123,
                                                                         apiKey: "sample-api-key"))
        optimizely.start { result in
            if case .failure(let error) = result {
                print("[AudienceSegments] SDK initialization failed: \(error)")
                return
            }
            
            let user = optimizely.createUserContext(userId: "user_123", attributes: ["location": "NY"])
            user.fetchQualifiedSegments(options: [.ignoreCache]) { _, error in
                guard error == nil else {
                    print("[AudienceSegments] \(error!.errorDescription!)")
                    return
                }
            
                let decision = user.decide(key: "show_coupon", options: [.includeReasons])
                print("[AudienceSegments] decision: \(decision)")
            }
        }
    }
    
    // MARK: - Initializations

    static func samplesForInitialization() {
        
        // These are sample codes for synchronous and asynchronous SDK initializations with multiple options

        guard let localDatafileUrl = Bundle.main.url(forResource: "demoTestDatafile", withExtension: "json"),
            let localDatafile = try? Data(contentsOf: localDatafileUrl)
        else {
            fatalError("Local datafile cannot be found")
        }

        var optimizely: OptimizelyClient
        var variationKey: String?
        
        // [Synchronous]
        
        // [S1] Synchronous initialization
        //      1. SDK is initialized instantly with a cached (or bundled) datafile
        //      2. A new datafile can be downloaded in background and cached after the SDK is initialized.
        //         The cached datafile will be used only when the SDK re-starts in the next session.
        optimizely = OptimizelyClient(sdkKey: "<Your_SDK_Key>")
        try? optimizely.start(datafile: localDatafile)
        variationKey = try? optimizely.activate(experimentKey: "<Experiment_Key", userId: "<User_ID>")
        
        // [S2] Synchronous initialization
        //      1. SDK is initialized instantly with a cached (or bundled) datafile
        //      2. A new datafile can be downloaded in background and cached after the SDK is initialized.
        //         The cached datafile is used immediately to update the SDK project config.
        optimizely = OptimizelyClient(sdkKey: "<Your_SDK_Key>")
        try? optimizely.start(datafile: localDatafile,
                              doUpdateConfigOnNewDatafile: true)
        variationKey = try? optimizely.activate(experimentKey: "<Experiment_Key", userId: "<User_ID>")
        
        // [S3] Synchronous initialization
        //      1. SDK is initialized instantly with a cached (or bundled) datafile
        //      2. A new datafile can be downloaded in background and cached after the SDK is initialized.
        //         The cached datafile is used immediately to update the SDK project config.
        //      3. Polling datafile periodically.
        //         The cached datafile is used immediately to update the SDK project config.
        optimizely = OptimizelyClient(sdkKey: "<Your_SDK_Key>",
                                      periodicDownloadInterval: 60)
        try? optimizely.start(datafile: localDatafile)
        variationKey = try? optimizely.activate(experimentKey: "<Experiment_Key", userId: "<User_ID>")
        
        // [Asynchronous]
        
        // [A1] Asynchronous initialization
        //      1. A datafile is downloaded from the server and the SDK is initialized with the datafile
        optimizely = OptimizelyClient(sdkKey: "<Your_SDK_Key>")
        optimizely.start { result in
            variationKey = try? optimizely.activate(experimentKey: "<Experiment_Key", userId: "<User_ID>")
        }
        
        // [A2] Asynchronous initialization
        //      1. A datafile is downloaded from the server and the SDK is initialized with the datafile
        //      2. Polling datafile periodically.
        //         The cached datafile is used immediately to update the SDK project config.
        optimizely = OptimizelyClient(sdkKey: "<Your_SDK_Key>",
                                      periodicDownloadInterval: 60)
        optimizely.start { result in
            variationKey = try? optimizely.activate(experimentKey: "<Experiment_Key", userId: "<User_ID>")
        }
        
        print("activated variation: \(String(describing: variationKey))")
    }

}
