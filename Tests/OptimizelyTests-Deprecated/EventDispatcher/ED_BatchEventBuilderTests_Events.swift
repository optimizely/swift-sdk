/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

    var optimizely: OptimizelyClient!
    var eventDispatcher: FakeLagacyEventDispatcher!
    var project: Project!
    
    override func setUp() {
        eventDispatcher = FakeLagacyEventDispatcher()
        
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
        
        let event = getFirstEventJSON()!

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

    func testCreateConversionEvent() {
        let eventKey = "event_single_targeted_exp"
        let eventId = "10404198135"

        let attributes: [String: Any] = ["s_foo": "bar"]
        let eventTags: [String: Any] = ["browser": "chrome"]
        
        try! optimizely.track(eventKey: eventKey,
                              userId: userId,
                              attributes: attributes,
                              eventTags: eventTags)
        
        let event = getFirstEventJSON()!
        
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

// MARK: - Utils

extension BatchEventBuilderTests_Events {
    
    func getFirstEvent() -> EventForDispatch? {
        optimizely.eventLock.sync{}
        return eventDispatcher.events.first
    }
    
    func getFirstEventJSON() -> [String: Any]? {
        guard let event = getFirstEvent() else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
}

