//
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
import Foundation
import Cucumberish

class TestManager: NSObject {
    
    internal static var requestModel: RequestModel?
    internal static var responseModel: ResponseModel?
    
    static func setup() {
        
        before { (scenario) in
            requestModel = RequestModel()
        }
        
        setupBackgroundScenarios()
        setupWhenListeners()
        setupThenListeners()
        setupAndListeners()
    }
    
    internal static func getResult() {
        do {
            responseModel = try OptimizelyE2EService.LoadOptimizelyE2E(request: requestModel!)?.run()
        } catch {
            print(error.localizedDescription)
        }
    }
}