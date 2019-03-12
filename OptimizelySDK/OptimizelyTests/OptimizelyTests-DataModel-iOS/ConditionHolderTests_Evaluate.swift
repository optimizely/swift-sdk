//
//  ConditionHolderTests_Evaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest


// MARK: - Evaluate (AudienceIds)

class ConditionHolderTests_Evaluate: XCTestCase {

    struct ProjectMock: ProjectProtocol {
        func evaluateAudience(audienceId: String, attributes: OptimizelyAttributes?) throws -> Bool {
            return Int(audienceId)! < 20000
        }
    }
    
    var project = ProjectMock()
    let attributeData = ["age": 30]
    let userAttributeData: [String: Any] = ["name":"age",
                                            "type":"custom_attribute",
                                            "match":"gt",
                                            "value":20]

    func testEvaluate_I() {
        let model = ConditionHolder.leaf(.audienceId("11111"))
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_A() {
        let model = ConditionHolder.logicalOp(.and)
        XCTAssertNil(try? model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_O() {
        let model = ConditionHolder.logicalOp(.or)
        XCTAssertNil(try? model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_N() {
        let model = ConditionHolder.logicalOp(.not)
        XCTAssertNil(try? model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111"))]
            )
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.or),
            .leaf(.audienceId("11111"))]
        )
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.not),
            .leaf(.audienceId("11111"))]
        )
        XCTAssertFalse(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_A_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_A_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_A_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertFalse(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_A_I_AII() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111")),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("33333")),
                    .leaf(.audienceId("44444"))])
            ])
        XCTAssertFalse(try! model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_O__A_I_OII__O_AII_NI() {
        let model = ConditionHolder.array([
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
            ])
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }
    
}

// MARK: - Evaluate (UserAttributes)

extension ConditionHolderTests_Evaluate {

    func testEvaluate_U() {
        let model: ConditionHolder = try! OTUtils.model(from: userAttributeData)
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }

    func testEvaluate_AU() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", userAttributeData])
        XCTAssertTrue(try! model.evaluate(project: project, attributes: attributeData))
    }

    func testEvaluate_NU() {
        let model: ConditionHolder = try! OTUtils.model(from: ["not", userAttributeData])
        XCTAssertFalse(try! model.evaluate(project: project, attributes: attributeData))
    }

}

