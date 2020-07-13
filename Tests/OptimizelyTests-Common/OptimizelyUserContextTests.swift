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

    func testOptimizelyUserContext() {
        let user = OptimizelyUserContext(userId: nil)
        
        XCTAssert(user.userId == nil)
        XCTAssert(user.attributes.count == 0)
        XCTAssert(user.bucketingId == nil)
        XCTAssert(user.userProfileUpdates.count == 0)
    }

    func testOptimizelyUserContext_userId() {
        let user = OptimizelyUserContext(userId: expUserId)
        
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes.count == 0)
        XCTAssert(user.bucketingId == nil)
        XCTAssert(user.userProfileUpdates.count == 0)
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

    func testOptimizelyUserContext_setBucketingId() {
        let expBucketingId = "5678"
        var user = OptimizelyUserContext(userId: expUserId)
        user.setBucketingId(expBucketingId)

        XCTAssert(user.userId == expUserId)
        XCTAssert(user.bucketingId == expBucketingId)
        XCTAssert(user.attributes["$opt_bucketing_id"] as! String == expBucketingId)
    }

    func testOptimizelyUserContext_setUserProfile() {
        var user = OptimizelyUserContext(userId: expUserId)
        user.setUserProfile(key: "k1", value: "v1")
        user.setUserProfile(key: "k2", value: nil)
        user.setUserProfile(key: nil, value: nil)

        XCTAssert(user.userId == expUserId)
        XCTAssert(user.userProfileUpdates.count == 3)
        XCTAssert(user.userProfileUpdates[0] == ("k1", "v1"))
        XCTAssert(user.userProfileUpdates[1] == ("k2", nil))
        XCTAssert(user.userProfileUpdates[2] == (nil, nil))
    }
}
    
// MARK: - setOptimizelyUserContext
    
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
    
    func testSetUserContext_bucketingId() {
        let expBucketingId = "5678"
        var user = OptimizelyUserContext(userId: expUserId)
        user.setBucketingId(expBucketingId)
        
        let optimizely = OptimizelyClient(sdkKey: "sdk-key")
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("api_datafile")!)
        try! optimizely.setUserContext(user)

        if let internalUserId = optimizely.userContext?.userId,
            let internalAttributes = optimizely.userContext?.attributes {
            
            let bucketingId = (optimizely.decisionService as! DefaultDecisionService)
                                .getBucketingId(userId: internalUserId, attributes: internalAttributes)
            XCTAssert(bucketingId == expBucketingId)
            
        } else {
            XCTAssert(false)
        }
    }
    
    func testSetUserContext_userProfile() {
        var user = OptimizelyUserContext(userId: expUserId)
        user.setUserProfile(key: exp1Key, value: var1AKey)
        user.setUserProfile(key: exp2Key, value: var2AKey)

        let ups = setUserContextForUPSTest(user)
        
        let profile = ups.lookup(userId: expUserId)!
        let bucketMap = profile["experiment_bucket_map"] as! OPTUserProfileService.UPBucketMap
        XCTAssert(bucketMap[exp1Id] == ["variation_id": var1AId])
        XCTAssert(bucketMap[exp2Id] == ["variation_id": var2AId])
    }
    
    func testSetUserContext_userProfileRemove() {
        var user = OptimizelyUserContext(userId: expUserId)
        user.setUserProfile(key: exp1Key, value: var1AKey)
        user.setUserProfile(key: exp2Key, value: var2AKey)
        user.setUserProfile(key: exp1Key, value: nil)

        let ups = setUserContextForUPSTest(user)
        
        let profile = ups.lookup(userId: expUserId)!
        let bucketMap = profile["experiment_bucket_map"] as! OPTUserProfileService.UPBucketMap
        XCTAssertNil(bucketMap[exp1Id])
        XCTAssert(bucketMap[exp2Id] == ["variation_id": var2AId])
    }
    
    func testSetUserContext_userProfileRemoveAll() {
        var user = OptimizelyUserContext(userId: expUserId)
        user.setUserProfile(key: exp1Key, value: var1AKey)
        user.setUserProfile(key: exp2Key, value: var2AKey)
        user.setUserProfile(key: nil, value: nil)

        let ups = setUserContextForUPSTest(user)
        
        let profile = ups.lookup(userId: expUserId)!
        let bucketMap = profile["experiment_bucket_map"] as! OPTUserProfileService.UPBucketMap
        XCTAssertNil(bucketMap[exp1Id])
        XCTAssertNil(bucketMap[exp2Id])
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
        XCTAssert(userId1!.count > 10)
        
        let user2 = OptimizelyUserContext(userId: nil, attributes: [:])
        try! optimizely.setUserContext(user2)

        let userId2 = optimizely.userContext!.userId
        XCTAssert(userId1 == userId2)
        
        print("UUID: \(userId1!)")
        
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
