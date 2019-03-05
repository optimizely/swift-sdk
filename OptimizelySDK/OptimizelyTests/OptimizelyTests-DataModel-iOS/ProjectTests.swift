//
//  ProjectTests.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/19/19.
//  Copyright © 2019 Optimizely. All rights reserved.
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
                                            "variables": [FeatureVariableTests.sampleData],
                                            "rollouts": [RolloutTests.sampleData],
                                            "typedAudiences": [AudienceTests.sampleData],
                                            "featureFlags": [FeatureFlagTests.sampleData],
                                            "botFiltering": false]
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
        XCTAssert(model.variables == [try! OTUtils.model(from: FeatureVariableTests.sampleData)])
        XCTAssert(model.rollouts == [try! OTUtils.model(from: RolloutTests.sampleData)])
        XCTAssert(model.typedAudiences == [try! OTUtils.model(from: AudienceTests.sampleData)])
        XCTAssert(model.featureFlags == [try OTUtils.model(from: FeatureFlagTests.sampleData)])
        XCTAssert(model.botFiltering == false)
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
    
    //MARK: - Optional Fields

    func testDecodeSuccessWithMissingAnonymizeIP() {
        var data: [String: Any] = ProjectTests.sampleData
        data["anonymizeIP"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
    }
    
    func testDecodeSuccessWithMissingVariables() {
        var data: [String: Any] = ProjectTests.sampleData
        data["variables"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
    }
    
    func testDecodeSuccessWithMissingRollouts() {
        var data: [String: Any] = ProjectTests.sampleData
        data["rollouts"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
    }
    
    func testDecodeSuccessWithMissingTypedAudiences() {
        var data: [String: Any] = ProjectTests.sampleData
        data["typedAudiences"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
    }
    
    
    func testDecodeSuccessWithMissingFeatureFlags() {
        var data: [String: Any] = ProjectTests.sampleData
        data["featureFlags"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
    }
    
    
    func testDecodeSuccessWithMissingBotFiltering() {
        var data: [String: Any] = ProjectTests.sampleData
        data["botFiltering"] = nil
        
        let model: Project = try! OTUtils.model(from: data)
        XCTAssert(model.projectId == "11111")
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

