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

class OdpVuidManagerTests: XCTestCase {
    var manager = OdpVuidManager()
    
    func testMakeVuid() {
        let vuid = manager.makeVuid()
        
        XCTAssertTrue(vuid.starts(with: "vuid_"))
        XCTAssertTrue(vuid.count > 20)
    }
    
    func testIsVuid() {
        XCTAssertTrue(manager.isVuid(visitorId: "vuid_123"))
        XCTAssertFalse(manager.isVuid(visitorId: "vuid-123"))
        XCTAssertFalse(manager.isVuid(visitorId: "123"))
    }
    
    func testAutoSaveAndLoad() {
        UserDefaults.standard.removeObject(forKey: "optimizely-odp")
        
        manager = OdpVuidManager()
        let vuid1 = manager.vuid
        
        manager = OdpVuidManager()
        let vuid2 = manager.vuid

        XCTAssertTrue(vuid1 == vuid2)
        XCTAssert(manager.isVuid(visitorId: vuid1))
        XCTAssert(manager.isVuid(visitorId: vuid2))
        
        UserDefaults.standard.removeObject(forKey: "optimizely-odp")
        
        manager = OdpVuidManager()
        let vuid3 = manager.vuid

        XCTAssertTrue(vuid1 != vuid3)
    }
}
