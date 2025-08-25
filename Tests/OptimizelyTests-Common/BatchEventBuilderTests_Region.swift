//
// Copyright 2023-2025, Optimizely, Inc. and contributors
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

class BatchEventBuilderTests_Region: XCTestCase {
    
    let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
    let userId = "test_user_1"
    let featureKey = "feature_1"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher: MockEventDispatcher!
    var project: Project!
    let datafile = OTUtils.loadJSONDatafile("api_datafile")!
    
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
    
    // MARK: - Test Impression Event with Region
    
    func testCreateImpressionEventWithUSRegion() {
        // Set the region to US
        optimizely.config?.project.region = .US
        
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
        
        // Check if the region is correctly set to US in the event
        XCTAssertEqual(event["region"] as! String, "US")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .US))
    }
    
    func testCreateImpressionEventWithEURegion() {
        // Set the region to EU
        optimizely.config?.project.region = .EU
        
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
        
        // Check if the region is correctly set to EU in the event
        XCTAssertEqual(event["region"] as! String, "EU")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .EU))
    }

    func testCreateImpressionEventWithInvalidRegion() {
        // Set the region to invalid ZZ
        optimizely.config?.project.region = .ZZ
        
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
        
        // Check if the region is correctly set to default US in the event
        XCTAssertEqual(event["region"] as! String, "US")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .US))
    }
    
    // MARK: - Test Conversion Event with Region
    
    func testCreateConversionEventWithUSRegion() {
        // Set the region to US
        optimizely.config?.project.region = .US
        
        let eventKey = "event_single_targeted_exp"
        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        let event = getFirstEventJSON(dispatcher: eventDispatcher)!
        
        // Check if the region is correctly set to US in the event
        XCTAssertEqual(event["region"] as! String, "US")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .US))
    }
    
    func testCreateConversionEventWithEURegion() {
        // Set the region to EU
        optimizely.config?.project.region = .EU
        
        let eventKey = "event_single_targeted_exp"
        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        let event = getFirstEventJSON(dispatcher: eventDispatcher)!
        
        // Check if the region is correctly set to EU in the event
        XCTAssertEqual(event["region"] as! String, "EU")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .EU))
    }

    func testCreateConversionEventWithInvalidRegion() {
        // Set the region to invalid ZZ
        optimizely.config?.project.region = .ZZ
        
        let eventKey = "event_single_targeted_exp"
        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        let event = getFirstEventJSON(dispatcher: eventDispatcher)!
        
        // Check if the region is correctly set to default US in the event
        XCTAssertEqual(event["region"] as! String, "US")
        
        // Check if the event was sent to the correct endpoint
        let eventForDispatch = getFirstEvent(dispatcher: eventDispatcher)!
        XCTAssertEqual(eventForDispatch.url.absoluteString, EventForDispatch.getEndpoint(for: .US))
    }
    
    // MARK: - Test Direct Event Creation with Region
    
    func testDirectImpressionEventCreationWithUSRegion() {
        // Set the region to US
        optimizely.config?.project.region = .US
        
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        let variation = experiment?.variations.first
        
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                           experiment: experiment,
                                                           variation: variation,
                                                           userId: userId,
                                                           attributes: nil,
                                                           flagKey: experiment!.key,
                                                           ruleType: Constants.DecisionSource.experiment.rawValue,
                                                           enabled: true,
                                                           cmabUUID: nil)
        
        XCTAssertNotNil(event)
        
        let eventJson = getEventJSON(data: event!)!
        
        // Check if the region is correctly set to US in the event
        XCTAssertEqual(eventJson["region"] as! String, "US")
    }
    
    func testDirectImpressionEventCreationWithEURegion() {
        // Set the region to EU
        optimizely.config?.project.region = .EU
        
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        let variation = experiment?.variations.first
        
        let event = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                           experiment: experiment,
                                                           variation: variation,
                                                           userId: userId,
                                                           attributes: nil,
                                                           flagKey: experiment!.key,
                                                           ruleType: Constants.DecisionSource.experiment.rawValue,
                                                           enabled: true,
                                                           cmabUUID: nil)
        
        XCTAssertNotNil(event)
        
        let eventJson = getEventJSON(data: event!)!
        
        // Check if the region is correctly set to EU in the event
        XCTAssertEqual(eventJson["region"] as! String, "EU")
    }
    
    func testDirectConversionEventCreationWithUSRegion() {
        // Set the region to US
        optimizely.config?.project.region = .US
        
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        let event = BatchEventBuilder.createConversionEvent(config: optimizely.config!,
                                                           eventKey: eventKey,
                                                           userId: userId,
                                                           attributes: nil,
                                                           eventTags: eventTags)
        
        XCTAssertNotNil(event)
        
        let eventJson = getEventJSON(data: event!)!
        
        // Check if the region is correctly set to US in the event
        XCTAssertEqual(eventJson["region"] as! String, "US")
    }
    
    func testDirectConversionEventCreationWithEURegion() {
        // Set the region to EU
        optimizely.config?.project.region = .EU
        
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        let event = BatchEventBuilder.createConversionEvent(config: optimizely.config!,
                                                           eventKey: eventKey,
                                                           userId: userId,
                                                           attributes: nil,
                                                           eventTags: eventTags)
        
        XCTAssertNotNil(event)
        
        let eventJson = getEventJSON(data: event!)!
        
        // Check if the region is correctly set to EU in the event
        XCTAssertEqual(eventJson["region"] as! String, "EU")
    }
    
    // MARK: - Test Event Batching with Region
    
    func testEventBatchingWithSameRegion() {
        // Set the region to US
        optimizely.config?.project.region = .US
        
        // Create two events with the same region
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        let variation = experiment?.variations.first
        
        // Create first event
        let event1 = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                            experiment: experiment,
                                                            variation: variation,
                                                            userId: userId,
                                                            attributes: nil,
                                                            flagKey: experiment!.key,
                                                            ruleType: Constants.DecisionSource.experiment.rawValue,
                                                            enabled: true,
                                                            cmabUUID: nil)
        
        // Create second event
        let event2 = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                            experiment: experiment,
                                                            variation: variation,
                                                            userId: userId + "2",
                                                            attributes: nil,
                                                            flagKey: experiment!.key,
                                                            ruleType: Constants.DecisionSource.experiment.rawValue,
                                                            enabled: true,
                                                            cmabUUID: nil)
        
        // Create EventForDispatch objects
        let eventForDispatch1 = EventForDispatch(url: nil, body: event1!, region: .US)
        let eventForDispatch2 = EventForDispatch(url: nil, body: event2!, region: .US)
        
        // Test batching
        let batchResult = [eventForDispatch1, eventForDispatch2].batch()
        
        // Events should be batched together since they have the same region
        XCTAssertEqual(batchResult.numEvents, 2)
        XCTAssertNotNil(batchResult.eventForDispatch)
    }
    
    func testEventBatchingWithDifferentRegions() {
        // Create two events with different regions
        let experiment = optimizely.config?.getExperiment(id: "10390977714")
        let variation = experiment?.variations.first
        
        // Set region to US for first event
        optimizely.config?.project.region = .US
        
        // Create first event (US)
        let event1 = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                            experiment: experiment,
                                                            variation: variation,
                                                            userId: userId,
                                                            attributes: nil,
                                                            flagKey: experiment!.key,
                                                            ruleType: Constants.DecisionSource.experiment.rawValue,
                                                            enabled: true,
                                                            cmabUUID: nil)
        
        // Set region to EU for second event
        optimizely.config?.project.region = .EU
        
        // Create second event (EU)
        let event2 = BatchEventBuilder.createImpressionEvent(config: optimizely.config!,
                                                            experiment: experiment,
                                                            variation: variation,
                                                            userId: userId + "2",
                                                            attributes: nil,
                                                            flagKey: experiment!.key,
                                                            ruleType: Constants.DecisionSource.experiment.rawValue,
                                                            enabled: true,
                                                            cmabUUID: nil)
        
        // Create EventForDispatch objects
        let eventForDispatch1 = EventForDispatch(url: nil, body: event1!, region: .US)
        let eventForDispatch2 = EventForDispatch(url: nil, body: event2!, region: .EU)
        
        // Test batching
        let batchResult = [eventForDispatch1, eventForDispatch2].batch()
        
        // Only the first event should be batched as they have different regions
        XCTAssertEqual(batchResult.numEvents, 1)
        XCTAssertNotNil(batchResult.eventForDispatch)
    }
    
    // MARK: - Utils
    
    func getFirstEvent(dispatcher: MockEventDispatcher) -> EventForDispatch? {
        optimizely.eventLock.sync{}
        return dispatcher.events.first
    }
    
    func getFirstEventJSON(dispatcher: MockEventDispatcher) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: dispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func getEventJSON(data: Data) -> [String: Any]? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        return json
    }
}
