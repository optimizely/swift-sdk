//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class EventForDispatchTests: XCTestCase {
    
    func testEqualOperator() {
        var urlStr = "https://optimizely.com"
        var message = "One body"
        let event1 = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        var event2 = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        XCTAssert(event1 == event2)
        
        message = "Other body"
        event2 = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        XCTAssert(event1 != event2)

        urlStr = "Other url"
        message = "One body"
        event2 = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        XCTAssert(event1 != event2)
        
        urlStr = "https://optimizely.com"
        message = "One body"
        event2 = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        XCTAssert(event1 == event2)
    }

    func testDescriptionWithGoodString() {
        let urlStr = "https://optimizely.com"
        let message = "This is event body"
        let event = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf8)!)
        
        let desc = event.description
        XCTAssert(desc.contains(urlStr))
        XCTAssert(desc.contains(message))
    }
    
    func testDescriptionWithBadString() {
        let urlStr = "https://optimizely.com"
        let message = "This is event body"
        
        // use a wrong encoding (UTF16), which will cause invalid string
        let event = EventForDispatch(url: URL(string: urlStr), body: message.data(using: .utf16)!)
        
        let desc = event.description
        XCTAssert(desc.contains(urlStr))
        XCTAssert(desc.contains("UNKNOWN"))
    }
    
}
