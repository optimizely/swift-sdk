/****************************************************************************
 * Copyright 2019-2020, Optimizely, Inc. and contributors                   *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

import XCTest

class BatchEventBuilderTests_Events: XCTestCase {
    
    let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
    let userId = "test_user_1"
    let featureKey = "feature_1"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher: FakeEventDispatcher!
    var project: Project!
    let datafile = OTUtils.loadJSONDatafile("api_datafile")!
    
    override func setUp() {
        eventDispatcher = FakeEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)!
        project = optimizely.config!.project!
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
    
    func testCreateImpressionEventWithSendFlagDecisions() {
        let scenarios: [String: Bool] = [
            "experiment": true,
            "anything-else": true,
            Constants.DecisionSource.featureTest.rawValue: true,
            Constants.DecisionSource.rollout.rawValue: false
        ]
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        let variation = experiment?.getVariation(id: "10416523162")
        
        for scenario in scenarios {
            let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: experiment!, variation: variation, userId: userId, attributes: attributes, flagKey: experiment!.key, ruleType: scenario.key)
            scenario.value ? XCTAssertNotNil(event): XCTAssertNil(event)
        }
        
        // nil variation should always return nil
        for scenario in scenarios {
            let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: experiment!, variation: nil, userId: userId, attributes: attributes, flagKey: experiment!.key, ruleType: scenario.key)
            XCTAssertNil(event)
        }
        
        // should always return a event if sendFlagDecisions is set
        optimizely.config?.project.sendFlagDecisions = true
        for scenario in scenarios {
            let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: experiment!, variation: nil, userId: userId, attributes: attributes, flagKey: experiment!.key, ruleType: scenario.key)
            XCTAssertNotNil(event)
        }
        optimizely.config?.project.sendFlagDecisions = nil
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
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: experiment!, variation: nil, userId: userId, attributes: attributes, flagKey: experiment!.key, ruleType: Constants.DecisionSource.featureTest.rawValue)
        XCTAssertNotNil(event)
        
        let visitor = (getEventJSON(data: event!)!["visitors"] as! Array<Dictionary<String, Any>>)[0]
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, "feature-test")
        XCTAssertEqual(metaData["rule_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["flag_key"] as! String, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(metaData["variation_key"] as! String, "")
        optimizely.config?.project.sendFlagDecisions = nil
    }
    
    func testCreateImpressionEventWithoutExperimentAndVariation() {
        
        optimizely.config?.project.sendFlagDecisions = true
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!, experiment: nil, variation: nil, userId: userId, attributes: [String: Any](), flagKey: "feature_1", ruleType: Constants.DecisionSource.rollout.rawValue)
        XCTAssertNotNil(event)
        
        let visitor = (getEventJSON(data: event!)!["visitors"] as! Array<Dictionary<String, Any>>)[0]
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
        
        let metaData = decision["metadata"] as! Dictionary<String, Any>
        XCTAssertEqual(metaData["rule_type"] as! String, "rollout")
        XCTAssertEqual(metaData["rule_key"] as! String, "")
        XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
        XCTAssertEqual(metaData["variation_key"] as! String, "")
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
        let eventDispatcher2 = FakeEventDispatcher()
        let fakeOptimizelyManager = FakeManager(sdkKey: "12345",
                                            eventDispatcher: eventDispatcher2)
        try! fakeOptimizelyManager.start(datafile: datafile)
        
        let exp = expectation(description: "Wait for event to dispatch")
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = true
        fakeOptimizelyManager.setDecisionServiceData(experiment: nil, variation: nil, source: "")
        _ = fakeOptimizelyManager.isFeatureEnabled(featureKey: featureKey, userId: userId)
        
        let result = XCTWaiter.wait(for: [exp], timeout: 0.1)
         if result == XCTWaiter.Result.timedOut {
            let event = getFirstEventJSON(dispatcher: eventDispatcher2)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "")
         } else {
             XCTFail("No event found")
         }
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
    
    func testImpressionEventWithWithUserInRollout() {
        let eventDispatcher2 = FakeEventDispatcher()
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
         if result == XCTWaiter.Result.timedOut {
            let event = getFirstEventJSON(dispatcher: eventDispatcher2)!
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"]  as! Array<Dictionary<String, Any>>)[0]
            
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
         } else {
             XCTFail("No event found")
         }
        variation.featureEnabled = false
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
    
    func testImpressionEventWithUserInExperiment() {
        let eventDispatcher2 = FakeEventDispatcher()
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
         } else {
             XCTFail("No event found")
         }
        variation.featureEnabled = false
        fakeOptimizelyManager.config!.project!.sendFlagDecisions = nil
    }
}

// MARK: - Utils

extension BatchEventBuilderTests_Events {
    
    func getFirstEvent(dispatcher: FakeEventDispatcher) -> EventForDispatch? {
        optimizely.eventLock.sync{}
        return dispatcher.events.first
    }
    
    func getFirstEventJSON(dispatcher: FakeEventDispatcher) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: dispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func  getEventJSON(data: Data) -> [String: Any]? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        return json
    }
    
}

