//
// Copyright 2019-2021, 2023 Optimizely, Inc. and contributors
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

import XCTest

class BatchEventBuilderTests_Events: XCTestCase {
    
    let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
    let userId = "test_user_1"
    let featureKey = "feature_1"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher: MockEventDispatcher!
    var project: Project!
    let datafile = OTUtils.loadJSONDatafile("api_datafile")!
    
    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_4444444",
            "key": "holdout_key",
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": "holdout_variation_a11", "endOfRange": 10000] // 100% traffic allocation
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_variation_a11",
                    "key": "holdout_a"
                ]
            ]
        ]
    }
    
    override func setUp() {
        eventDispatcher = MockEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)!
        project = optimizely.config!.project!
    }
    
    override func tearDown() {
        Utils.sdkVersion = OPTIMIZELYSDKVERSION
        Utils.swiftSdkClientName = "swift-sdk"
        optimizely?.close()
        optimizely = nil
        optimizely?.eventDispatcher = nil
        super.tearDown()
    }
    
    func testCreateImpressionEvent() {
        let expVariationId = "10416523162"
        let expCampaignId = "10420273929"
        let expExperimentId = "10390977714"
        
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        
        let event = getFirstEventJSON(dispatcher: eventDispatcher)!
        
        XCTAssertEqual((event["revision"] as! String), project.revision)
        XCTAssertEqual((event["account_id"] as! String), project.accountId)
        XCTAssertEqual(event["client_version"] as! String, Utils.sdkVersion)
        XCTAssertEqual(event["project_id"] as! String, project.projectId)
        XCTAssertEqual(event["client_name"] as! String, "swift-sdk")
        XCTAssertEqual(event["anonymize_ip"] as! Bool, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"] as! Bool, true)
        
        let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(visitor["visitor_id"] as! String, userId)
        
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"] as! Array<Dictionary<String, Any>>
        XCTAssertEqual(eventAttributes.count, attributes.count)
        
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(decision["variation_id"] as! String, expVariationId)
        XCTAssertEqual(decision["campaign_id"] as! String, expCampaignId)
        XCTAssertEqual(decision["experiment_id"] as! String, expExperimentId)
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.experiment.rawValue)
        XCTAssertEqual(metaData["rule_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["flag_key"] as! String, "")
        XCTAssertEqual(metaData["variation_key"] as! String, "all_traffic_variation")
        XCTAssertTrue(metaData["enabled"] as! Bool)
        
        let de = (snapshot["events"]  as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(de["entity_id"] as! String, expCampaignId)
        XCTAssertEqual(de["key"] as! String, "campaign_activated")
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"] as! Int64)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert((de["uuid"] as! String).count > 20)
        // event tags are tested separately below
        XCTAssert((de["tags"] as! Dictionary<String, Any>).count==0)
        XCTAssertNil(de["revenue"])
        XCTAssertNil(de["value"])
    }
    
    func testCreateImpressionEventCustomClientNameAndVersion() {
        // Needed custom instances to avoid breaking original tests
        let eventDispatcher = MockEventDispatcher()
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher,
                                                  settings: OptimizelySdkSettings(sdkName: "flutter-sdk", sdkVersion: "1234"))!
        
        let expVariationId = "10416523162"
        let expCampaignId = "10420273929"
        let expExperimentId = "10390977714"
        
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        
        // Skipped getFirstEventJSON as it uses the class level optimizely instance
        optimizely.eventLock.sync{}
        let rawEvent: EventForDispatch = eventDispatcher.events.first!
        let event = try! JSONSerialization.jsonObject(with: rawEvent.body, options: .allowFragments) as! [String: Any]
        
        XCTAssertEqual((event["revision"] as! String), project.revision)
        XCTAssertEqual((event["account_id"] as! String), project.accountId)
        XCTAssertEqual(event["client_version"] as! String, "1234")
        XCTAssertEqual(event["project_id"] as! String, project.projectId)
        XCTAssertEqual(event["client_name"] as! String, "flutter-sdk")
        XCTAssertEqual(event["anonymize_ip"] as! Bool, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"] as! Bool, true)
        
        let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(visitor["visitor_id"] as! String, userId)
        
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"] as! Array<Dictionary<String, Any>>
        XCTAssertEqual(eventAttributes.count, attributes.count)
        
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(decision["variation_id"] as! String, expVariationId)
        XCTAssertEqual(decision["campaign_id"] as! String, expCampaignId)
        XCTAssertEqual(decision["experiment_id"] as! String, expExperimentId)
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.experiment.rawValue)
        XCTAssertEqual(metaData["rule_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["flag_key"] as! String, "")
        XCTAssertEqual(metaData["variation_key"] as! String, "all_traffic_variation")
        XCTAssertTrue(metaData["enabled"] as! Bool)
        
        let de = (snapshot["events"]  as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(de["entity_id"] as! String, expCampaignId)
        XCTAssertEqual(de["key"] as! String, "campaign_activated")
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"] as! Int64)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert((de["uuid"] as! String).count > 20)
        // event tags are tested separately below
        XCTAssert((de["tags"] as! Dictionary<String, Any>).count==0)
        XCTAssertNil(de["revenue"])
        XCTAssertNil(de["value"])
    }
    
    func testCreateImpressionEventWithoutVariation() {
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        
        optimizely.config?.project.sendFlagDecisions = true
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: experiment!, variation: nil, userId: userId, attributes: attributes, flagKey: experiment!.key, ruleType: Constants.DecisionSource.featureTest.rawValue, enabled: false)
        XCTAssertNotNil(event)
        
        let visitor = (getEventJSON(data: event!)!["visitors"] as! Array<Dictionary<String, Any>>)[0]
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, "feature-test")
        XCTAssertEqual(metaData["rule_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["flag_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["variation_key"] as! String, "")
        XCTAssertFalse(metaData["enabled"] as! Bool)
        optimizely.config?.project.sendFlagDecisions = nil
    }
    
    func testCreateImpressionEventWithoutExperimentAndVariation() {
        
        optimizely.config?.project.sendFlagDecisions = true
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: nil, variation: nil, userId: userId, attributes: [String: Any](), flagKey: "feature_1", ruleType: Constants.DecisionSource.rollout.rawValue, enabled: true)
        XCTAssertNotNil(event)
        
        let visitor = (getEventJSON(data: event!)!["visitors"] as! Array<Dictionary<String, Any>>)[0]
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, "rollout")
        XCTAssertEqual(metaData["rule_key"] as! String, "")
        XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
        XCTAssertEqual(metaData["variation_key"] as! String, "")
        XCTAssertTrue(metaData["enabled"] as! Bool)
        optimizely.config?.project.sendFlagDecisions = nil
    }
    
    func testCreateConversionEvent() {
        let eventKey = "event_single_targeted_exp"
        let eventId = "10404198135"
        
        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        let event = getFirstEventJSON(dispatcher: eventDispatcher)!
        
        XCTAssertEqual(event["revision"] as! String, project.revision)
        XCTAssertEqual(event["account_id"] as! String, project.accountId)
        XCTAssertEqual(event["client_version"] as! String, Utils.sdkVersion)
        XCTAssertEqual(event["project_id"] as! String, project.projectId)
        XCTAssertEqual(event["client_name"] as! String, "swift-sdk")
        XCTAssertEqual(event["anonymize_ip"] as! Bool, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"] as! Bool, true)
        
        let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(visitor["visitor_id"] as! String, userId)
        
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"] as! Array<Dictionary<String, Any>>
        XCTAssertEqual(eventAttributes[0]["key"] as! String, "s_foo")
        XCTAssertEqual(eventAttributes[0]["value"] as! String, "bar")
        
        let decisions = snapshot["decisions"]
        
        XCTAssertNil(decisions)
        
        let de = (snapshot["events"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(de["entity_id"] as! String, eventId)
        XCTAssertEqual(de["key"] as! String, eventKey)
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"] as! Int64)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert((de["uuid"] as!String).count > 20)
        // {tags, revenue, value} are tested separately below
        XCTAssertEqual((de["tags"] as! Dictionary<String, Any>)["browser"] as! String, "chrome")
        XCTAssertNil(de["revenue"])
        XCTAssertNil(de["value"])
    }
    
    func testCreateConversionEventCustomClientNameAndVersion() {
        // Needed custom instances to avoid breaking original tests
        let eventDispatcher = MockEventDispatcher()
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher,
                                                  settings: OptimizelySdkSettings(sdkName: "flutter-sdk", sdkVersion: "1234"))!

        let eventKey = "event_single_targeted_exp"
        let eventId = "10404198135"
        
        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        // Skipped getFirstEventJSON as it uses the class level optimizely instance
        optimizely.eventLock.sync{}
        let rawEvent: EventForDispatch = eventDispatcher.events.first!
        let event = try! JSONSerialization.jsonObject(with: rawEvent.body, options: .allowFragments) as! [String: Any]
                
        XCTAssertEqual(event["revision"] as! String, project.revision)
        XCTAssertEqual(event["account_id"] as! String, project.accountId)
        XCTAssertEqual(event["client_version"] as! String, "1234")
        XCTAssertEqual(event["project_id"] as! String, project.projectId)
        XCTAssertEqual(event["client_name"] as! String, "flutter-sdk")
        XCTAssertEqual(event["anonymize_ip"] as! Bool, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"] as! Bool, true)
        
        let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(visitor["visitor_id"] as! String, userId)
        
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"] as! Array<Dictionary<String, Any>>
        XCTAssertEqual(eventAttributes[0]["key"] as! String, "s_foo")
        XCTAssertEqual(eventAttributes[0]["value"] as! String, "bar")
        
        let decisions = snapshot["decisions"]
        
        XCTAssertNil(decisions)
        
        let de = (snapshot["events"] as! Array<Dictionary<String, Any>>)[0]
        
        XCTAssertEqual(de["entity_id"] as! String, eventId)
        XCTAssertEqual(de["key"] as! String, eventKey)
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"] as! Int64)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert((de["uuid"] as!String).count > 20)
        // {tags, revenue, value} are tested separately below
        XCTAssertEqual((de["tags"] as! Dictionary<String, Any>)["browser"] as! String, "chrome")
        XCTAssertNil(de["revenue"])
        XCTAssertNil(de["value"])
    }
    
    func testCreateConversionEventWhenEventKeyInvalid() {
        let eventKey = "not-existing-key"
        
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        do {
            try optimizely.track(eventKey: eventKey,
                                 userId: userId,
                                 attributes: nil,
                                 eventTags: eventTags)
            XCTAssert(false, "event should not be created for an invalid event key")
        } catch {
            XCTAssert(true)
        }
        
        let eventForDispatch = eventDispatcher.events.first
        XCTAssertNil(eventForDispatch)
    }
    
}

// MARK: - API Tests

extension BatchEventBuilderTests_Events {
    
    func testImpressionEventWithUserNotInExperimentAndRollout() {
        let eventDispatcher2 = MockEventDispatcher()
        let fakeOptimizelyManager = FakeManager(sdkKey: "12345",
                                                eventDispatcher: eventDispatcher2)
        try! fakeOptimizelyManager.start(datafile: datafile)
        
        let exp = expectation(description: "Wait for event to dispatch")
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = true
        fakeOptimizelyManager.setDecisionServiceData(experiment: nil, variation: nil, source: "")
        _ = fakeOptimizelyManager.isFeatureEnabled(featureKey: featureKey, userId: userId)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut, let event = getFirstEventJSON(dispatcher: eventDispatcher2) {
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "")
            XCTAssertFalse(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
    
    func testImpressionEventWithWithUserInRollout() {
        let eventDispatcher2 = MockEventDispatcher()
        let fakeOptimizelyManager = FakeManager(sdkKey: "12345",
                                                eventDispatcher: eventDispatcher2)
        try! fakeOptimizelyManager.start(datafile: datafile)
        
        let exp = expectation(description: "Wait for event to dispatch")
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = true
        
        let experiment: Experiment = fakeOptimizelyManager.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        fakeOptimizelyManager.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        _ = fakeOptimizelyManager.isFeatureEnabled(featureKey: featureKey, userId: userId)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut, let event = getFirstEventJSON(dispatcher: eventDispatcher2) {
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
            XCTAssertTrue(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
        variation.featureEnabled = false
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
    
    func testImpressionEventWithUserInExperiment() {
        let eventDispatcher2 = MockEventDispatcher()
        let fakeOptimizelyManager = FakeManager(sdkKey: "12345",
                                                eventDispatcher: eventDispatcher2)
        try! fakeOptimizelyManager.start(datafile: datafile)
        
        let exp = expectation(description: "Wait for event to dispatch")
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = true
        
        let experiment: Experiment = (fakeOptimizelyManager.config?.allExperiments.first!)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        fakeOptimizelyManager.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        _ = fakeOptimizelyManager.isFeatureEnabled(featureKey: featureKey, userId: userId)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.1)
        if result == XCTWaiter.Result.timedOut {
            let event = getFirstEventJSON(dispatcher: eventDispatcher2)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
            XCTAssertTrue(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
        variation.featureEnabled = false
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
}

// MARK:- Holdouts

extension BatchEventBuilderTests_Events {
    func testImpressionEvent_UserInHoldout() {
        let eventDispatcher2 = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "12345", eventDispatcher: eventDispatcher2)
        
        try! optimizely.start(datafile: datafile)
        
        let holdout: Holdout = try! OTUtils.model(from: sampleHoldout)
        optimizely.config?.project.holdouts = [holdout]
        
        let exp = expectation(description: "Wait for event to dispatch")
        let user = optimizely.createUserContext(userId: userId)
        _  = user.decide(key: featureKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.2)
        if result == XCTWaiter.Result.completed {
            let event = getFirstEventJSON(client: optimizely)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.holdout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "holdout_key")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "holdout_a")
            XCTAssertFalse(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
        
    }
    
    func testImpressionEvent_UserInHoldout_IncludedFlags() {
        let eventDispatcher2 = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "12345", eventDispatcher: eventDispatcher2)
        
        try! optimizely.start(datafile: datafile)
        
        var holdout: Holdout = try! OTUtils.model(from: sampleHoldout)
        holdout.includedFlags = ["4482920077"]
        optimizely.config?.project.holdouts = [holdout]
        
        let exp = expectation(description: "Wait for event to dispatch")
        
        let user = optimizely.createUserContext(userId: userId)
        _  = user.decide(key: featureKey)
        
        
        // Add a delay before evaluating getFirstEventJSON
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill() // Fulfill the expectation after the delay
        }
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.2)
        if result == XCTWaiter.Result.completed {
            let event = getFirstEventJSON(client: optimizely)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.holdout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "holdout_key")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "holdout_a")
            XCTAssertFalse(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
        optimizely = nil
        
    }
    
    func testImpressionEvent_UserNotInHoldout_ExcludedFlags() {
        let eventDispatcher2 = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "123456", eventDispatcher: eventDispatcher2)
        
        try! optimizely.start(datafile: datafile)
        
        var holdout: Holdout = try! OTUtils.model(from: sampleHoldout)
        holdout.excludedFlags = ["4482920077"]
        optimizely.config?.project.holdouts = [holdout]
        
        let exp = expectation(description: "Wait for event to dispatch")
        
        let user = optimizely.createUserContext(userId: userId)
        _  = user.decide(key: featureKey)
        
        // Add a delay before evaluating getFirstEventJSON
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill() // Fulfill the expectation after the delay
        }
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.2)
        if result == XCTWaiter.Result.completed {
            let event = getFirstEventJSON(client: optimizely)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
            XCTAssertTrue(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
    }
    
    func testImpressionEvent_UserNotInHoldout_MissesTrafficAllocation() {
        let eventDispatcher2 = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "123457", eventDispatcher: eventDispatcher2)
        
        try! optimizely.start(datafile: datafile)
        
        var holdout: Holdout = try! OTUtils.model(from: sampleHoldout)
        /// Set traffic allocation to gero
        holdout.trafficAllocation[0].endOfRange = 0
        holdout.includedFlags = ["4482920077"]
        optimizely.config?.project.holdouts = [holdout]
        
        let exp = expectation(description: "Wait for event to dispatch")
        
        let user = optimizely.createUserContext(userId: userId)
        _  = user.decide(key: featureKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill() // Fulfill the expectation after the delay
        }
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.2)
        if result == XCTWaiter.Result.completed {
            let event = getFirstEventJSON(client: optimizely)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
            XCTAssertTrue(metaData["enabled"] as! Bool)
        } else {
            XCTFail("No event found")
        }
    }
}

// MARK: - Utils

extension BatchEventBuilderTests_Events {
    
    func getFirstEvent(dispatcher: MockEventDispatcher) -> EventForDispatch? {
        optimizely.eventLock.sync{}
        return dispatcher.events.first
    }
    
    func getFirstEventJSON(dispatcher: MockEventDispatcher) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: dispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func getFirstEventJSON(client: OptimizelyClient) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: client.eventDispatcher as! MockEventDispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func getEventJSON(data: Data) -> [String: Any]? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        return json
    }
    
}

