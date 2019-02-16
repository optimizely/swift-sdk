//
//  DataModelConditionHolderTestsEvaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelConditionHolderTestsEvaluate: XCTestCase {

    var config = ProjectConfig()
    let attributes = ["age": 30]
    
    // MARK: - Decode
    
    func testEvaluate_I() {
        let model = ConditionHolder.audienceId("12345")
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_A() {
        let model = ConditionHolder.logicalOp(.and)
        XCTAssertNil(model.evaluate(projectConfig: config, attributes: attributes))
    }
    
    func testEvaluate_O() {
        let model = ConditionHolder.logicalOp(.or)
        XCTAssertNil(model.evaluate(projectConfig: config, attributes: attributes))
    }
    
    func testEvaluate_N() {
        let model = ConditionHolder.logicalOp(.not)
        XCTAssertNil(model.evaluate(projectConfig: config, attributes: attributes))
    }
    
    func testEvaluate_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("12345")]
            )
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.or),
            .audienceId("12345")]
        )
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.not),
            .audienceId("12345")]
        )
        XCTAssertFalse(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_A_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .audienceId("12345")])
            ])
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_A_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .audienceId("12345")])
            ])
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_A_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .audienceId("12345")])
            ])
        XCTAssertFalse(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
    func testEvaluate_A_I_AII() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .audienceId("12345"),
            .array([.logicalOp(.and),
                    .audienceId("33333"),
                    .audienceId("44444")])
            ])
        XCTAssertFalse(model.evaluate(projectConfig: config, attributes: attributes)!)
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
        XCTAssertTrue(model.evaluate(projectConfig: config, attributes: attributes)!)
    }
    
}
