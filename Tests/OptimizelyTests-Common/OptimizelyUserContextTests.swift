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
    let expOptimizely = OptimizelyClient(sdkKey: "any")

    func testOptimizelyUserContext_userId() {
        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: expUserId)
        
        XCTAssert(user.optimizely == expOptimizely)
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes.count == 0)
    }
    
    func testOptimizelyUserContext_nilAttributes() {
        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: expUserId, attributes: nil)
        
        XCTAssert(user.optimizely == expOptimizely)
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes.count == 0)
    }

    func testOptimizelyUserContext_attributes() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: expUserId, attributes: attributes)
        
        XCTAssert(user.optimizely == expOptimizely)
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
    }

    func testOptimizelyUserContext_setAttribute() {
        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: expUserId, attributes: nil)
        user.setAttribute(key: "state", value: "ca")
        user.setAttribute(key: "num", value: 200)
        user.setAttribute(key: "many", value: false)

        XCTAssert(user.optimizely == expOptimizely)
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
        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: expUserId, attributes: attributes)
        user.setAttribute(key: "state", value: "ca")

        XCTAssert(user.optimizely == expOptimizely)
        XCTAssert(user.userId == expUserId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
        XCTAssert(user.attributes["state"] as! String == "ca")
    }
    
    func testOptimizelyUserContext_equal() {
        let userId1 = "user1"
        let userId2 = "user2"

        let attributes1: [String: Any] = [
            "country": "us",
            "old": true
        ]
        
        let attributes2: [String: Any] = [
            "country": "ca",
            "old": true
        ]

        let attributes3: [String: Any] = [
            "country": "us",
            "old": false
        ]

        let user = OptimizelyUserContext(optimizely: expOptimizely, userId: userId1, attributes: attributes1)
        XCTAssertEqual(user, OptimizelyUserContext(optimizely: expOptimizely, userId: userId1, attributes: attributes1))
        XCTAssertNotEqual(user, OptimizelyUserContext(optimizely: expOptimizely, userId: userId2, attributes: attributes1))
        XCTAssertNotEqual(user, OptimizelyUserContext(optimizely: expOptimizely, userId: userId1, attributes: attributes2))
        XCTAssertNotEqual(user, OptimizelyUserContext(optimizely: expOptimizely, userId: userId1, attributes: attributes3))
    }

}

