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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var optimizely: OptimizelyClient!
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        var sdkKeys = [String]()
//        sdkKeys.append("AqLkkcss3wRGUbftnKNgh2")
//        sdkKeys.append("FCnSegiEkRry9rhVMroit4")
//        sdkKeys.append("VE2r2nTX4fogL6m3EQqkk3")
//        sdkKeys.append("Q9yTzC1GTnden1geuSFXu")
        sdkKeys.append("DZB4eRNYsk8cWMAHE4Uvhb")    // Optimizely Product JS/Python
//        sdkKeys.append("X6xJvai8Yu9E7wT1hkvGM")     // large flags + many audiences
//        sdkKeys.append("Sr9qbsCXNFhZvLpZk764za")    // many audiences
        
        print("[DecisionTable Files Directory] \(NSHomeDirectory())")

        sdkKeys.forEach { sdkKey in            
            let semaphore = DispatchSemaphore(value: 0)
            
            optimizely = OptimizelyClient(sdkKey: sdkKey,
                                          defaultLogLevel: .error,
                                          defaultDecideOptions: [.ignoreUserProfileService, .disableDecisionEvent])
            
            optimizely.start { result in
                if case .failure(let error) = result {
                    print("Optimizely SDK initiliazation failed: \(error)")
                    return
                }
                
                self.testDecisionTable()
                semaphore.signal()
            }
            
            semaphore.wait()
        }
    }
            
    func testDecisionTable() {
        // locally generate DecisionTables (will be created in the backend and downloaded later)
        let decisionTables = DecisionTableGenerator.create(for: optimizely)

        compareDecisions(decisionTables)
//
//        comparePerformance(decisionTables)
    }
    
    func compareDecisions(_ decisionTables: OptimizelyDecisionTables) {
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        let allFlags = optimizelyConfig.featuresMap.keys
        let compareTotal = 1000
        var countMatch = 0
        
        print("\n----- DecisionAPI : DecideTable ------------------------")
        for i in 0..<compareTotal {
            let flagKey = allFlags.randomElement()!
            //let flagKey = "my_feature"
            let user = decisionTables.getRandomUserContext(optimizely: optimizely, key: flagKey)
            
            OptimizelyDecisionTables.modeUseDecisionTable = true
            let decisionNew = user.decide(key: flagKey)
            let variationNew = decisionNew.variationKey ?? "nil"
            let lookupInput = decisionNew.ruleKey!   // passing back lookupInput in the ruleKey field 
            OptimizelyDecisionTables.modeUseDecisionTable = false
            let decisionOld = user.decide(key: flagKey)
            let variationOld = decisionOld.variationKey ?? "nil"
            let flagKeyPadding = "(Flag: \(flagKey))".padding(toLength: 32, withPad: " ", startingAt: 0)
            
            //print(String(format: "[%3d]%@   =   %@ : %@ (<- %@)", i, flagKeyPadding, variationOld, variationNew, lookupInput))
            print(String(format: "[%3d]%@   =   %@ : %@ (<- %@)    (%@)", i, flagKeyPadding, variationOld, variationNew, lookupInput, user.description))
            if variationNew == variationOld {
                countMatch += 1
            } else {
                print("---> [Failure]")
            }
        }
        print("Total match: \(countMatch)/\(compareTotal)")
    }
    
    func comparePerformance(_ decisionTables: OptimizelyDecisionTables) {
        let optimizelyConfig = try! optimizely.getOptimizelyConfig()
        let allFlags = optimizelyConfig.featuresMap.keys
        let flagKey = allFlags.randomElement()!
        let user = decisionTables.getRandomUserContext(optimizely: optimizely, key: flagKey)
        let performanceTotal = 10000
        
        print("\n----- Performance ------------------------")
        
        var startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<performanceTotal {
            OptimizelyDecisionTables.modeUseDecisionTable = true
            _ = user.decide(key: flagKey).variationKey
        }
        print(String(format: "Time elapsed for DecisionTable: %.03f secs", CFAbsoluteTimeGetCurrent() - startTime))
    
        startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<performanceTotal {
            OptimizelyDecisionTables.modeUseDecisionTable = false
            _ = user.decide(key: flagKey).variationKey
        }
        print(String(format: "Time elapsed for DecisionAPI: %.03f secs", CFAbsoluteTimeGetCurrent() - startTime))
    }

}




extension AppDelegate {
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}
}
