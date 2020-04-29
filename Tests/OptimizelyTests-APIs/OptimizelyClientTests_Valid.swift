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

class OptimizelyClientTests_Valid: XCTestCase {

    // MARK: - Constants
    
    let kExperimentKey = "exp_with_audience"
    
    let kVariationKey = "a"
    let kVariationOtherKey = "b"
    
    let kFeatureKey = "feature_1"
    let kFeatureOtherKey = "feature_2"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    let kVariableKeyJSON = "j_1"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    let kVariableValueJSON = "{\"value\":1}"
    
    let kEventKey = "event1"
    
    let kUserId = "11111"
    
    // MARK: - Properties
    
    var datafile: Data!
    var optimizely: OptimizelyClient!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    func testMultiStart() {
        try! self.optimizely.start(datafile: datafile)
        try! self.optimizely.start(datafile: datafile)
        DispatchQueue.global().async {
            for _ in 0...10 {
                try! self.optimizely.start(datafile: self.datafile)
            }
        }
        sleep(1)
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)

    }
    
    func testActivate() {
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testActivateEmptyUserId() {
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: "")
        XCTAssert(variationKey == kVariationKey)
    }

    func testGetVariationKey() {
        let variationKey: String = try! self.optimizely.getVariationKey(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testGetForcedVariation() {
        let variationKey: String? = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testSetForcedVariationKey() {
        _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)
        let variationKey: String? = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
    }
    
    func testIsFeatureEnabled() {
        let result = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertTrue(result)
    }
    
    func testGetFeatureVariableBoolean() {
        let result: Bool = try! self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKeyBool,
                                                                           userId: kUserId)
        XCTAssert(result == kVariableValueBool)
    }
    
    func testGetFeatureVariableDouble() {
        let result: Double = try! self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey,
                                                                            variableKey: kVariableKeyDouble,
                                                                            userId: kUserId)
        XCTAssert(result == kVariableValueDouble)
    }
    
    func testGetFeatureVariableInteger() {
        let result: Int? = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey,
                                                                          variableKey: kVariableKeyInt,
                                                                          userId: kUserId)
        XCTAssert(result == kVariableValueInt)
    }
    
    func testGetFeatureVariableString() {
        let result: String? = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey,
                                                                            variableKey: kVariableKeyString,
                                                                            userId: kUserId)
        XCTAssert(result == kVariableValueString)
    }
    
    func testGetFeatureVariableJSON() {
        let result: OptimizelyJSON? = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey,
                                                                                  variableKey: kVariableKeyJSON,
                                                                                  userId: kUserId)
        XCTAssert(result?.toString() == kVariableValueJSON)
        XCTAssert((result?.toMap()["value"] as! Int) == 1)
        let intValue: Int? = result?.getValue(jsonPath: "value")
        
        XCTAssertNotNil(intValue)
        XCTAssert(intValue == 1)
    }
    
    func testGetAllFeatureVariables() {
        let optimizelyJSON = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey,
                                                                         userId: kUserId)
        let variablesMap = optimizelyJSON!.toMap()
        XCTAssert(variablesMap[kVariableKeyString] as! String == kVariableValueString)
        XCTAssert(variablesMap[kVariableKeyBool] as! Bool == kVariableValueBool)
        XCTAssert(variablesMap[kVariableKeyInt] as! Int == kVariableValueInt)
        XCTAssert(variablesMap[kVariableKeyDouble] as! Double == kVariableValueDouble)
        XCTAssert((variablesMap[kVariableKeyJSON] as! [String: Any])["value"] as! Int == 1)
    }
    
    func testGetAllFeatureVariablesWithFeatureVariables() {
        let config = self.optimizely.config
        config?.allExperiments[0].variations[0].variables?.append(contentsOf:[
            Variable(id: "2687470095", value: "43"),
            Variable(id: "2689280165", value: "4.3"),
            Variable(id: "2689660112", value: "false"),
            Variable(id: "2696150066", value: "f_foo"),
            Variable(id: "2696150067", value: "{\"value\":2}")
            ]
        )
        self.optimizely.config = config
        let optimizelyJSON = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey,
                                                                         userId: kUserId)
        let variablesMap = optimizelyJSON!.toMap()
        XCTAssert(variablesMap[kVariableKeyString] as! String == "f_foo")
        XCTAssert(variablesMap[kVariableKeyBool] as! Bool == false)
        XCTAssert(variablesMap[kVariableKeyInt] as! Int == 43)
        XCTAssert(variablesMap[kVariableKeyDouble] as! Double == 4.3)
        XCTAssert((variablesMap[kVariableKeyJSON] as! [String: Any])["value"] as! Int == 2)
    }
    
    func testGetAllFeatureVariablesFeatureDisabled() {
        let config = self.optimizely.config
        config?.allExperiments[0].variations[0].variables?.append(contentsOf:[
            Variable(id: "2687470095", value: "43"),
            Variable(id: "2689280165", value: "4.3"),
            Variable(id: "2689660112", value: "false"),
            Variable(id: "2696150066", value: "f_foo"),
            Variable(id: "2696150067", value: "{\"value\":2}")
            ]
        )
        self.optimizely.config = config
        self.optimizely.config?.allExperiments[0].variations[0].featureEnabled = false
        let optimizelyJSON = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey,
                                                                         userId: kUserId)
        let variablesMap = optimizelyJSON!.toMap()
        XCTAssert(variablesMap[kVariableKeyString] as! String == kVariableValueString)
        XCTAssert(variablesMap[kVariableKeyBool] as! Bool == kVariableValueBool)
        XCTAssert(variablesMap[kVariableKeyInt] as! Int == kVariableValueInt)
        XCTAssert(variablesMap[kVariableKeyDouble] as! Double == kVariableValueDouble)
        XCTAssert((variablesMap[kVariableKeyJSON] as! [String: Any])["value"] as! Int == 1)
    }
    
    func testGetEnabledFeatures() {
        let result: [String] = self.optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssert(result == [kFeatureKey])
    }
    
    func testTrack() {
        var trackSuccessful = false
        do {
            try self.optimizely.track(eventKey: kEventKey, userId: kUserId)
            trackSuccessful = true
        } catch {
        }
        XCTAssert(trackSuccessful)
    }

}
