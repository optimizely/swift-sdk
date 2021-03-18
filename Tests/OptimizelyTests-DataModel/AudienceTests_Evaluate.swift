//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

// REF:
// https://docs.google.com/document/d/158_83difXVXF0nb91rxzrfHZwnhsybH21ImRA_si7sg/edit#heading=h.4pg6cutdopxx
// https://github.com/optimizely/objective-c-sdk/blob/master/OptimizelySDKCore/OptimizelySDKCoreTests/OPTLYTypedAudienceTest.m

class AudienceTests_Evaluate: XCTestCase {
    
    // MARK: - Constants
    
    let kAudienceId = "6366023138"
    let kAudienceName = "Android users"
    let kAudienceConditions = "[\"and\", [\"or\", [\"or\", {\"name\": \"device_type\", \"type\": \"custom_attribute\", \"value\": \"iPhone\"}]], [\"or\", [\"or\", {\"name\": \"location\", \"type\": \"custom_attribute\", \"value\": \"San Francisco\"}]], [\"or\", [\"not\", [\"or\", {\"name\": \"browser\", \"type\": \"custom_attribute\", \"value\": \"Firefox\"}]]]]"

    let kAudienceConditionsWithAnd: [Any] = ["and", ["or", ["or", ["name": "device_type", "type": "custom_attribute", "value": "iPhone", "match": "substring"]]], ["or", ["or", ["name": "num_users", "type": "custom_attribute", "value": 15, "match": "exact"]]], ["or", ["or", ["name": "decimal_value", "type": "custom_attribute", "value": 3.14, "match": "gt"]]]]

