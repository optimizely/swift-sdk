//
//  DataModelConditionHolderTestsEvaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest


// MARK: - Evaluate (AudienceIds)

class DataModelConditionHolderTestsEvaluate: XCTestCase {

    struct ProjectMock: ProjectProtocol {
        func evaluateAudience(audienceId: String, attributes: [String : Any]) -> Bool? {
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
        let model = ConditionHolder.audienceId("11111")
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A() {
        let model = ConditionHolder.logicalOp(.and)
        XCTAssertNil(model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_O() {
        let model = ConditionHolder.logicalOp(.or)
        XCTAssertNil(model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_N() {
        let model = ConditionHolder.logicalOp(.not)
        XCTAssertNil(model.evaluate(project: project, attributes: attributeData))
    }
    
    func testEvaluate_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("11111")]
            )
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.or),
            .audienceId("11111")]
        )
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.not),
            .audienceId("11111")]
        )
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .audienceId("11111")])
            ])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .audienceId("11111")])
            ])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .audienceId("11111")])
            ])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_I_AII() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("11111"),
            .array([.logicalOp(.and),
                    .audienceId("33333"),
                    .audienceId("44444")])
            ])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_O__A_I_OII__O_AII_NI() {
        let model = ConditionHolder.array([
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
            ])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
}


// MARK: - Evaluate (UserAttributes)

extension DataModelConditionHolderTestsEvaluate {

    func testEvaluate_U() {
        let model: ConditionHolder = jsonDecodeFromDict(userAttributeData)
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }

    func testEvaluate_AU() {
        let model: ConditionHolder = jsonDecodeFromDict(["and", userAttributeData])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }

    func testEvaluate_NU() {
        let model: ConditionHolder = jsonDecodeFromDict(["not", userAttributeData])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }

}
