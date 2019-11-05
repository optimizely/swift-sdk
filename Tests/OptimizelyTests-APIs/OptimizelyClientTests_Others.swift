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

class OptimizelyClientTests_Others: XCTestCase {
    
    let kExperimentKey = "exp_with_audience"
    let kInvalidExperimentKey = "invalid_key"
    let kVariationKey = "a"
    
    let kFeatureKey = "feature_1"
    let kInvalidFeatureKey = "invalid_key"

    let kVariableKeyString = "s_foo"
    let kInvalidVariableKeyString = "invalid_key"

    let kUserId = "user"
    let kNotRealSdkKey = "notrealkey123"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher = MockEventDispatcher()

    override func setUp() {
        super.setUp()
        
        let eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher, batchSize: 1)
        self.optimizely = OTUtils.createOptimizely(datafileName: "api_datafile",
                                                   clearUserProfileService: true,
                                                   eventProcessor: eventProcessor,
                                                   eventDispatcher: nil)!
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

    func testGetFeatureVariableString_InvalidVariableKey() {
        var value = try? optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        XCTAssertNotNil(value)
        
        value = try? optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kInvalidVariableKeyString, userId: kUserId)
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
                                                  clearUserProfileService: true,
                                                  eventProcessor: nil,
                                                  eventDispatcher: nil)!
        
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
    
    func testGetFeatureVariable_MissingDefaultValue() {
        var optimizely = OTUtils.createOptimizely(datafileName: "feature_variables",
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
    
    func testSendImpressionEvent_FailToCreateEvent() {
        let experiment = optimizely.config!.getExperiment(key: kExperimentKey)!
        let variation = experiment.getVariation(key: kVariationKey)!
        
        // set invalid (infinity) to attribute values, which will cause JSONEncoder.encode exception
        let attributes = ["testvar": Double.infinity]
        
        optimizely.sendImpressionEvent(experiment: experiment, variation: variation, userId: kUserId, attributes: attributes)
        optimizely.close()
        
        XCTAssert(eventDispatcher.events.count == 0)
    }
    
    func testSendConversionEvent_FailToCreateEvent() {
        let kEventKey = "event1"
        let kInvalidEventKey = "invalid_key"
        let kUserId = "user"
        
        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        optimizely.eventProcessor?.clear()
        XCTAssertEqual(eventDispatcher.events.count, 1)

        optimizely.sendConversionEvent(eventKey: kInvalidEventKey, userId: kUserId)
        optimizely.eventProcessor?.clear()
        XCTAssertEqual(eventDispatcher.events.count, 1, "event should not be sent for invalid event key")
        
        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        optimizely.eventProcessor?.clear()
        XCTAssertEqual(eventDispatcher.events.count, 2)
    }
    
    func testSendEvent_ConfigNotReady() {
        let experiment = optimizely.config!.getExperiment(key: kExperimentKey)!
        let variation = experiment.getVariation(key: kVariationKey)!
        
        let kEventKey = "event1"
        let kUserId = "user"
        
        // force condition for sdk-not-ready
        optimizely.config = nil
        
        optimizely.sendImpressionEvent(experiment: experiment, variation: variation, userId: kUserId)
        XCTAssert(eventDispatcher.events.isEmpty, "event should not be sent out sdk is not configured properly")

        optimizely.sendConversionEvent(eventKey: kEventKey, userId: kUserId)
        XCTAssert(eventDispatcher.events.isEmpty, "event should not be sent out sdk is not configured properly")
    }
    
    func testFetchedDatafileInvalid() {
        
        class FakeDatafileHandler: DefaultDatafileHandler {
            override func downloadDatafile(sdkKey: String,
                                           resourceTimeoutInterval: Double? = nil,
                                           completionHandler: @escaping DatafileDownloadCompletionHandler) {
                let invalidDatafile = OTUtils.loadJSONDatafile("unsupported_datafile")!
                completionHandler(.success(invalidDatafile))
            }
        }
        
        let handler = FakeDatafileHandler()
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self)
            .sdkKey(key: kNotRealSdkKey)
            .using(instance: handler)
            .to(factory: FakeDatafileHandler.init)
            .reInitializeStrategy(strategy: .reUse)
            .singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: kNotRealSdkKey)
        
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
        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self)
            .sdkKey(key: kNotRealSdkKey)
            .using(instance: handler)
            .to(factory: FakeDatafileHandler.init)
            .reInitializeStrategy(strategy: .reUse)
            .singetlon())

        
        let optimizely = OptimizelyClient(sdkKey: kNotRealSdkKey)

        // all handlers before transfer
        
        var handlersForCurrentSdkKey = HandlerRegistryService.shared.binders.property?.keys.filter { $0.sdkKey == kNotRealSdkKey }
        let oldHandlersCount = handlersForCurrentSdkKey?.count

        // remove one of the handler to test nil-handlers

        let testKey = handlersForCurrentSdkKey!.filter { $0.service.contains("DecisionService") }.first!
        HandlerRegistryService.shared.binders.property?[testKey] = nil
    
        // this will replace config, which will transfer all handlers
        
        try? optimizely.configSDK(datafile: OTUtils.loadJSONDatafile("api_datafile")!)

        // nil handlers must be cleaned up when re-init
        
        handlersForCurrentSdkKey = HandlerRegistryService.shared.binders.property?.keys.filter { $0.sdkKey == kNotRealSdkKey }
        let newHandlersCount = handlersForCurrentSdkKey?.count
        
        XCTAssertEqual(newHandlersCount, oldHandlersCount! - 1, "nil handlers should be filtered out")
    }
    

}
