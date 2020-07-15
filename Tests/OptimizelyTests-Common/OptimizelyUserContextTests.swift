//
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

class OptimizelyUserContextTests: XCTestCase {
    
    let exp1Key = "exp_with_audience"
    let var1AKey = "a"
    let var1BKey = "b"
    let exp1Id = "10390977673"
    let var1AId = "10389729780"
    let var1BId = "10416523121"

    let exp2Key = "exp_no_audience"
    let var2AKey = "variation_with_traffic"
    let var2BKey = "variation_no_traffic"
    let exp2Id = "10420810910"
    let var2AId = "10418551353"
    let var2BId = "10418510624"

    let expUserId = "1234"
    let expUserId2 = "3456"

    func testOptimizelyUserContext_userId() {
        let user = OptimizelyUserContext(userId: expUserId)
        
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes.count == 0)
        XCTAssert(user.defaultOptions.count == 0)
    }
    
    func testOptimizelyUserContext_nilUserId() {
        clearOptimizelyUUID()
        
        var user = OptimizelyUserContext(userId: nil)
        
        let expUserId1 = getOptimizelyUUID()
        XCTAssert(user.userId == expUserId1)
        XCTAssert(user.attributes.count == 0)
        XCTAssert(user.defaultOptions.count == 0)
        
        user = OptimizelyUserContext(userId: nil)
        
        let expUserId2 = getOptimizelyUUID()
        XCTAssert(user.userId == expUserId2)
        XCTAssert(expUserId1 == expUserId2)
    }

    func testOptimizelyUserContext_nilAttributes() {
        let user = OptimizelyUserContext(userId: expUserId, attributes: nil)
        
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes.count == 0)
    }

    func testOptimizelyUserContext_attributes() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user = OptimizelyUserContext(userId: expUserId, attributes: attributes)
        
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
    }

    func testOptimizelyUserContext_setAttribute() {
        var user = OptimizelyUserContext(userId: expUserId, attributes: nil)
        user.setAttribute(key: "state", value: "ca")
        user.setAttribute(key: "num", value: 200)
        user.setAttribute(key: "many", value: false)

        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes["state"] as! String == "ca")
        XCTAssert(user.attributes["num"] as! Int == 200)
        XCTAssert(user.attributes["many"] as! Bool == false)
    }

    func testOptimizelyUserContext_setAttribute2() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        var user = OptimizelyUserContext(userId: expUserId, attributes: attributes)
        user.setAttribute(key: "state", value: "ca")

        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
        XCTAssert(user.attributes["state"] as! String == "ca")
    }

    func testOptimizelyUserContext_setDefaultOptions() {
        let expOptions: [OptimizelyDecideOption] = [.bypassUPS,
                                                    .disableTracking,
                                                    .enabledOnly,
                                                    .forExperiment,
                                                    .includeReasons]
        var user = OptimizelyUserContext(userId: expUserId)
        user.setDefaultOptions(expOptions)
        
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.defaultOptions == expOptions)
    }
    
}
    
// MARK: - setUserContext
    
extension OptimizelyUserContextTests {
    
    func testSetUserContext() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user = OptimizelyUserContext(userId: expUserId, attributes: attributes)
        
        let optimizely = OptimizelyClient(sdkKey: "sdk-key")
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("api_datafile")!)
        try! optimizely.setUserContext(user)
        
        XCTAssert(optimizely.userContext == user)
    }
    
    func testSetUserContext_replace() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user1 = OptimizelyUserContext(userId: expUserId, attributes: attributes)
        let user2 = OptimizelyUserContext(userId: expUserId2, attributes: [:])

        let optimizely = OptimizelyClient(sdkKey: "sdk-key")
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("api_datafile")!)
        try! optimizely.setUserContext(user1)
        XCTAssert(optimizely.userContext == user1)
        
        try! optimizely.setUserContext(user2)
        XCTAssert(optimizely.userContext == user2)
    }
    
    func testSetUserContext_emptyUserId() {
        let optimizely = OptimizelyClient(sdkKey: "sdk-key")
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("api_datafile")!)
        
        let user1 = OptimizelyUserContext(userId: nil, attributes: [:])
        try! optimizely.setUserContext(user1)
        
        let userId1 = optimizely.userContext!.userId
        XCTAssertNotNil(userId1)
        XCTAssert(userId1.count > 10)
        
        let user2 = OptimizelyUserContext(userId: nil, attributes: [:])
        try! optimizely.setUserContext(user2)

        let userId2 = optimizely.userContext!.userId
        XCTAssert(userId1 == userId2)
        
        print("UUID: \(userId1)")
        
        clearOptimizelyUUID()   // clean up UUID store after testing
    }
    
}

// Mark: - Utils

extension OptimizelyUserContextTests {
    
    func setUserContextForUPSTest(_ user: OptimizelyUserContext) -> OPTUserProfileService {
        let ups = DefaultUserProfileService()
        ups.reset()

        let optimizely = OptimizelyClient(sdkKey: String(arc4random()),   // random to avoid ups conflicts
                                          userProfileService: ups)
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("api_datafile")!)
        try! optimizely.setUserContext(user)
        
        return ups
    }
    
    var uuidKey: String {
        return "optimizely-uuid"
    }
    
    func getOptimizelyUUID() -> String? {
        return UserDefaults.standard.string(forKey: uuidKey)
    }
    
    func clearOptimizelyUUID() {
        UserDefaults.standard.removeObject(forKey: uuidKey)
    }
    
}
