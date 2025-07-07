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

class OptimizelyClientTests_Others: XCTestCase {
    
    let kExperimentKey = "exp_with_audience"
    let kInvalidExperimentKey = "invalid_key"
    let kVariationKey = "a"
    
    let kFeatureKey = "feature_1"
    let kFeatureKeyNoVariables = "feature_2"
    let kInvalidFeatureKey = "invalid_key"

    let kVariableKeyString = "s_foo"
    let kInvalidVariableKeyString = "invalid_key"
    
    let kVariableKeyJSON = "j_1"
    let kInvalidVariableKeyJSON = "invalid_key"
    
    let kVariableKeyBool = "b_true"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyInt = "i_42"

    let kUserId = "user"
    
    var optimizely: OptimizelyClient!
    let eventDispatcher = MockEventDispatcher()

    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "api_datafile",
                                                   clearUserProfileService: true,
                                                   eventDispatcher: eventDispatcher)!
    }

    func testActivate_InvalidExperimentKey() {
        var variationKey = try? optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNotNil(variationKey)

        variationKey = try? optimizely.activate(experimentKey: kInvalidExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }

    func testGetVariation_InvalidExperimentKey() {
        var variation = try? optimizely.getVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNotNil(variation)
        
        variation = try? optimizely.getVariation(experimentKey: kInvalidExperimentKey, userId: kUserId)
        XCTAssertNil(variation)
    }

    func testIsFeatureEnabled_InvalidFeatureKey() {
        var result = optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        XCTAssert(result)
        
        result = optimizely.isFeatureEnabled(featureKey: kInvalidFeatureKey, userId: kUserId)
        XCTAssertFalse(result)
    }
    
    func testGetFeatureVariableString_InvalidFeatureKey() {
        var value = try? optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNotNil(value)
        
        value = try? optimizely.getFeatureVariableString(featureKey: kInvalidFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNil(value)
    }
    
    func testGetFeatureVariableJSON_InvalidFeatureKey() {
        var value = try? optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        XCTAssertNotNil(value)
        
        value = try? optimizely.getFeatureVariableJSON(featureKey: kInvalidFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        XCTAssertNil(value)
    }
    
    func testGetAllFeatureVariables_InvalidType() {
        for (index, featureFlag) in self.optimizely.config!.project!.featureFlags.enumerated() {
            if featureFlag.key == kFeatureKey {
                var flag = featureFlag
                flag.variables.append(FeatureVariable(id: "2689660113", key: "valid_key", type: "invalid_type", subType: nil, defaultValue: "true"))
                self.optimizely.config?.project.featureFlags[index] = flag
                break
            }
        }
        let optimizelyJSON = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey,
                                                                         userId: kUserId)
        let variablesMap = optimizelyJSON!.toMap()
        XCTAssert((variablesMap[kVariableKeyJSON] as! [String: Any])["value"] as! Int == 1)
        XCTAssertEqual(variablesMap[kVariableKeyString] as! String, "foo")
        XCTAssertEqual(variablesMap[kVariableKeyBool] as! Bool, true)
        XCTAssertEqual(variablesMap[kVariableKeyDouble] as! Double, 4.2)
        XCTAssertEqual(variablesMap[kVariableKeyInt] as! Int, 42)
        // Verifying that map contains value as string if type is invalid
        XCTAssertEqual(variablesMap["valid_key"] as? String, "true")
        XCTAssertEqual(variablesMap["i_1"] as! String, "invalid")
    }
    
    func testGetAllFeatureVariables_InvalidFeatureKey() {
        var optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertNotNil(optimizelyJSON)
        
        optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: kInvalidFeatureKey, userId: kUserId)
        XCTAssertNil(optimizelyJSON)
    }

    func testGetFeatureVariableString_InvalidVariableKey() {
        var value = try? optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNotNil(value)
        
        value = try? optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kInvalidVariableKeyString, userId: kUserId)
        XCTAssertNil(value)
    }
    
    func testGetFeatureVariableJSON_InvalidVariableKey() {
        var value = try? optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        XCTAssertNotNil(value)
        
        value = try? optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kInvalidVariableKeyJSON, userId: kUserId)
        XCTAssertNil(value)
    }
    
    func testGetFeatureVariable_WrongType() {
        // read integer for string-type variable
        let value = try? optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNil(value)
    }
    
    func testGetFeatureVariable_NotSupportedType() {
        let value: [String: Int]? = try? optimizely.getFeatureVariable(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNil(value)
    }

    func testGetFeatureVariableString_DecisionFailed() {
        var optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                                  clearUserProfileService: true)!
        
        let featureKey = "feature_running_exp_enabled_targeted_with_variable_overrides"
        let attributeKey = "string_attribute"
        let attributeValue = "exact_match"
        
        let variableKey = "s_foo"
        let variableValue = "foo bar"
        let variableDefaultValue = "foo"
        
        let userId = "user"
        let attributes: [String: Any] = [attributeKey: attributeValue]
        let attributesNotMatch: [String: Any] = [attributeKey: "wrong_value"]

        var value = try? optimizely.getFeatureVariableString(featureKey: featureKey,
                                                        variableKey: variableKey,
                                                        userId: userId,
                                                        attributes: attributes)
        XCTAssert(value == variableValue)

        // reset user-profile-service to test variation-not-found case (default variable value)
        
        optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                                  clearUserProfileService: true)!

        value = try? optimizely.getFeatureVariableString(featureKey: featureKey,
                                                             variableKey: variableKey,
                                                             userId: userId,
                                                             attributes: attributesNotMatch)
        XCTAssert(value == variableDefaultValue)
    }
    
    func testGetAllFeatureVariables_DecisionFailed() {
        var optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                                  clearUserProfileService: true)!
        
        let featureKey = "feature_running_exp_enabled_targeted_with_variable_overrides"
        let attributeKey = "string_attribute"
        let attributeValue = "exact_match"
        
        let variableKey = "s_foo"
        let variableValue = "foo bar"
        let variableDefaultValue = "foo"
        
        let userId = "user"
        let attributes: [String: Any] = [attributeKey: attributeValue]
        let attributesNotMatch: [String: Any] = [attributeKey: "wrong_value"]
        
        var optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: featureKey,
                                                                    userId: userId,
                                                                    attributes: attributes)
        var variableMap = optimizelyJSON!.toMap()
        XCTAssert((variableMap[variableKey] as! String) == variableValue)
        
        // reset user-profile-service to test variation-not-found case (default variable value)
        
        optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                              clearUserProfileService: true)!
        
        optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: featureKey,
                                                                userId: userId,
                                                                attributes: attributesNotMatch)
        variableMap = optimizelyJSON!.toMap()
        XCTAssert((variableMap[variableKey] as! String) == variableDefaultValue)
    }
    
    func testGetFeatureVariable_MissingDefaultValue() {
        let optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                                  clearUserProfileService: true)!
        
        let featureKey = "feature_running_exp_enabled_targeted_with_variable_overrides"
        let attributeKey = "string_attribute"
        
        let variableKey = "s_foo"
        let variableDefaultValue = "foo"
        
        let userId = "user"
        let attributesNotMatch: [String: Any] = [attributeKey: "wrong_value"]
        
        var valueString = try? optimizely.getFeatureVariableString(featureKey: featureKey,
                                                                   variableKey: variableKey,
                                                                   userId: userId,
                                                                   attributes: attributesNotMatch)
        XCTAssert(valueString == variableDefaultValue)
        
        // remove defaultValue of the target featureFlag variable
        
        var featureFlag = optimizely.config!.getFeatureFlag(key: featureKey)!
        var variable = featureFlag.getVariable(key: variableKey)!
        variable.defaultValue = nil
        featureFlag.variables = [variable]
        optimizely.config!.featureFlagKeyMap[featureKey] = featureFlag
        
        valueString = try? optimizely.getFeatureVariableString(featureKey: featureKey,
                                                               variableKey: variableKey,
                                                               userId: userId,
                                                               attributes: attributesNotMatch)
        XCTAssert(valueString == "", "Should return empty string when default value is not defined")
    }
    
    func testGetAllFeatureVariables_MissingDefaultValue() {
        let optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
                                                  clearUserProfileService: true)!
        
        let featureKey = "feature_running_exp_enabled_targeted_with_variable_overrides"
        let attributeKey = "string_attribute"
        
        let variableKey = "s_foo"
        let variableDefaultValue = "foo"
        
        let userId = "user"
        let attributesNotMatch: [String: Any] = [attributeKey: "wrong_value"]
        
        var optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: featureKey,
                                                                    userId: userId,
                                                                    attributes: attributesNotMatch)
        var variableMap = optimizelyJSON!.toMap()
        XCTAssert((variableMap[variableKey] as! String) == variableDefaultValue)
        
        // remove defaultValue of the target featureFlag variable
        
        var featureFlag = optimizely.config!.getFeatureFlag(key: featureKey)!
        var variable = featureFlag.getVariable(key: variableKey)!
        variable.defaultValue = nil
        featureFlag.variables = [variable]
        optimizely.config!.featureFlagKeyMap[featureKey] = featureFlag
        
        optimizelyJSON = try? optimizely.getAllFeatureVariables(featureKey: featureKey,
                                                                userId: userId,
                                                                attributes: attributesNotMatch)
        variableMap = optimizelyJSON!.toMap()
        XCTAssert((variableMap[variableKey] as! String) == "", "Should return empty string when default value is not defined")
    }
    
    func testSendImpressionEvent_FailToCreateEvent() {
        let experiment = optimizely.config!.getExperiment(key: kExperimentKey)!
        let variation = experiment.getVariation(key: kVariationKey)!
        
        // set invalid (infinity) to attribute values, which will cause JSONEncoder.encode exception
        let attributes = ["testvar": Double.infinity]
        
        optimizely.sendImpressionEvent(experiment: experiment, variation: variation, userId: kUserId, attributes: attributes, flagKey: "", ruleType: Constants.DecisionSource.rollout.rawValue, enabled: true, cmabUUID: nil)
        XCTAssert(eventDispatcher.events.count == 0)
    }
    
    func testSendConversionEvent_FailToCreateEvent() {
        let kEventKey = "event1"
        let kInvalidEventKey = "invalid_key"
        let kUserId = "user"
        
        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        sleep(1)
        XCTAssert(eventDispatcher.events.count == 1)

        optimizely.sendConversionEvent(eventKey: kInvalidEventKey, userId: kUserId)
        sleep(1)
        XCTAssert(eventDispatcher.events.count == 1, "event should not be sent for invalid event key")
        
        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        sleep(1)
        XCTAssert(eventDispatcher.events.count == 2)
    }
    
    func testSendEvent_ConfigNotReady() {
        let experiment = optimizely.config!.getExperiment(key: kExperimentKey)!
        let variation = experiment.getVariation(key: kVariationKey)!
        
        let kEventKey = "event1"
        let kUserId = "user"
        
        // force condition for sdk-not-ready
        optimizely.config = nil
        
        optimizely.sendImpressionEvent(experiment: experiment, variation: variation, userId: kUserId, flagKey: experiment.key, ruleType: Constants.DecisionSource.rollout.rawValue, enabled: true, cmabUUID: nil)
        XCTAssert(eventDispatcher.events.isEmpty, "event should not be sent out sdk is not configured properly")

        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        XCTAssert(eventDispatcher.events.isEmpty, "event should not be sent out sdk is not configured properly")
    }
    
    func testFetchedDatafileInvalid() {
        
        class FakeDatafileHandler: DefaultDatafileHandler {
            override func downloadDatafile(sdkKey: String,
                                           returnCacheIfNoChange: Bool,
                                           resourceTimeoutInterval: Double? = nil,
                                           completionHandler: @escaping DatafileDownloadCompletionHandler) {
                let invalidDatafile = OTUtils.loadJSONDatafile("unsupported_datafile")!
                completionHandler(.success(invalidDatafile))
            }
        }
        
        let handler = FakeDatafileHandler()
        let optimizely = OptimizelyClient(sdkKey: "testFetchedDatafileInvalid",
                                          datafileHandler: handler)
        
        let exp = expectation(description: "a")
        var failureOccured = false
        optimizely.start { result in
            
            if case .failure(OptimizelyError.dataFileVersionInvalid) = result  {
                failureOccured = true
            }
            
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10)
        XCTAssertTrue(failureOccured)
    }
    
    func testHandlerReinitializeOnBackgroundDatafileUpdate() {
        
        // mock background datafile fetch to test handler re-init on datafile update
        
        class FakeDatafileHandler: DefaultDatafileHandler {
            override func startUpdates(sdkKey: String, datafileChangeNotification: ((Data) -> Void)?) {
                let newDatafile = OTUtils.loadJSONDatafile("empty_datafile")!
                datafileChangeNotification?(newDatafile)
            }
        }

        let handler = FakeDatafileHandler()
        let optimizely = OptimizelyClient(sdkKey: "testHandlerReinitializeOnBackgroundDatafileUpdate",
                                          datafileHandler: handler)

        // all handlers before transfer
        
        var handlersForCurrentSdkKey = HandlerRegistryService.shared.binders.property?.keys.filter { $0.sdkKey == "testHandlerReinitializeOnBackgroundDatafileUpdate" }
        let oldHandlersCount = handlersForCurrentSdkKey?.count

        // remove one of the handler to test nil-handlers

        let testKey = handlersForCurrentSdkKey!.filter { $0.service.contains("EventDispatcher")}.first!
        HandlerRegistryService.shared.binders.property?[testKey] = nil
    
        // this will replace config, which will transfer all handlers
        
        try? optimizely.configSDK(datafile: OTUtils.loadJSONDatafile("api_datafile")!)

        // nil handlers must be cleaned up when re-init
        
        handlersForCurrentSdkKey = HandlerRegistryService.shared.binders.property?.keys.filter { $0.sdkKey == "testHandlerReinitializeOnBackgroundDatafileUpdate" }
        let newHandlersCount = handlersForCurrentSdkKey?.count
        
        XCTAssertEqual(newHandlersCount, oldHandlersCount! - 1, "nil handlers should be filtered out")
    }
    
    func testGettingLoggerAfterMultiInit() {
        
        let exp = expectation(description: "a")
        
        _ = OptimizelyClient(sdkKey: "a")
        
        let maxNum = 100
        for i in 0..<maxNum {
            DispatchQueue.global().async {
                if i == 10 {
                    _ = OptimizelyClient(sdkKey: "b")
                }
                for k in 0..<10 {
                    let logger = OPTLoggerFactory.getLogger()
                    logger.log(level: .info, message: "[LOGGER] [\(i)] \(k)")
                }
                if i == maxNum - 1 {
                    exp.fulfill()
                }
            }
            // need to let the main global queue run otherwise some remained queued.
            Thread.sleep(forTimeInterval: 0.02)
        }
        
        wait(for: [exp], timeout: 10)
    }
}
