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
        
        let attributes = ["device_type": "iPhone",
                          "location": "San Francisco",
                          "browser": "Chrome"]
        
        XCTAssertTrue(try! audience.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testEvaluateConditionsDoNotMatch() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        let attributes = ["device_type": "iPhone",
                          "location": "San Francisco",
                          "browser": "Firefox"]
        
        XCTAssertFalse(try! audience.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testEvaluateSingleLeaf() {
        let config = self.optimizely.config
        
        let holder = ConditionHolder.array([ConditionHolder.leaf(ConditionLeaf.audienceId("3468206642"))])
        
        let attributes = ["house": "Gryffindor"]
        
        let bool = try? holder.evaluate(project: config?.project, user: OTUtils.user(attributes: attributes))
        
        XCTAssertTrue(bool!)
    }
    
    func testEvaluateEmptyUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)

        let attributes = [String: String]()
        XCTAssertNil(try? audience.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testEvaluateNullUserAttributes() {
        let audience = makeAudienceLegacy(conditions: kAudienceConditions)
        
        XCTAssertNil(try? audience.evaluate(project: nil, user: OTUtils.user(attributes: nil)))
    }

    func testTypedUserAttributesEvaluateTrue() {
        let audience = makeAudience(conditions: kAudienceConditionsWithAnd)

        let attributes: [String: Any] = ["device_type": "iPhone",
                                                    "is_firefox": false,
                                                    "num_users": 15,
                                                    "pi_value": 3.14,
                                                    "decimal_value": 3.15678]
        
        XCTAssertTrue(try! audience.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }

    func testEvaluateTrueWhenNoUserAttributesAndConditionEvaluatesTrue() {
        //should return true if no attributes are passed and the audience conditions evaluate to true in the absence of attributes
    
        let conditions: [Any] = ["not", ["or", ["or", ["name": "input_value", "type": "custom_attribute", "match": "exists"]]]]
        let audience = makeAudience(conditions: conditions)
        
        XCTAssertTrue(try! audience.evaluate(project: nil, user: OTUtils.user(attributes: nil)))
    }
    
    // MARK: - Invalid Base Condition Tests
    
    func testEvaluateReturnsNullWithInvalidBaseCondition() {
        let attributes = ["device_type": "iPhone"]

        var condition = ["name": "device_type"]
        var userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))

        condition = ["name": "device_type", "value": "iPhone"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))

        condition = ["name": "device_type", "match": "exact"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))

        condition = ["name": "device_type", "type": "invalid"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))

        condition = ["name": "device_type", "type": "custom_attribute"]
        userAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
    }

    // MARK: - Invalid input Tests
    
    func testEvaluateReturnsNullWithInvalidConditionType() {
        let condition = ["name": "device_type",
                         "value": "iPhone",
                         "type": "invalid",
                         "match": "exact"]

        let attributes = ["device_type": "iPhone"]
        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
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
        
        let attributes = ["device_type": "iPhone"]
        
        var userAttribute: UserAttribute = try! OTUtils.model(from: condition1)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
        
        userAttribute = try! OTUtils.model(from: condition2)
        XCTAssertTrue(try! userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
        
        userAttribute = try! OTUtils.model(from: condition3)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
        
        userAttribute = try! OTUtils.model(from: condition4)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
        
        userAttribute = try! OTUtils.model(from: condition5)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
    }
        
    func testEvaluateReturnsNullWithInvalidMatchType() {
        let condition = ["name": "device_type",
                         "value": "iPhone",
                         "type": "custom_attribute",
                         "match": "invalid"]

        let attributes = ["device_type": "iPhone"]

        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
    }

    func testEvaluateReturnsNullWithInvalidValueForMatchType() {
        let condition: [String: Any] = ["name": "is_firefox",
                                        "value": false,
                                        "type": "custom_attribute",
                                        "match": "substring"]
    
        let attributes = ["is_firefox": false]
        
        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
    }
    
    // MARK: - ExactMatcher Tests
    
    func testExactMatcherReturnsNullWhenUnsupportedConditionValue() {
        let condition: [String: Any] = ["name": "device_type",
                                        "value": [],
                                        "type": "custom_attribute",
                                        "match": "exact"]

        let attributes = ["device_type": "iPhone"]

        let userAttribute: UserAttribute = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(user: OTUtils.user(attributes: attributes)))
    }
    
    func testExactMatcherReturnsNullWhenNoUserProvidedValue() {
        let attributes: [String: Any] = [:]
    
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    
        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testExactMatcherReturnsFalseWhenAttributeValueDoesNotMatch() {
        let attributes1 = ["attr_value": "chrome"]
        let attributes2 = ["attr_value": true]
        let attributes3 = ["attr_value": 2.5]
        let attributes4 = ["attr_value": 55]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))
    }
    
    func testExactMatcherReturnsNullWhenTypeMismatch() {
        let attributes1 = ["attr_value": true]
        let attributes2 = ["attr_value": "abcd"]
        let attributes3 = ["attr_value": false]
        let attributes4 = ["attr_value": "apple"]
        let attributes5 = [String: String]()
        //let attributes6 = ["attr_value" : nil]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes5)))
    }
    
    func testExactMatcherReturnsNullWithNumericInfinity() {
        
        // TODO: [Jae] confirm: do we need this inifinite case for Swift?  Not parsed OK (invalid)
        
        let attributes = ["attr_value": Double.infinity]
        
        let andCondition1: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertNil(try? andCondition1.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))

    }
    
    func testExactMatcherReturnsTrueWhenAttributeValueMatches() {
        let attributes1 = ["attr_value": "firefox"]
        let attributes2 = ["attr_value": false]
        let attributes3 = ["attr_value": 1.5]
        let attributes4 = ["attr_value": 10]
        let attributes5 = ["attr_value": 10.0]
        
        var conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchStringType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchBoolType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchDecimalType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))

        conditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExactMatchIntType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes5)))
    }
    
    // MARK: - ExistsMatcher Tests
    
    func testExistsMatcherReturnsFalseWhenAttributeIsNotProvided() {
        let attributes = [String: String]()
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
   func testExistsMatcherReturnsFalseWhenAttributeIsNull() {
    let attributes: [String: Any?] = ["attr_value": nil]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }

    func testExistsMatcherReturnsFalseWhenAttributeIsNSNull() {
        let attributes: [String: Any?] = ["attr_value": NSNull()]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }

    func testExistsMatcherReturnsTrueWhenAttributeValueIsProvided() {
        let attributes1 = ["attr_value": ""]
        let attributes2 = ["attr_value": "iPhone"]
        let attributes3 = ["attr_value": 10]
        let attributes4 = ["attr_value": 10.5]
        let attributes5 = ["attr_value": false]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithExistsMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes5)))
    }
    
    // MARK: - SubstringMatcher Tests
    
    func testSubstringMatcherReturnsNullWhenUnsupportedConditionValue() {
        let condition: [String: Any] = ["name": "device_type",
                                        "value": [],
                                        "type": "custom_attribute",
                                        "match": "substring"]

        let attributes = ["device_type": "iPhone"]

        let userAttribute: ConditionHolder = try! OTUtils.model(from: condition)
        XCTAssertNil(try? userAttribute.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testSubstringMatcherReturnsFalseWhenConditionValueIsNotSubstringOfUserValue() {
        let attributes = ["attr_value": "Breaking news!"]
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testSubstringMatcherReturnsTrueWhenConditionValueIsSubstringOfUserValue() {
        let attributes1 = ["attr_value": "firefox"]
        let attributes2 = ["attr_value": "chrome vs firefox"]

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
    func testSubstringMatcherReturnsNullWhenAttributeValueIsNotAString() {
        let attributes1 = ["attr_value": 10.5]
        let attributes2: [String: Any?] = ["attr_value": nil]

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
    func testSubstringMatcherReturnsNullWhenAttributeIsNotProvided() {
        let attributes1: [String: Any] = [:]
        let attributes2: [String: Any]? = nil

        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithSubstringMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
    // MARK: - GTMatcher Tests
    
    func testGTMatcherReturnsFalseWhenAttributeValueIsLessThanOrEqualToConditionValue() {
        let attributes1 = ["attr_value": 5]
        let attributes2 = ["attr_value": 10]
        let attributes3 = ["attr_value": 10.0]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))
    }
    
    func testGTMatcherReturnsNullWhenAttributeValueIsNotANumericValue() {
        let attributes1 = ["attr_value": "invalid"]
        let attributes2 = [String: String]()
        let attributes3 = ["attr_value": true]
        let attributes4 = ["attr_value": false]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))
    }
    
    func testGTMatcherReturnsNullWhenAttributeValueIsInfinity() {
        let attributes = ["attr_value": Double.infinity]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testGTMatcherReturnsTrueWhenAttributeValueIsGreaterThanConditionValue() {
        let attributes1 = ["attr_value": 15]
        let attributes2 = ["attr_value": 10.1]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithGreaterThanMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
    // MARK: - LTMatcher Tests
    
    func testLTMatcherReturnsFalseWhenAttributeValueIsGreaterThanOrEqualToConditionValue() {
        let attributes1 = ["attr_value": 15]
        let attributes2 = ["attr_value": 10]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertFalse(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
    func testLTMatcherReturnsNullWhenAttributeValueIsNotANumericValue() {
        let attributes1 = ["attr_value": "invalid"]
        let attributes2 = [String: String]()
        let attributes3 = ["attr_value": true]
        let attributes4 = ["attr_value": false]
        
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes3)))
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes4)))
    }
    
    func testLTMatcherReturnsNullWhenAttributeValueIsInfinity() {
        let attributes = ["attr_value": Double.infinity]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertNil(try? conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes)))
    }
    
    func testLTMatcherReturnsTrueWhenAttributeValueIsLessThanConditionValue() {
        let attributes1 = ["attr_value": 5]
        let attributes2 = ["attr_value": 9.9]
    
        let conditionHolder: ConditionHolder = try! OTUtils.model(from: kAudienceConditionsWithLessThanMatchType)
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes1)))
        XCTAssertTrue(try! conditionHolder.evaluate(project: nil, user: OTUtils.user(attributes: attributes2)))
    }
    
}
