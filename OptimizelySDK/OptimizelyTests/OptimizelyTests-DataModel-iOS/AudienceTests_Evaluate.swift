//
//  AudienceTests_Evaluate.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/26/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// REF:
// https://docs.google.com/document/d/158_83difXVXF0nb91rxzrfHZwnhsybH21ImRA_si7sg/edit#heading=h.4pg6cutdopxx
// https://github.com/optimizely/objective-c-sdk/blob/master/OptimizelySDKCore/OptimizelySDKCoreTests/OPTLYTypedAudienceTest.m

class AudienceTests_Evaluate: XCTestCase {
    
    // MARK: - Constants
    
    let kAudienceId = "6366023138"
    let kAudienceName = "Android users"
    let kAudienceConditions = "[\"and\", [\"or\", [\"or\", {\"name\": \"device_type\", \"type\": \"custom_attribute\", \"value\": \"iPhone\"}]], [\"or\", [\"or\", {\"name\": \"location\", \"type\": \"custom_attribute\", \"value\": \"San Francisco\"}]], [\"or\", [\"not\", [\"or\", {\"name\": \"browser\", \"type\": \"custom_attribute\", \"value\": \"Firefox\"}]]]]"

    let kAudienceConditionsWithAnd: [Any] = ["and", ["or", ["or", ["name": "device_type", "type": "custom_attribute", "value": "iPhone", "match": "substring"]]],["or", ["or", ["name": "num_users", "type": "custom_attribute", "value": 15, "match": "exact"]]],["or", ["or", ["name": "decimal_value", "type": "custom_attribute", "value": 3.14, "match": "gt"]]]]

    let kAudienceConditionsWithExactMatchStringType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": "firefox", "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchBoolType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": false, "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchDecimalType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 1.5, "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchIntType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "exact"]]]]
    
    let kAudienceConditionsWithExistsMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "match": "exists"]]]]
    
    let kAudienceConditionsWithSubstringMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": "firefox", "match": "substring"]]]]
    
    let kAudienceConditionsWithGreaterThanMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "gt"]]]]

    let kAudienceConditionsWithLessThanMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "lt"]]]]
    
