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
 
 A.I.AII = ["and", I, AII]
 A.I.OII = ["and", I, OII]
 A.I.NI = ["and", I, NI]
 O.I.AII = ["or", I, AII]
 O.I.OII = ["or", I, OII]
 O.I.NI = ["or", I, NI]
 
 A.AII.I = ["and", AII, I]
 A.OII.I = ["and", OII, I]
 A.NI.I = ["and", NI, I]
 O.AII.I = ["or", AII, I]
 O.OII.I = ["or", OII, I]
 O.NI.I = ["or", NI, I]
 
 // [and/or/not, [and/or/not, UserAttribute, [and/or/not, UserAttribute], [and/or/not, UserAttribute]]
 
 Complex1 = ["and", A.I.AII, AI]
 Complex2 = ["or", A.I.OII, O.AII.NI]
 
 */


class DataModelConditionHolderTests: XCTestCase {
    
    let config = ProjectConfig()
    let attributes = ["age": 30]
    
    // MARK: - Decode
    
    func testDecode_I() {
        let model: [ConditionHolder] = jsonDecodeFromDict(["12345"])
        XCTAssert(model[0] == ConditionHolder.audienceId("12345"))
    }
    
    func testDecode_A() {
        let model: [ConditionHolder] = jsonDecodeFromDict(["and"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.and))
    }
    
    func testDecode_O() {
        let model: [ConditionHolder] = jsonDecodeFromDict(["or"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.or))
    }

    func testDecode_N() {
        let model: [ConditionHolder] = jsonDecodeFromDict(["not"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.not))
    }
    
    func testDecode_AI() {
        let model: ConditionHolder = jsonDecodeFromDict(["and", "12345"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("12345")]
            ))
    }
    
    func testDecode_OI() {
        let model: ConditionHolder = jsonDecodeFromDict(["or", "12345"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.or),
            .audienceId("12345")]
            ))
    }
    
    func testDecode_NI() {
        let model: ConditionHolder = jsonDecodeFromDict(["not", "12345"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.not),
            .audienceId("12345")]
            ))
    }
    
    func testDecode_A_AI() {
        let model: ConditionHolder = jsonDecodeFromDict(["and", ["and", "12345"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .audienceId("12345")])
            ]))
    }

    func testDecode_A_OI() {
        let model: ConditionHolder = jsonDecodeFromDict(["and", ["or", "12345"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .audienceId("12345")])
            ]))
    }

    func testDecode_A_NI() {
        let model: ConditionHolder = jsonDecodeFromDict(["and", ["not", "12345"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .audienceId("12345")])
            ]))
    }
    
    func testDecode_A_I_AII() {
        let model: ConditionHolder = jsonDecodeFromDict(["and",
                                                           "12345",
                                                           ["and", "33333", "44444"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("12345"),
            .array([.logicalOp(.and),
                    .audienceId("33333"),
                    .audienceId("44444")])
            ]))
    }
    
    func testDecode_O__A_I_OII__O_AII_NI() {
        let model: ConditionHolder = jsonDecodeFromDict(["or",
                                                           ["and",
                                                            "11111",
                                                            ["or", "22222", "33333"]],
                                                           ["or",
                                                            ["and", "44444", "55555"],
                                                            ["not", "66666"]]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.or),
            .array([.logicalOp(.and),
                    .audienceId("11111"),
                    .array([.logicalOp(.or),
                            .audienceId("22222"),
                            .audienceId("33333")])]),
            .array([.logicalOp(.or),
                    .array([.logicalOp(.and),
                            .audienceId("44444"),
                            .audienceId("55555")]),
                    .array([.logicalOp(.not),
                            .audienceId("66666")])])
            ]))
    }
}

// MARK: - Encode

extension DataModelConditionHolderTests {
    func testEncodeJSON() {
        let modelGiven = ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("12345"),
            .array([.logicalOp(.or),
                    .audienceId("67890"),
                    .audienceId("55555")])
            ])
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}

