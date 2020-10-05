/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

class OptimizelyClientTests_Decide: XCTestCase {

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
    }
   
    func testCreateUserContext() {
        let userId = "tester"
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        
        let user = optimizely.createUserContext(userId: "tester", attributes: attributes)
        
        XCTAssert(user.optimizely == optimizely)
        XCTAssert(user.userId == userId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
    }
    
    func testCreateUserContext_multiple() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user1 = optimizely.createUserContext(userId: "tester1", attributes: attributes)
        let user2 = optimizely.createUserContext(userId: "tester2", attributes: [:])
        
        XCTAssert(user1.userId == "tester1")
        XCTAssert(user2.userId == "tester2")
    }
    
    func testDefaultDecideOptions() {
        let expOptions: [OptimizelyDecideOption] = [.ignoreUserProfileService,
                                                    .disableDecisionEvent,
                                                    .enabledFlagsOnly,
                                                    .includeReasons]
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        XCTAssert(optimizely.defaultDecideOptions.count == 0)

        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      defaultDecideOptions: expOptions)
        XCTAssert(optimizely.defaultDecideOptions == expOptions)
    }
    
}

