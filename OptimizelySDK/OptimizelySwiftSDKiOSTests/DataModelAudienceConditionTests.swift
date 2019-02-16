//
//  DataModelConditionHolderTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest


/* Test combinations
 
 // single UserAttribute
 
 I = audienceId
 U = userAttribute
 A = "and"
 0 = "or"
 N = "not"
 
 // [and/or/not, AudienceId]
 
 AI = ["and", I]
 OI = ["or", I]
 NI = ["not", I]
 
 // [and/or/not, UserAttribute]
 
 AU = ["and", U]
 OU = ["or", U]
 NU = ["not", U]
 
 // [and/or/not, [and/or/not, UserAttribute]]
 
 A.AI = ["and", AI]
 A.OI = ["and", OI]
 A.NI = ["and", NI]
 
 O.AI = ["or", AI]
 O.OI = ["or", OI]
 O.NI = ["or", NI]
 
 N.AI = ["not", AI]
 N.OI = ["not", OI]
 N.NI = ["not", NI]
 
 // [and/or/not, [and/or/not, UserAttribute], [and/or/not, UserAttribute]]
 
 A.AI.AI = ["and", AI, AI]
 A.AI.OI = ["and", AI, OI]
 A.AI.NI = ["and", AI, NI]
 O.AI.AI = ["or", AI, AI]
 O.AI.OI = ["or", AI, OI]
 O.AI.NI = ["or", AI, NI]
 
 A.OI.AI = ["and", OI, AI]
 A.OI.OI = ["and", OI, OI]
 A.OI.NI = ["and", OI, NI]
 O.OI.AI = ["or", OI, AI]
 O.OI.OI = ["or", OI, OI]
 O.OI.NI = ["or", OI, NI]
 
 A.NI.AI = ["and", NI, AI]
 A.NI.OI = ["and", NI, OI]
 A.NI.NI = ["and", NI, NI]
 O.NI.AI = ["or", NI, AI]
 O.NI.OI = ["or", NI, OI]
 O.NI.NI = ["or", NI, NI]
 
 // [and/or/not, UserAttribute, [and/or/not, UserAttribute]]
 
 A.UA.AI = ["and", UA, AI]
 A.UA.OI = ["and", UA, OI]
 A.UA.NI = ["and", UA, NI]
 O.UA.AI = ["or", UA, AI]
 O.UA.OI = ["or", UA, OI]
 O.UA.NI = ["or", UA, NI]
 
 A.AI.UA = ["and", AI, UA]
 A.OI.UA = ["and", OI, UA]
 A.NI.UA = ["and", NI, UA]
 O.AI.UA = ["or", AI, UA]
 O.OI.UA = ["or", OI, UA]
 O.NI.UA = ["or", NI, UA]
 
 // [and/or/not, [and/or/not, UserAttribute, [and/or/not, UserAttribute], [and/or/not, UserAttribute]]
 
 Complex1 = ["and", A.UA.AI, AI]
 Complex2 = ["or", A.UA.AI, O.UA.AI]
 
 */


class DataModelAudienceConditionTests: XCTestCase {
    
    // MARK: - Decode
    
    func testDecode_I() {
        let model: [AudienceCondition] = jsonDecodeFromDict(["12345"])
        XCTAssert(model[0] == AudienceCondition.audienceId("12345"))
    }
    
    func testDecode_A() {
        let model: [AudienceCondition] = jsonDecodeFromDict(["and"])
        XCTAssert(model[0] == AudienceCondition.logicalOp(.and))
    }
    
    func testDecode_O() {
        let model: [AudienceCondition] = jsonDecodeFromDict(["or"])
        XCTAssert(model[0] == AudienceCondition.logicalOp(.or))
    }

    func testDecode_N() {
        let model: [AudienceCondition] = jsonDecodeFromDict(["not"])
        XCTAssert(model[0] == AudienceCondition.logicalOp(.not))
    }
    
    func testDecode_AI() {
        let model: AudienceCondition = jsonDecodeFromDict(["and", "12345"])
        XCTAssert(model == AudienceCondition.array([
            .logicalOp(.and),
            .audienceId("12345")]
            ))
    }
    
    func testDecode_OI() {
        let model: AudienceCondition = jsonDecodeFromDict(["or", "12345"])
        XCTAssert(model == AudienceCondition.array([
            .logicalOp(.or),
            .audienceId("12345")]
            ))
    }
    
    func testDecode_NI() {
        let model: AudienceCondition = jsonDecodeFromDict(["not", "12345"])
        XCTAssert(model == AudienceCondition.array([
            .logicalOp(.not),
            .audienceId("12345")]
            ))
    }
}

// MARK: - Encode

extension DataModelAudienceConditionTests {
    func testEncodeJSON() {
        let modelGiven = AudienceCondition.array([
            .logicalOp(.and),
            .audienceId("12345"),
            .array([
                .logicalOp(.or),
                .audienceId("67890"),
                .audienceId("55555")])
            ])
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}

