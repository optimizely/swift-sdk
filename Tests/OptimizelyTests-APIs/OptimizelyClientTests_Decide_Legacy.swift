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

class OptimizelyClientTests_Decide_Legacy: XCTestCase {
    
    let kUserId = "tester"
    let kAttributes = ["country": "US"]
    let kEventKey = "any-event"
    let kEventTags = ["name": "carrot"]
    
    class MockOptimizelyClient: OptimizelyClient {
        var trackEventKey: String?
        var trackUserId: String?
        var trackAttributes: [String: String]?
        var trackEventTags: [String: String]?
        
        override func track(eventKey: String,
                            userId: String,
                            attributes: OptimizelyAttributes? = nil,
                            eventTags: OptimizelyEventTags? = nil) throws {
            trackEventKey = eventKey
            trackUserId = userId
            trackAttributes = attributes as? [String: String]
            trackEventTags = eventTags as? [String: String]
        }
    }
    
    var optimizely: MockOptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = MockOptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                          userProfileService: OTUtils.createClearUserProfileService())
        try! optimizely.start(datafile: datafile)
    }
    
}

// MARK: - legacy APIs with UserContext

extension OptimizelyClientTests_Decide_Legacy {
    
    func testLegacyTrackIsCalled() {
        try! self.optimizely.track(eventKey: kEventKey,
                                   user: OptimizelyUserContext(userId: kUserId, attributes: kAttributes),
                                   eventTags: kEventTags)
        
        XCTAssertEqual(optimizely.trackEventKey, kEventKey)
        XCTAssertEqual(optimizely.trackUserId, kUserId)
        XCTAssertEqual(optimizely.trackAttributes, kAttributes)
        XCTAssertEqual(optimizely.trackEventTags, kEventTags)
    }
    
}
