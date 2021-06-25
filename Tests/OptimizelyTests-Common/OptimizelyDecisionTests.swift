//
// Copyright 2021, Optimizely, Inc. and contributors
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

class OptimizelyDecisionTests: XCTestCase {
    
    let variables = OptimizelyJSON(map: ["k1": "v1"])!
    let user = OptimizelyUserContext(optimizely: OptimizelyClient(sdkKey: "sdkKey"),
                                     userId: "userId")
    
    lazy var decision: OptimizelyDecision = {
        return OptimizelyDecision(variationKey: "value-variationKey",
                                      enabled: true,
                                      variables: variables,
                                      ruleKey: "value-ruleKey",
                                      flagKey: "value-flagKey",
                                      userContext: user,
                                      reasons: [])
    }()
    
    func testHasFailed() {
        XCTAssertFalse(decision.hasFailed)
        
        let d = OptimizelyDecision.errorDecision(key: "kv",
                                                 user: user,
                                                 error: .sdkNotReady)
        XCTAssert(d.hasFailed)
    }

    func testOptimizelyDecision_equal() {
        var d = OptimizelyDecision(variationKey: "value-variationKey",
                                    enabled: true,
                                    variables: variables,
                                    ruleKey: "value-ruleKey",
                                    flagKey: "value-flagKey",
                                    userContext: user,
                                    reasons: [])
        XCTAssert(d == decision)
        
        d = OptimizelyDecision(variationKey: "value-variationKey",
                               enabled: false,
                               variables: variables,
                               ruleKey: "value-ruleKey",
                               flagKey: "value-flagKey",
                               userContext: user,
                               reasons: [])
        XCTAssert(d != decision)

        d = OptimizelyDecision(variationKey: "wrong-value",
                               enabled: false,
                               variables: variables,
                               ruleKey: "value-ruleKey",
                               flagKey: "value-flagKey",
                               userContext: user,
                               reasons: [])
        XCTAssert(d != decision)

        d = OptimizelyDecision(variationKey: "wrong-value",
                               enabled: false,
                               variables: OptimizelyJSON(map: ["k1": "v2"])!,
                               ruleKey: "value-ruleKey",
                               flagKey: "value-flagKey",
                               userContext: user,
                               reasons: [])
        XCTAssert(d != decision)

        d = OptimizelyDecision(variationKey: "wrong-value",
                               enabled: false,
                               variables: variables,
                               ruleKey: "value-ruleKey",
                               flagKey: "value-flagKey",
                               userContext: OptimizelyUserContext(optimizely: OptimizelyClient(sdkKey: "sdkKey"),
                                                                  userId: "wrong-user"),
                               reasons: [])
        XCTAssert(d != decision)

        d = OptimizelyDecision(variationKey: "wrong-value",
                               enabled: false,
                               variables: variables,
                               ruleKey: "value-ruleKey",
                               flagKey: "value-flagKey",
                               userContext: user,
                               reasons: ["reason-1"])
        XCTAssert(d != decision)
    }
        
    func testOptimizelyDecision_description1() {
        let expected = """
        {
          variationKey: "value-variationKey"
          enabled: true
          variables: ["k1": "v1"]
          ruleKey: "value-ruleKey"
          flagKey: "value-flagKey"
          userContext: { userId: userId, attributes: [:] }
          reasons: [  ]
        }
        """
        XCTAssertEqual(decision.description, expected)
    }
    
    func testOptimizelyDecision_description2() {
        let variables = OptimizelyJSON(map: ["k2": true])!
        let user = OptimizelyUserContext(optimizely: OptimizelyClient(sdkKey: "sdkKey"),
                                         userId: "userId",
                                         attributes: ["age": 18])
        
        let decision = OptimizelyDecision(variationKey: "value-variationKey",
                                          enabled: true,
                                          variables: variables,
                                          ruleKey: "value-ruleKey",
                                          flagKey: "value-flagKey",
                                          userContext: user,
                                          reasons: ["reason-1", "reason-2"])
        
        let expected = """
        {
          variationKey: "value-variationKey"
          enabled: true
          variables: ["k2": true]
          ruleKey: "value-ruleKey"
          flagKey: "value-flagKey"
          userContext: { userId: userId, attributes: ["age": Optional(18)] }
          reasons: [
            - reason-1
            - reason-2
          ]
        }
        """
        XCTAssertEqual(decision.description, expected)
    }

}