    let kAudienceConditionsWithExactMatchStringType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": "firefox", "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchBoolType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": false, "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchDecimalType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 1.5, "match": "exact"]]]]

    let kAudienceConditionsWithExactMatchIntType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "exact"]]]]
    
    let kAudienceConditionsWithExistsMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "match": "exists"]]]]
    
    let kAudienceConditionsWithSubstringMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": "firefox", "match": "substring"]]]]
    
    let kAudienceConditionsWithGreaterThanMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "gt"]]]]

    let kAudienceConditionsWithLessThanMatchType: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": 10, "match": "lt"]]]]
    
    let kInfinityIntConditionStr: [Any] = ["and", ["or", ["or", ["name": "attr_value", "type": "custom_attribute", "value": Double.infinity, "match": "exact"]]]]

    // MARK: - Properties
    
    var typedAudienceDatafile: Data!
    var optimizely: OptimizelyClient!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.typedAudienceDatafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        self.optimizely = OptimizelyClient(sdkKey: "12345")
        try! self.optimizely.start(datafile: typedAudienceDatafile)
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

        let attributesPassOrValue = ["device_type": "iPhone",
                                     "location": "San Francisco",
                                     "browser": "Chrome"]
        
        XCTAssertTrue(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testEvaluateConditionsDoNotMatch() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        let attributesPassOrValue = ["device_type": "iPhone",
                                     "location": "San Francisco",
                                     "browser": "Firefox"]
        
        XCTAssertFalse(try! audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }

    func testEvaluateSingleLeaf() {
        let config = self.optimizely.config
        
        let holder = ConditionHolder.array([ConditionHolder.leaf(ConditionLeaf.audienceId("3468206642"))])
        
        let attributes = ["house": "Gryffindor"]
        
        let bool = try? holder.evaluate(project: config?.project, attributes: attributes)
        
        XCTAssertTrue(bool!)
    }
    
    func testEvaluateEmptyUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)

        let attributesPassOrValue = [String: String]()
        XCTAssertNil(try? audience.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testEvaluateNullUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        XCTAssertNil(try? audience.evaluate(project: nil, attributes: nil))
    }

    func testTypedUserAttributesEvaluateTrue() {
        let audience = makeAudience(conditions: kAudienceConditionsWithAnd)

        let attributesPassOrValue: [String: Any] = ["device_type": "iPhone",
                                                    "is_firefox": false,
                                                    "num_users": 15,
                                                    "pi_value": 3.14,
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
        let attributesPassOrValue = ["device_type": "iPhone"]

        var condition = ["name": "device_type"]
        var userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))

        condition = ["name": "device_type", "value": "iPhone"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))

        condition = ["name": "device_type", "match": "exact"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))

        condition = ["name": "device_type", "type": "invalid"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))

        condition = ["name": "device_type", "type": "custom_attribute"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }

    // MARK: - Invalid input Tests
    
    func testEvaluateReturnsNullWithInvalidConditionType() {
        let condition = ["name": "device_type",
                         "value": "iPhone",
                         "type": "invalid",
                         "match": "exact"]

        let attributesPassOrValue = ["device_type": "iPhone"]
        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
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
        
        let attributesPassOrValue = ["device_type": "iPhone"]
        
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
        let condition = ["name": "device_type",
                         "value": "iPhone",
                         "type": "custom_attribute",
                         "match": "invalid"]

        let attributesPassOrValue = ["device_type": "iPhone"]

        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }

    func testEvaluateReturnsNullWithInvalidValueForMatchType() {
        let condition: [String: Any] = ["name": "is_firefox",
                                        "value": false,
                                        "type": "custom_attribute",
                                        "match": "substring"]
    
        let attributesPassOrValue = ["is_firefox": false]
        
        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
    
    // MARK: - ExactMatcher Tests
    
    func testExactMatcherReturnsNullWhenUnsupportedConditionValue() {
        let condition: [String: Any] = ["name": "device_type",
                                        "value": [],
                                        "type": "custom_attribute",
                                        "match": "exact"]

        let attributesPassOrValue = ["device_type": "iPhone"]

        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(attributes: attributesPassOrValue))
    }
    
    func testExactMatcherReturnsNullWhenNoUserProvidedValue() {
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
        let attributesPassOrValue1 = ["attr_value": "chrome"]
        let attributesPassOrValue2 = ["attr_value": true]
        let attributesPassOrValue3 = ["attr_value": 2.5]
        let attributesPassOrValue4 = ["attr_value": 55]
        
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
        let attributesPassOrValue1 = ["attr_value": true]
        let attributesPassOrValue2 = ["attr_value": "abcd"]
        let attributesPassOrValue3 = ["attr_value": false]
        let attributesPassOrValue4 = ["attr_value": "apple"]
        let attributesPassOrValue5 = [String: String]()
        //let attributesPassOrValue6 = ["attr_value" : nil]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue5))
    }
    
    func testExactMatcherReturnsNullWithNumericInfinity() {
        
        // TODO: [Jae] confirm: do we need this inifinite case for Swift?  Not parsed OK (invalid)
        
        let attributesPassOrValue1 = ["attr_value": Double.infinity]
        
        let andCondition1: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? andCondition1.evaluate(project: nil, attributes: attributesPassOrValue1))

    }
    
    func testExactMatcherReturnsTrueWhenAttributeValueMatches() {
        let attributesPassOrValue1 = ["attr_value": "firefox"]
        let attributesPassOrValue2 = ["attr_value": false]
        let attributesPassOrValue3 = ["attr_value": 1.5]
        let attributesPassOrValue4 = ["attr_value": 10]
        let attributesPassOrValue5 = ["attr_value": 10.0]
        
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
    
    // MARK: - ExistsMatcher Tests
    
    func testExistsMatcherReturnsFalseWhenAttributeIsNotProvided() {
        let attributesPassOrValue = [String: String]()
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
   func testExistsMatcherReturnsFalseWhenAttributeIsNull() {
    let attributesPassOrValue: [String: Any?] = ["attr_value": nil]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }

    func testExistsMatcherReturnsFalseWhenAttributeIsNSNull() {
        let attributesPassOrValue: [String: Any?] = ["attr_value": NSNull()]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }

    func testExistsMatcherReturnsTrueWhenAttributeValueIsProvided() {
        let attributesPassOrValue1 = ["attr_value": ""]
        let attributesPassOrValue2 = ["attr_value": "iPhone"]
        let attributesPassOrValue3 = ["attr_value": 10]
        let attributesPassOrValue4 = ["attr_value": 10.5]
        let attributesPassOrValue5 = ["attr_value": false]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue5))
    }
    
    // MARK: - SubstringMatcher Tests
    
    func testSubstringMatcherReturnsNullWhenUnsupportedConditionValue() {
        let condition: [String: Any] = ["name": "device_type",
                                        "value": [],
                                        "type": "custom_attribute",
                                        "match": "substring"]

        let attributesPassOrValue = ["device_type": "iPhone"]

        let userAttribute: ConditionHolder = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testSubstringMatcherReturnsFalseWhenConditionValueIsNotSubstringOfUserValue() {
        let attributesPassOrValue = ["attr_value": "Breaking news!"]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testSubstringMatcherReturnsTrueWhenConditionValueIsSubstringOfUserValue() {
        let attributesPassOrValue1 = ["attr_value": "firefox"]
        let attributesPassOrValue2 = ["attr_value": "chrome vs firefox"]

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    func testSubstringMatcherReturnsNullWhenAttributeValueIsNotAString() {
        let attributesPassOrValue1 = ["attr_value": 10.5]
        let attributesPassOrValue2: [String: Any?] = ["attr_value": nil]

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    func testSubstringMatcherReturnsNullWhenAttributeIsNotProvided() {
        let attributesPassOrValue1: [String: Any] = [:]
        let attributesPassOrValue2: [String: Any]? = nil

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    // MARK: - GTMatcher Tests
    
    func testGTMatcherReturnsFalseWhenAttributeValueIsLessThanOrEqualToConditionValue() {
        let attributesPassOrValue1 = ["attr_value": 5]
        let attributesPassOrValue2 = ["attr_value": 10]
        let attributesPassOrValue3 = ["attr_value": 10.0]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))
    }
    
    func testGTMatcherReturnsNullWhenAttributeValueIsNotANumericValue() {
        let attributesPassOrValue1 = ["attr_value": "invalid"]
        let attributesPassOrValue2 = [String: String]()
        let attributesPassOrValue3 = ["attr_value": true]
        let attributesPassOrValue4 = ["attr_value": false]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
    }
    
    func testGTMatcherReturnsNullWhenAttributeValueIsInfinity() {
        let attributesPassOrValue = ["attr_value": Double.infinity]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testGTMatcherReturnsTrueWhenAttributeValueIsGreaterThanConditionValue() {
        let attributesPassOrValue1 = ["attr_value": 15]
        let attributesPassOrValue2 = ["attr_value": 10.1]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    // MARK: - LTMatcher Tests
    
    func testLTMatcherReturnsFalseWhenAttributeValueIsGreaterThanOrEqualToConditionValue() {
        let attributesPassOrValue1 = ["attr_value": 15]
        let attributesPassOrValue2 = ["attr_value": 10]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
    func testLTMatcherReturnsNullWhenAttributeValueIsNotANumericValue() {
        let attributesPassOrValue1 = ["attr_value": "invalid"]
        let attributesPassOrValue2 = [String: String]()
        let attributesPassOrValue3 = ["attr_value": true]
        let attributesPassOrValue4 = ["attr_value": false]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue3))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue4))
    }
    
    func testLTMatcherReturnsNullWhenAttributeValueIsInfinity() {
        let attributesPassOrValue = ["attr_value": Double.infinity]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue))
    }
    
    func testLTMatcherReturnsTrueWhenAttributeValueIsLessThanConditionValue() {
        let attributesPassOrValue1 = ["attr_value": 5]
        let attributesPassOrValue2 = ["attr_value": 9.9]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue1))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, attributes: attributesPassOrValue2))
    }
    
}
