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


// MARK: - Evaluate (AudienceIds)

class ConditionHolderTests_Evaluate: XCTestCase {

    let attributeData = ["age": 30]
    let userAttributeData: [String: Any] = ["name":"age",
                                            "type":"custom_attribute",
                                            "match":"gt",
                                            "value":20]

    var project:Project?
    
    override func setUp() {
        let data = OTUtils.loadJSONDatafile("simple_datafile")
        project = try! OTUtils.model(fromData:data!)
        let typedAudiences = "[{\"id\": \"11111\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"exact\", \"value\": 30}]]] },{\"id\": \"22222\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"gt\", \"value\": 30}]]] },{\"id\": \"33333\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"gt\", \"value\": 30}]]] },{\"id\": \"44444\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"gt\", \"value\": 30}]]] },{\"id\": \"55555\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"gt\", \"value\": 30}]]] },{\"id\": \"66666\",\"name\": \"age\",\"conditions\": [\"and\", [\"or\", [\"or\", {\"name\": \"age\", \"type\": \"custom_attribute\", \"match\":\"gt\", \"value\": 30}]]] },]"
        
        let jsonData = typedAudiences.data(using: .utf8)
        
        let audiences = try! JSONDecoder().decode([Audience].self, from: jsonData!)
        
        project?.typedAudiences = audiences
    }

    func testEvaluate_I() {
        let model = ConditionHolder.leaf(.audienceId("11111"))
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
            .leaf(.audienceId("11111"))]
            )
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.or),
            .leaf(.audienceId("11111"))]
        )
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.not),
            .leaf(.audienceId("11111"))]
        )
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_AI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_OI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.or),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_NI() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .array([.logicalOp(.not),
                    .leaf(.audienceId("11111"))])
            ])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }
    
    func testEvaluate_A_I_AII() {
        let model = ConditionHolder.array([
            .logicalOp(.and),
            .leaf(.audienceId("11111")),
            .array([.logicalOp(.and),
                    .leaf(.audienceId("33333")),
                    .leaf(.audienceId("44444"))])
            ])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
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
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }
    
}

// MARK: - Evaluate (UserAttributes)

extension ConditionHolderTests_Evaluate {

    func testEvaluate_U() {
        let model: ConditionHolder = try! OTUtils.model(from: userAttributeData)
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }

    func testEvaluate_AU() {
        let model: ConditionHolder = try! OTUtils.model(from: ["and", userAttributeData])
        XCTAssertTrue(model.evaluate(project: project, attributes: attributeData)!)
    }

    func testEvaluate_NU() {
        let model: ConditionHolder = try! OTUtils.model(from: ["not", userAttributeData])
        XCTAssertFalse(model.evaluate(project: project, attributes: attributeData)!)
    }

}

