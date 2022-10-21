//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class OptimizelyUserContextTests_Performance: XCTestCase {
    var optimizely: OptimizelyClient!
    
    override func setUpWithError() throws {
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, defaultLogLevel: .error)
        try! optimizely.start(datafile: datafile)
    }
}

// tests below will be skipped in CI (travis/actions) since they use time control.

#if DEBUG

extension OptimizelyUserContextTests_Performance {
    
    func testPerformance_create() {
        let timeInMicrosecs = measureTime {
            _ = optimizely.createUserContext(userId: "tester", attributes: ["a1": "b1"])
        }
        
        XCTAssert(timeInMicrosecs < 10, "user context create takes too long (\(timeInMicrosecs) microsecs)")
    }
    
    func testPerformance_clone() {
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "tester", attributes: ["a1": "b1"])
        
        let timeInMicrosecs = measureTime {
            _ = user.clone
        }
        
        XCTAssert(timeInMicrosecs < 10, "user context cloning takes too long (\(timeInMicrosecs) microsecs)")
    }
    
    func testPerformance_clone_2() {
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "tester", attributes: ["a1": "b1"])
        
        for i in 0..<100 {
            user.setAttribute(key: "k\(i)", value: "v\(i)")
        }
        for i in 0..<100 {
            _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: "f\(i)", ruleKey: "k\(i)"), decision: OptimizelyForcedDecision(variationKey: "v\(i)"))
        }
        user.qualifiedSegments = (0..<100).map{ "segment\($0)" }
        
        let timeInMicrosecs = measureTime {
            _ = user.clone
        }
        
        XCTAssert(timeInMicrosecs < 10, "user context cloning takes too long (\(timeInMicrosecs) microsecs)")
    }
    
    func testPerformance_decideInvalid() {
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "tester", attributes: ["a1": "b1"])
        
        var decision: OptimizelyDecision!
        let timeInMicrosecs = measureTime {
            decision = user.decide(key: "invalid")
        }
        XCTAssertFalse(decision.enabled)
        
        XCTAssert(timeInMicrosecs < 10, "user context decide-with-invalid takes too long (\(timeInMicrosecs) microsecs)")
    }
    
    func testPerformance_decideValid() {
        
        // fall-thru to 'everyone-else after one ab-test (audience=gender) + 2 rollouts (audience=country, audience=browser)
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: "tester")
        
        var decision: OptimizelyDecision!
        let timeInMicrosecs = measureTime {
            decision = user.decide(key: featureKey, options: [.ignoreUserProfileService])
        }
        XCTAssert(decision.enabled, "everyone-else rule is enabled")
        
        XCTAssert(timeInMicrosecs < 300, "user context decide-with-valid takes too long (\(timeInMicrosecs) microsecs)")
    }
    
}

#endif

// MARK: - Utils

extension OptimizelyUserContextTests_Performance {
    
    func measureTime(operation: () -> Void) -> Double {
        let measureCount = 10000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<measureCount {
            operation()
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let unitTimeInMillisecs = timeElapsed / Double(measureCount) * 1_000_000
        let formatted = Double(Int(unitTimeInMillisecs * 1000)) / 1000
        
        print("[UserContext] (\(formatted) microsecs) to complete the task")
        return formatted
    }
    
}

