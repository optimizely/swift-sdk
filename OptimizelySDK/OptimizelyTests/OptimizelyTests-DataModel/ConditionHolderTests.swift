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

// MARK: - Sample Data

class ConditionHolderTests: XCTestCase {
    static var sampleData: [Any] = ["or", UserAttributeTests.sampleData]

    func testDecodeSample() {
        let model: ConditionHolder = try! OTUtils.model(from: ConditionHolderTests.sampleData)
        let userAttribute: UserAttribute = try! OTUtils.model(from: UserAttributeTests.sampleData)
        
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.or),
            .leaf(.attribute(userAttribute))]))
    }
    
    func testDecodeFailure() {
        var value = 3
        let data = Data(bytes: &value,
                             count: MemoryLayout.size(ofValue: value))
        
        let holder = try? JSONDecoder().decode(ConditionHolder.self, from: data)
        XCTAssertNil(holder)
    }
    
    func testEvaluateFail() {
        let holder:ConditionHolder = ConditionHolder.array([ConditionHolder.logicalOp(.and)])
        var data:Data?
    
        data = try? JSONEncoder().encode(holder)

        XCTAssertNotNil(data)
        let testHolder = try? JSONDecoder().decode(ConditionHolder.self, from: data!)
        let bool = try? testHolder!.evaluate(project: nil, attributes: nil)
        XCTAssertNil(bool)
    }
}

// MARK: - Decode (AudienceIds)

extension ConditionHolderTests {
    func testDecode_I() {
        // JSON does not support raw string (so use array of string)
        let model: [ConditionHolder] = try! OTUtils.model(from: ["11111"])
        XCTAssert(model[0] == ConditionHolder.leaf(.audienceId("11111")))
    }
    
    func testDecode_A() {
        let model: [ConditionHolder] = try! OTUtils.model(from: ["and"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.and))
    }

    func testDecode_O() {
        let model: [ConditionHolder] = try! OTUtils.model(from: ["or"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.or))
    }

    func testDecode_N() {
        let model: [ConditionHolder] = try! OTUtils.model(from: ["not"])
        XCTAssert(model[0] == ConditionHolder.logicalOp(.not))
    }

    func testDecode_AI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", "11111"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111"))]
            ))
    }

    func testDecode_OI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["or", "11111"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.or),
            .leaf(.audienceId("11111"))]
            ))
    }

    func testDecode_NI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["not", "11111"])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.not),
            .leaf(.audienceId("11111"))]
            ))
    }

    func testDecode_A_AI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", ["and", "11111"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("11111"))])
            ]))
    }

    func testDecode_A_OI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", ["or", "11111"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .leaf(.audienceId("11111"))])
            ]))
    }

    func testDecode_A_NI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", ["not", "11111"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .leaf(.audienceId("11111"))])
            ]))
    }

    func testDecode_A_I_AII() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and",
                                                           "11111",
                                                           ["and", "33333", "44444"]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111")),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("33333")),
                    .leaf(.audienceId("44444"))])
            ]))
    }

    func testDecode_O__A_I_OII__O_AII_NI() {
        let model: ConditionHolder = try! OTUtils.model(from: ["or",
                                                           ["and",
                                                            "11111",
                                                            ["or", "22222", "33333"]],
                                                           ["or",
                                                            ["and", "44444", "55555"],
                                                            ["not", "66666"]]])
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.or),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("11111")),
                    .array([.logicalOp(.or),
                            .leaf(.audienceId("22222")),
                            .leaf(.audienceId("33333"))])]),
            .array([.logicalOp(.or),
                    .array([.logicalOp(.and),
                            .leaf(.audienceId("44444")),
                            .leaf(.audienceId("55555"))]),
                    .array([.logicalOp(.not),
                            .leaf(.audienceId("66666"))])])
            ]))
    }
}

// MARK: - Decode (UserAttributes)

extension ConditionHolderTests {

    func testDecode_U() {
        let userAttributeData = UserAttributeTests.sampleData
        
        let model: ConditionHolder = try! OTUtils.model(from: userAttributeData)
        let leaf = ConditionLeaf.attribute(try! OTUtils.model(from: userAttributeData))
        XCTAssert(model == ConditionHolder.leaf(leaf))
    }

    func testDecode_AU() {
        let userAttributeData = UserAttributeTests.sampleData

        let model: ConditionHolder = try! OTUtils.model(from: ["and", userAttributeData])
        let leaf = ConditionLeaf.attribute(try! OTUtils.model(from: userAttributeData))
        XCTAssert(model == ConditionHolder.array([
            .logicalOp(.and),
            .leaf(leaf)]
            ))
    }
    
}

// MARK: - Encode

extension ConditionHolderTests {
    func testEncodeJSON() {
        let modelGiven = ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111")),
            .array([.logicalOp(.or),
                    .leaf(.audienceId("22222")),
                    .leaf(.audienceId("33333"))])
            ])
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
}

// MARK: - Others

extension ConditionHolderTests {

    func testDecode_Invalid() {
        do {
            let _: ConditionHolder = try OTUtils.model(from: [120])
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

}
