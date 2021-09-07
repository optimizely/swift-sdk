//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

import UIKit
import Optimizely

var modeGenerateDecisionTable = false
var modeUseDecisionTable = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var optimizely: OptimizelyClient!
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        let sdkKey = "FCnSegiEkRry9rhVMroit4"

        optimizely = OptimizelyClient(sdkKey: sdkKey,
                                      defaultLogLevel: .error,
                                      defaultDecideOptions: [.ignoreUserProfileService, .disableDecisionEvent])
        
        optimizely.start { result in
            if case .failure(let error) = result {
                print("Optimizely SDK initiliazation failed: \(error)")
                return
            }

            self.testDecisionTable()
        }
    }
            
    func testDecisionTable() {
        
        // create DecisionTables (will be created in the backend and downloaded later)
        
        modeGenerateDecisionTable = true
        
        let decisionTables = DecisionTableGenerator.create(for: optimizely)
        
        modeGenerateDecisionTable = false
        
        // validate decisions from DecisionTables
        
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        let allFlags = optimizelyConfig.featuresMap.keys
        
        let compareTotal = 100
        var countMatch = 0
        
        print("----- DecisionTable : DecideAPI ------------------------")
        for i in 0..<compareTotal {
            let flagKey = allFlags.randomElement()!
            let user = decisionTables.getRandomUserContext(optimizely: optimizely, flagKey: flagKey)
            
            modeUseDecisionTable = true
            let decisionNew = user.decide(key: flagKey).variationKey
            modeUseDecisionTable = false
            let decisionOld = user.decide(key: flagKey).variationKey
            
            print("[Decision \(i)][Flag: \(flagKey)] = \(decisionOld) : \(decisionNew)")
            if decisionNew == decisionOld {
                countMatch += 1
            } else {
                print("---> [Failure]")
            }
        }
        print("Total match: \(countMatch)/\(compareTotal)")
        
        // performance
        
        let performanceTotal = 10000
        
        let flagKey = allFlags.randomElement()!
        let user = decisionTables.getRandomUserContext(optimizely: optimizely, flagKey: flagKey)

        print("----- Performance ------------------------")
        
        var startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<performanceTotal {
            modeUseDecisionTable = true
            _ = user.decide(key: flagKey).variationKey
        }
        print(String(format: "Time elapsed for DecisionTable: %.03f secs", CFAbsoluteTimeGetCurrent() - startTime))
    
        startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<performanceTotal {
            modeUseDecisionTable = false
            _ = user.decide(key: flagKey).variationKey
        }
        print(String(format: "Time elapsed for DecisionAPI: %.03f secs", CFAbsoluteTimeGetCurrent() - startTime))
    }
    
    
    
    
    
    
    // MARK: - AppDelegagte
    
    func applicationWillResignActive(_ application: UIApplication) {}
    
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    func applicationWillEnterForeground(_ application: UIApplication) {}
    
    func applicationDidBecomeActive(_ application: UIApplication) {}
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
}
