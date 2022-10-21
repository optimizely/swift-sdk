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

import XCTest

// MARK: - Sample Data

class ProjectTests: XCTestCase {
    static var sampleData: [String: Any] = ["version": "4",
                                            "projectId": "11111",
                                            "experiments": [ExperimentTests.sampleData],
                                            "audiences": [AudienceTests.sampleData],
                                            "groups": [GroupTests.sampleData],
                                            "attributes": [AttributeTests.sampleData],
                                            "accountId": "1234567890",
                                            "events": [EventTests.sampleData],
                                            "revision": "5",
                                            "anonymizeIP": true,
                                            "rollouts": [RolloutTests.sampleData],
                                            "typedAudiences": [AudienceTests.sampleData],
                                            "integrations": [IntegrationTests.sampleData],
                                            "featureFlags": [FeatureFlagTests.sampleData],
                                            "botFiltering": false,
                                            "sendFlagDecisions": true]
}

// MARK: - Decode

extension ProjectTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ProjectTests.sampleData
        
        let model: Project = try! OTUtils.model(from: data)
        
        XCTAssert(model.version == "4")
        XCTAssert(model.projectId == "11111")
        XCTAssert(model.experiments == [try! OTUtils.model(from: ExperimentTests.sampleData)])
        XCTAssert(model.audiences == [try! OTUtils.model(from: AudienceTests.sampleData)])
        XCTAssert(model.groups == [try! OTUtils.model(from: GroupTests.sampleData)])
        XCTAssert(model.attributes == [try! OTUtils.model(from: AttributeTests.sampleData)])
        XCTAssert(model.accountId == "1234567890")
        XCTAssert(model.events == [try! OTUtils.model(from: EventTests.sampleData)])
        XCTAssert(model.revision == "5")
        XCTAssert(model.anonymizeIP == true)
        XCTAssert(model.rollouts == [try! OTUtils.model(from: RolloutTests.sampleData)])
        XCTAssert(model.typedAudiences == [try! OTUtils.model(from: AudienceTests.sampleData)])
        XCTAssert(model.integrations == [try! OTUtils.model(from: IntegrationTests.sampleData)])
        XCTAssert(model.featureFlags == [try! OTUtils.model(from: FeatureFlagTests.sampleData)])
        XCTAssert(model.botFiltering == false)
        XCTAssert(model.sendFlagDecisions == true)
        XCTAssert(model.sdkKey == nil)
        XCTAssert(model.environmentKey == nil)
    }
    
    func testDecodeWithSDKKeyAndEnvironmentKey() {
        var data: [String: Any] = ProjectTests.sampleData
        data["sdkKey"] = "123"
        data["environmentKey"] = "production"
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertEqual(model?.sdkKey, "123")
        XCTAssertEqual(model?.environmentKey, "production")
    }
    
    func testDecodeFailWithMissingVersion() {
        var data: [String: Any] = ProjectTests.sampleData
        data["version"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingProjectId() {
        var data: [String: Any] = ProjectTests.sampleData
        data["projectId"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperiments() {
        var data: [String: Any] = ProjectTests.sampleData
        data["experiments"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingAudiences() {
        var data: [String: Any] = ProjectTests.sampleData
        data["audiences"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingGroups() {
        var data: [String: Any] = ProjectTests.sampleData
        data["groups"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingAttributes() {
        var data: [String: Any] = ProjectTests.sampleData
        data["attributes"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingAccountId() {
        var data: [String: Any] = ProjectTests.sampleData
        data["accountId"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingEvents() {
        var data: [String: Any] = ProjectTests.sampleData
        data["events"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingRevision() {
        var data: [String: Any] = ProjectTests.sampleData
        data["revision"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingAnonymizeIP() {
        var data: [String: Any] = ProjectTests.sampleData
        data["anonymizeIP"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingRollouts() {
        var data: [String: Any] = ProjectTests.sampleData
        data["rollouts"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingFeatureFlags() {
        var data: [String: Any] = ProjectTests.sampleData
        data["featureFlags"] = nil
        
        let model: Project? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    // MARK: - Optional Fields
    
    func testDecodeSuccessWithMissingTypedAudiences() {
        var data: [String: Any] = ProjectTests.sampleData
        data["typedAudiences"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
        XCTAssertNil(model.typedAudiences)
    }
    
    func testDecodeSuccessWithMissingIntegrations() {
        var data: [String: Any] = ProjectTests.sampleData
        data["integrations"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
        XCTAssertNil(model.integrations)
    }
    
    func testDecodeSuccessWithMissingBotFiltering() {
        var data: [String: Any] = ProjectTests.sampleData
        data["botFiltering"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
        XCTAssertNil(model.botFiltering)
    }
    
    func testDecodeSuccessWithMissingSendFlagDecisions() {
        var data: [String: Any] = ProjectTests.sampleData
        data["sendFlagDecisions"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
        XCTAssertNil(model.sendFlagDecisions)
    }
    
}

// MARK: - Encode

extension ProjectTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = ProjectTests.sampleData
        let modelGiven: Project = try! OTUtils.model(from: data)
        
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
}
