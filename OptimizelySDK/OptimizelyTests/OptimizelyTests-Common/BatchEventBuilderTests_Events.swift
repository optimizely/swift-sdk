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
import SwiftyJSON

class BatchEventBuilderTests_Events: XCTestCase {

    let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
    let userId = "test_user_1"

    var optimizely: OptimizelyClient!
    var eventDispatcher: FakeEventDispatcher!
    var project: Project!
    
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
        
        let eventForDispatch = eventDispatcher.events.first!
        let json = JSON(eventForDispatch.body)
        let event = json.dictionaryValue
        
        XCTAssertEqual(event["revision"]!.stringValue, project.revision)
        XCTAssertEqual(event["account_id"]!.stringValue, project.accountId)
        XCTAssertEqual(event["client_version"]!.stringValue, Utils.sdkVersion)
        XCTAssertEqual(event["project_id"]!.stringValue, project.projectId)
        XCTAssertEqual(event["client_name"]!.stringValue, "swift-sdk")
        XCTAssertEqual(event["anonymize_ip"]!.boolValue, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"]!.boolValue, true)
        
        let visitor = event["visitors"]![0].dictionaryValue
        
        XCTAssertEqual(visitor["visitor_id"]!.stringValue, userId)

        let snapshot = visitor["snapshots"]![0].dictionaryValue
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"]!.arrayValue
        XCTAssertEqual(eventAttributes.count, attributes.count)

        let decision = snapshot["decisions"]![0].dictionaryValue
        
        XCTAssertEqual(decision["variation_id"]!.stringValue, expVariationId)
        XCTAssertEqual(decision["campaign_id"]!.stringValue, expCampaignId)
        XCTAssertEqual(decision["experiment_id"]!.stringValue, expExperimentId)
        
        let de = snapshot["events"]![0].dictionaryValue
        
        XCTAssertEqual(de["entity_id"]!.stringValue, expCampaignId)
        XCTAssertEqual(de["key"]!.stringValue, "campaign_activated")
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"]!.int64Value)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert(de["uuid"]!.stringValue.count > 20)
        // event tags are tested separately below
        XCTAssert(de["tags"]!.count==0)
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
        let eventForDispatch = eventDispatcher.events.first!
        let json = JSON(eventForDispatch.body)
        let event = json.dictionaryValue
        
        XCTAssertEqual(event["revision"]!.stringValue, project.revision)
        XCTAssertEqual(event["account_id"]!.stringValue, project.accountId)
        XCTAssertEqual(event["client_version"]!.stringValue, Utils.sdkVersion)
        XCTAssertEqual(event["project_id"]!.stringValue, project.projectId)
        XCTAssertEqual(event["client_name"]!.stringValue, "swift-sdk")
        XCTAssertEqual(event["anonymize_ip"]!.boolValue, project.anonymizeIP)
        XCTAssertEqual(event["enrich_decisions"]!.boolValue, true)
        
        let visitor = event["visitors"]![0].dictionaryValue
        
        XCTAssertEqual(visitor["visitor_id"]!.stringValue, userId)
        
        let snapshot = visitor["snapshots"]![0].dictionaryValue
        
        // attributes contents are tested separately in "BatchEventBuilder_Attributes.swift"
        let eventAttributes = visitor["attributes"]!.arrayValue
        XCTAssertEqual(eventAttributes[0]["key"], "s_foo")
        XCTAssertEqual(eventAttributes[0]["value"], "bar")

        let decisions = snapshot["decisions"]
        
        XCTAssertNil(decisions)
        
        let de = snapshot["events"]![0].dictionaryValue
        
        XCTAssertEqual(de["entity_id"]!.stringValue, eventId)
        XCTAssertEqual(de["key"]!.stringValue, eventKey)
        let expTimestamp = Int64((Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate) * 1000)
        // divide by 1000 to ignore small time difference
        XCTAssertEqual((de["timestamp"]!.int64Value)/1000, expTimestamp / 1000)
        // cannot validate randomly-generated string. check if long enough.
        XCTAssert(de["uuid"]!.stringValue.count > 20)
        // {tags, revenue, value} are tested separately below
        XCTAssertEqual(de["tags"]!["browser"].stringValue, "chrome")
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