////    let kInfinityIntConditionStr: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": Double.infinity, "match": "exact"]]]]
    let kInfinityIntConditionStr: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": Double.infinity, "match": "exact"]]]]

    // MARK: - Properties
    
    var typedAudienceDatafile: Data!
    var optimizely: OptimizelyManager!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.typedAudienceDatafile = OTUtils.loadJSONDatafileIntoData("typed_audience_datafile")
        self.optimizely = OptimizelyManager(sdkKey: "12345")
        /////       try! self.optimizely.initializeSDK(datafile: typedAudienceDatafile)
    }


    // MARK: - Utils
    
    func makeAudience(conditions: [Any]) -> Audience {
        let fullAudienceData: [String: Any] = ["id": kAudienceId,
                                               "name": kAudienceName,
                                               "conditions": conditions]
        return try! OTUtils.model(from: fullAudienceData)
    }
    
    func makeAudienceLegacy(conditions: String) -> Audience {
        let fullAudienceData: [String: Any] = ["id": kAudienceId,
                                               "name": kAudienceName,
                                               "conditions": conditions]
        return try! OTUtils.model(from: fullAudienceData)
    }

    // MARK: - Tests

    func testEvaluateConditionsMatch() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)

        let attributesPassOrValue = ["device_type" : "iPhone",
                                     "location" : "San Francisco",
                                     "browser" : "Chrome"]
        
        XCTAssertTrue(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testEvaluateConditionsDoNotMatch() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        let attributesPassOrValue = ["device_type" : "iPhone",
                                     "location" : "San Francisco",
                                     "browser" : "Firefox"]
        
        XCTAssertFalse(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }

    func testEvaluateEmptyUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)

        let attributesPassOrValue = [String: String]()
        XCTAssertFalse(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testEvaluateNullUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        XCTAssertFalse(try! audience.evaluate(project: nil, attributes: nil))
    }

    func testTypedUserAttributesEvaluateTrue() {
        let audience = makeAudience(conditions: kAudienceConditionsWithAnd)

        let attributesPassOrValue: [String: Any] = ["device_type" : "iPhone",
                                                    "is_firefox" : false,
                                                    "num_users" : 15,
                                                    "pi_value" : 3.14,
                                                    "decimal_value": 3.15678]
        
        XCTAssertTrue(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }

    func testEvaluateTrueWhenNoUserAttributesAndConditionEvaluatesTrue() {
        //should return true if no attributes are passed and the audience conditions evaluate to true in the absence of attributes
    
        let conditions: [Any] = ["not", ["or", ["or", ["name": "input_value", "type": "custom_attribute", "match": "exists"]]]]
        let audience = makeAudience(conditions: conditions)
        
        XCTAssertTrue(try! audience.evaluate(project: nil, attributes: nil))
    }
    
    // MARK: - Invalid Base Condition Tests
    
    func testEvaluateReturnsNullWithInvalidBaseCondition() {
        // these tests redundant with validation check in the UserAudience model tests
        // TODO: [Jae] confirm: may need for logging checking (Nikhil's doc), not happens because datafile rejected at the beginning

//        let attributesPassOrValue = ["device_type" : "iPhone"]
//
//        var condition = ["name": "device_type"]
//        var userAttribute: UserAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
//
//        condition = ["name": "device_type", "value": "iPhone"]
//        userAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
//
//        condition = ["name": "device_type", "match": "exact"]
//        userAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
//
//        condition = ["name": "device_type", "type": "invalid"]
//        userAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
//
//        condition = ["name": "device_type", "type": "custom_attribute"]
//        userAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }

    //MARK: - Invalid input Tests
    
    func testEvaluateReturnsNullWithInvalidConditionType() {
        // these tests redundant with validation check in the UserAudience model tests
        // TODO: [Jae] confirm: may need for logging checking (Nikhil's doc), not happens because datafile rejected at the beginning

//        let condition = ["name": "device_type",
//                         "value": "iPhone",
//                         "type": "invalid",
//                         "match": "exact"]
//
//        let attributesPassOrValue = ["device_type" : "iPhone"];
//        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
    
    func testEvaluateReturnsNullWithNullValueTypeAndNonExistMatchType() {
        let condition1 = ["name": "device_type",
                          "value": nil,
                          "type": "custom_attribute",
                          "match": "exact"]
        let condition2 = ["name": "device_type",
                          "value": nil,
                          "type": "custom_attribute",
                          "match": "exists"]
        let condition3 = ["name": "device_type",
                          "value": nil,
                          "type": "custom_attribute",
                          "match": "substring"]
        let condition4 = ["name": "device_type",
                          "value": nil,
                          "type": "custom_attribute",
                          "match": "gt"]
        let condition5 = ["name": "device_type",
                          "value": nil,
                          "type": "custom_attribute",
                          "match": "lt"]
        
        let attributesPassOrValue = ["device_type" : "iPhone"]
        
        var userAttribute: UserAttribute = try! OTUtils.model(from: condition1)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
        
        userAttribute = try! OTUtils.model(from: condition2)
        XCTAssertTrue(try! userAttribute.evaluate(attributes: attributesPassOrValue))
        
        userAttribute = try! OTUtils.model(from: condition3)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
        
        userAttribute = try! OTUtils.model(from: condition4)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
        
        userAttribute = try! OTUtils.model(from: condition5)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
        
    func testEvaluateReturnsNullWithInvalidMatchType() {
        // these tests redundant with validation check in the UserAudience model tests
        // TODO: [Jae] confirm: may need for logging checking (Nikhil's doc), not happens because datafile rejected at the beginning

//        let condition = ["name": "device_type",
//                         "value": "iPhone",
//                         "type": "custom_attribute",
//                         "match": "invalid"]
//
//        let attributesPassOrValue = ["device_type" : "iPhone"]
//
//        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }

    func testEvaluateReturnsNullWithInvalidValueForMatchType() {
        let condition: [String: Any] = ["name": "is_firefox",
                                        "value": false,
                                        "type": "custom_attribute",
                                        "match": "substring"]
    
        let attributesPassOrValue = ["is_firefox" : false]
        
        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
    
    //MARK: - ExactMatcher Tests
    
    func testExactMatcherReturnsNullWhenUnsupportedConditionValue() {
        // these tests redundant with validation check in the UserAudience model tests
        // TODO: [Jae] confirm: may need for logging checking (Nikhil's doc), not happens because datafile rejected at the beginning
        
//        let condition: [String: Any] = ["name": "device_type",
//                                        "value": [],
//                                        "type": "custom_attribute",
//                                        "match": "exact"]
//
//        let attributesPassOrValue = ["device_type" : "iPhone"]
//
//        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
//        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
    
    func testExactMatcherReturnsNullWhenNoUserProvidedValue() {
        
        // TODO: [Jae] confirm: it looks like return false is correct behavior. Why ObjC expects nil for these?
        
        let attributesPassOrValue: [String: Any] = [:]
    
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    
        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testExactMatcherReturnsFalseWhenAttributeValueDoesNotMatch() {
        let attributesPassOrValue1 = ["attr_value" : "chrome"]
        let attributesPassOrValue2 = ["attr_value" : true]
        let attributesPassOrValue3 = ["attr_value" : 2.5]
        let attributesPassOrValue4 = ["attr_value" : 55]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
    }
    
    func testExactMatcherReturnsNullWhenTypeMismatch() {
        let attributesPassOrValue1 = ["attr_value" : true]
        let attributesPassOrValue2 = ["attr_value" : "abcd"]
        let attributesPassOrValue3 = ["attr_value" : false]
        let attributesPassOrValue4 = ["attr_value" : "apple"]
        let attributesPassOrValue5 = [String: String]()
        // TODO: [Jae] confirm: filtered by type checking [String: Any], so not valid input
        //let attributesPassOrValue6 = ["attr_value" : nil]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertNil(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue5))
    }
    
    func testExactMatcherReturnsNullWithNumericInfinity() {
        
        // TODO: [Jae] confirm: do we need this inifinite case for Swift?  Not parsed OK (invalid)
        
        let attributesPassOrValue1 = ["attr_value" : Double.infinity]
        let attributesPassOrValue2 = ["attr_value" : 15]
        
        let andCondition1: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try! andCondition1.evaluate(project: nil, attributes: attributesPassOrValue1))
        
        let andCondition2: ConditionHolder = try! OTUtils.model(from: kInfinityIntConditionStr)
        XCTAssertNil(try? andCondition2.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    func testExactMatcherReturnsTrueWhenAttributeValueMatches() {
        let attributesPassOrValue1 = ["attr_value" : "firefox"]
        let attributesPassOrValue2 = ["attr_value" : false]
        let attributesPassOrValue3 = ["attr_value" : 1.5]
        let attributesPassOrValue4 = ["attr_value" : 10]
        let attributesPassOrValue5 = ["attr_value" : 10.0]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue5))
    }
    
    //MARK: - ExistsMatcher Tests
    
    func testExistsMatcherReturnsFalseWhenAttributeIsNotProvided() {
        let attributesPassOrValue = [String: String]()
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
   func testExistsMatcherReturnsFalseWhenAttributeIsNull() {
    
    // TODO: [Jae] confirm: filtered by type checking [String: Any], so not valid input

//        let attributesPassOrValue = ["attr_value" : nil]
//        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
//        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testExistsMatcherReturnsTrueWhenAttributeValueIsProvided() {
        let attributesPassOrValue1 = ["attr_value" : ""]
        let attributesPassOrValue2 = ["attr_value" : "iPhone"]
        let attributesPassOrValue3 = ["attr_value" : 10]
        let attributesPassOrValue4 = ["attr_value" : 10.5]
        let attributesPassOrValue5 = ["attr_value" : false]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue5))
    }
    
    //MARK:- SubstringMatcher Tests
    
    func testSubstringMatcherReturnsNullWhenUnsupportedConditionValue() {
        
        // TODO: [Jae] confirm: filtered by type checking, so not valid UserAttribute

//        let condition: [String: Any] = ["name": "device_type",
//                                        "value": [],
//                                        "type": "custom_attribute",
//                                        "match": "substring"]
//
//        let attributesPassOrValue = ["device_type" : "iPhone"]
//
//        let userAttribute: ConditionHolder = try! OTUtils.model(from: condition)
//        XCTAssertTrue(try! userAttribute.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testSubstringMatcherReturnsFalseWhenConditionValueIsNotSubstringOfUserValue() {
        let attributesPassOrValue = ["attr_value":"Breaking news!"]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testSubstringMatcherReturnsTrueWhenConditionValueIsSubstringOfUserValue() {
        let attributesPassOrValue1 = ["attr_value" : "firefox"]
        let attributesPassOrValue2 = ["attr_value" : "chrome vs firefox"]

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
//
//                                                                                                                                        - (void)testSubstringMatcherReturnsNullWhenAttributeValueIsNotAString {
//                                                                                                                                            NSDictionary *attributesPassOrValue1 = {"attr_value" : 10.5};
//                                                                                                                                            NSDictionary *attributesPassOrValue2 = {"attr_value" : [NSNull null]};
//                                                                                                                                            NSDictionary *attributesPassOrValue3 = {};
//                                                                                                                                            id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                            
//                                                                                                                                            OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithSubstringMatchType]];
//                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue3 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                            OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                            
//                                                                                                                                            NSString *userAttributeClassName = NSStringFromClass([[attributesPassOrValue1 objectForKey:"attr_value"] class]);
//                                                                                                                                            userAttributeClassName = userAttributeClassName;
//                                                                                                                                            NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                            
//                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedTypeNull, [baseCondition toString], baseCondition.name];
//                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                            
//                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForMissingAttribute, [baseCondition toString], baseCondition.name];
//                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                            
//                                                                                                                                            [loggerMock stopMocking];
//                                                                                                                                            }
//                                                                                                                                            
//                                                                                                                                            - (void)testSubstringMatcherReturnsNullWhenAttributeIsNotProvided{
//                                                                                                                                                NSDictionary *attributesPassOrValue = {};
//                                                                                                                                                id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithSubstringMatchType]];
//                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                                NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForMissingAttribute, [baseCondition toString], baseCondition.name];
//                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                [loggerMock stopMocking];
//                                                                                                                                                }
//                                                                                                                                                
//                                                                                                                                                ///MARK:- GTMatcher Tests
//                                                                                                                                                
//                                                                                                                                                - (void)testGTMatcherReturnsNullWhenUnsupportedConditionValue {
//                                                                                                                                                    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                    NSDictionary *attributesPassOrValue1 = {"name": "device_type",
//                                                                                                                                                        "value": {},
//                                                                                                                                                        "type": "custom_attribute",
//                                                                                                                                                        "match": "gt"};
//                                                                                                                                                    
//                                                                                                                                                    NSDictionary *userAttributes = {"device_type" : "iPhone"};
//                                                                                                                                                    OPTLYBaseCondition *condition = [[OPTLYBaseCondition alloc] initWithDictionary:attributesPassOrValue1 error:nil];
//                                                                                                                                                    XCTAssertNil([condition evaluateConditionsWithAttributes:userAttributes projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                    NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorUnsupportedValueType, [condition toString]];
//                                                                                                                                                    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                    [loggerMock stopMocking];
//                                                                                                                                                    }
//                                                                                                                                                    
//                                                                                                                                                    - (void)testGTMatcherReturnsFalseWhenAttributeValueIsLessThanOrEqualToConditionValue {
//                                                                                                                                                        NSDictionary *attributesPassOrValue1 = {"attr_value" : 5};
//                                                                                                                                                        NSDictionary *attributesPassOrValue2 = {"attr_value" : 10};
//                                                                                                                                                        NSDictionary *attributesPassOrValue3 = {"attr_value" : 10.0};
//                                                                                                                                                        
//                                                                                                                                                        OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithGreaterThanMatchType]];
//                                                                                                                                                        XCTAssertFalse([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:nil] boolValue]);
//                                                                                                                                                        XCTAssertFalse([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:nil] boolValue]);
//                                                                                                                                                        XCTAssertFalse([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue3 projectConfig:nil] boolValue]);
//                                                                                                                                                        }
//                                                                                                                                                        
//                                                                                                                                                        - (void)testGTMatcherReturnsNullWhenAttributeValueIsNotANumericValue {
//                                                                                                                                                            id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                            NSDictionary *attributesPassOrValue1 = {"attr_value" : "invalid"};
//                                                                                                                                                            NSDictionary *attributesPassOrValue2 = {};
//                                                                                                                                                            NSDictionary *attributesPassOrValue3 = {"attr_value" : YES};
//                                                                                                                                                            NSDictionary *attributesPassOrValue4 = {"attr_value" : NO};
//                                                                                                                                                            NSDictionary *attributesPassOrValue5 = {"attr_value" : [NSNull null]};
//                                                                                                                                                            
//                                                                                                                                                            OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithGreaterThanMatchType]];
//                                                                                                                                                            OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                            NSString *userAttributeClassName = NSStringFromClass([[attributesPassOrValue1 objectForKey:"attr_value"] class]);
//                                                                                                                                                            userAttributeClassName = userAttributeClassName;
//                                                                                                                                                            NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                            
//                                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForMissingAttribute, [baseCondition toString], baseCondition.name];
//                                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                            
//                                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue3 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                            userAttributeClassName = NSStringFromClass([[attributesPassOrValue3 objectForKey:"attr_value"] class]);
//                                                                                                                                                            userAttributeClassName = userAttributeClassName;
//                                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                            
//                                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue4 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                            userAttributeClassName = NSStringFromClass([[attributesPassOrValue4 objectForKey:"attr_value"] class]);
//                                                                                                                                                            userAttributeClassName = userAttributeClassName;
//                                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                            
//                                                                                                                                                            XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue5 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                            logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedTypeNull, [baseCondition toString], baseCondition.name];
//                                                                                                                                                            OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                            
//                                                                                                                                                            [loggerMock stopMocking];
//                                                                                                                                                            }
//                                                                                                                                                            
//                                                                                                                                                            - (void)testGTMatcherReturnsNullWhenAttributeValueIsInfinity {
//                                                                                                                                                                id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                                NSDictionary *attributesPassOrValue = {"attr_value" : [NSNumber numberWithFloat:INFINITY]};
//                                                                                                                                                                OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithGreaterThanMatchType]];
//                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                
//                                                                                                                                                                OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                                                NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedTypeNanInfinity, [baseCondition toString], baseCondition.name];
//                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                                [loggerMock stopMocking];
//                                                                                                                                                                }
//                                                                                                                                                                
//                                                                                                                                                                - (void)testGTMatcherReturnsTrueWhenAttributeValueIsGreaterThanConditionValue {
//                                                                                                                                                                    NSDictionary *attributesPassOrValue1 = {"attr_value" : 15};
//                                                                                                                                                                    NSDictionary *attributesPassOrValue2 = {"attr_value" : 10.1};
//                                                                                                                                                                    
//                                                                                                                                                                    OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithGreaterThanMatchType]];
//                                                                                                                                                                    XCTAssertTrue([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:nil] boolValue]);
//                                                                                                                                                                    XCTAssertTrue([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:nil] boolValue]);
//                                                                                                                                                                    }
//                                                                                                                                                                    
//                                                                                                                                                                    ///MARK:- LTMatcher Tests
//                                                                                                                                                                    
//                                                                                                                                                                    - (void)testLTMatcherReturnsNullWhenUnsupportedConditionValue {
//                                                                                                                                                                        id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                                        NSDictionary *attributesPassOrValue1 = {"name": "device_type",
//                                                                                                                                                                            "value": {},
//                                                                                                                                                                            "type": "custom_attribute",
//                                                                                                                                                                            "match": "lt"};
//                                                                                                                                                                        
//                                                                                                                                                                        NSDictionary *userAttributes = {"device_type" : "iPhone"};
//                                                                                                                                                                        OPTLYBaseCondition *condition = [[OPTLYBaseCondition alloc] initWithDictionary:attributesPassOrValue1 error:nil];
//                                                                                                                                                                        XCTAssertNil([condition evaluateConditionsWithAttributes:userAttributes projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorUnsupportedValueType, [condition toString]];
//                                                                                                                                                                        OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                                        [loggerMock stopMocking];
//                                                                                                                                                                        }
//                                                                                                                                                                        
//                                                                                                                                                                        - (void)testLTMatcherReturnsFalseWhenAttributeValueIsGreaterThanOrEqualToConditionValue {
//                                                                                                                                                                            NSDictionary *attributesPassOrValue1 = {"attr_value" : 15};
//                                                                                                                                                                            NSDictionary *attributesPassOrValue2 = {"attr_value" : 10};
//                                                                                                                                                                            
//                                                                                                                                                                            OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithLessThanMatchType]];
//                                                                                                                                                                            XCTAssertFalse([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:nil] boolValue]);
//                                                                                                                                                                            XCTAssertFalse([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:nil] boolValue]);
//                                                                                                                                                                            }
//                                                                                                                                                                            
//                                                                                                                                                                            - (void)testLTMatcherReturnsNullWhenAttributeValueIsNotANumericValue {
//                                                                                                                                                                                NSDictionary *attributesPassOrValue1 = {"attr_value" : "invalid"};
//                                                                                                                                                                                NSDictionary *attributesPassOrValue2 = {};
//                                                                                                                                                                                NSDictionary *attributesPassOrValue3 = {"attr_value" : YES};
//                                                                                                                                                                                NSDictionary *attributesPassOrValue4 = {"attr_value" : NO};
//                                                                                                                                                                                NSDictionary *attributesPassOrValue5 = {"attr_value" : [NSNull null]};
//                                                                                                                                                                                id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                                                
//                                                                                                                                                                                OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithLessThanMatchType]];
//                                                                                                                                                                                OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                                                                
//                                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                NSString *userAttributeClassName = NSStringFromClass([[attributesPassOrValue1 objectForKey:"attr_value"] class]);
//                                                                                                                                                                                userAttributeClassName = userAttributeClassName;
//                                                                                                                                                                                NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                                                
//                                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForMissingAttribute, [baseCondition toString], baseCondition.name];
//                                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                                                
//                                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue3 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                userAttributeClassName = NSStringFromClass([[attributesPassOrValue3 objectForKey:"attr_value"] class]);
//                                                                                                                                                                                userAttributeClassName = userAttributeClassName;
//                                                                                                                                                                                logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                                                
//                                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue4 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                userAttributeClassName = NSStringFromClass([[attributesPassOrValue4 objectForKey:"attr_value"] class]);
//                                                                                                                                                                                userAttributeClassName = userAttributeClassName;
//                                                                                                                                                                                logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedType, [baseCondition toString], userAttributeClassName, baseCondition.name];
//                                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelWarning]);
//                                                                                                                                                                                
//                                                                                                                                                                                XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue5 projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedTypeNull, [baseCondition toString], baseCondition.name];
//                                                                                                                                                                                OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                                                
//                                                                                                                                                                                [loggerMock stopMocking];
//                                                                                                                                                                                }
//                                                                                                                                                                                
//                                                                                                                                                                                - (void)testLTMatcherReturnsNullWhenAttributeValueIsInfinity {
//                                                                                                                                                                                    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//                                                                                                                                                                                    NSDictionary *attributesPassOrValue = {"attr_value" : [NSNumber numberWithFloat:INFINITY]};
//                                                                                                                                                                                    
//                                                                                                                                                                                    OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithLessThanMatchType]];
//                                                                                                                                                                                    OPTLYBaseCondition *baseCondition = (OPTLYBaseCondition *)[((OPTLYOrCondition *)[((OPTLYOrCondition *)[andCondition.subConditions firstObject]).subConditions firstObject]).subConditions firstObject];
//                                                                                                                                                                                    XCTAssertNil([andCondition evaluateConditionsWithAttributes:attributesPassOrValue projectConfig:self.optimizelyTypedAudience.config]);
//                                                                                                                                                                                    NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorConditionEvaluatedAsUnknownForUnexpectedTypeNanInfinity, [baseCondition toString], baseCondition.name];
//                                                                                                                                                                                    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//                                                                                                                                                                                    [loggerMock stopMocking];
//                                                                                                                                                                                    }
//                                                                                                                                                                                    
//                                                                                                                                                                                    - (void)testLTMatcherReturnsTrueWhenAttributeValueIsLessThanConditionValue {
//                                                                                                                                                                                        NSDictionary *attributesPassOrValue1 = {"attr_value" : 5};
//                                                                                                                                                                                        NSDictionary *attributesPassOrValue2 = {"attr_value" : 9.9};
//                                                                                                                                                                                        
//                                                                                                                                                                                        OPTLYAndCondition *andCondition = (OPTLYAndCondition *)[self getFirstConditionFromArray:[self kAudienceConditionsWithLessThanMatchType]];
//                                                                                                                                                                                        XCTAssertTrue([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue1 projectConfig:nil] boolValue]);
//                                                                                                                                                                                        XCTAssertTrue([[andCondition evaluateConditionsWithAttributes:attributesPassOrValue2 projectConfig:nil] boolValue]);
//                                                                                                                                                                                        }
//                                                                                                                                                                                        
//                                                                                                                                                                                        ///MARK:- Helper Methods
//                                                                                                                                                                                        
//                                                                                                                                                                                        - (OPTLYCondition *)getFirstConditionFromArray:(NSArray *)array {
//                                                                                                                                                                                            NSArray *conditionArray = [OPTLYCondition deserializeJSON:array];
//                                                                                                                                                                                            return conditionArray[0];
//}
//
//end

}
