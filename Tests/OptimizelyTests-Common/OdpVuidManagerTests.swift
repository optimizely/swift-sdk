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
    var manager = OdpVuidManager(enabled: true)
    
    func testNewVuid() {
        let vuid = OdpVuidManager.newVuid
        
        XCTAssertTrue(vuid.starts(with: "vuid_"))
        XCTAssertEqual(vuid.count, 32)
    }
    
    func testIsVuid() {
        XCTAssertTrue(OdpVuidManager.isVuid("vuid_123"))
        XCTAssertFalse(OdpVuidManager.isVuid("vuid-123"))
        XCTAssertFalse(OdpVuidManager.isVuid("123"))
    }
    
    func testAutoSaveAndLoad() {
        UserDefaults.standard.removeObject(forKey: "optimizely-vuid")
        
        manager = OdpVuidManager(enabled: true)
        let vuid1 = manager.vuid
        
        manager = OdpVuidManager(enabled: true)
        let vuid2 = manager.vuid

        XCTAssertTrue(vuid1 == vuid2)
        XCTAssert(OdpVuidManager.isVuid(vuid1))
        XCTAssert(OdpVuidManager.isVuid(vuid2))
        
        UserDefaults.standard.removeObject(forKey: "optimizely-vuid")
        
        manager = OdpVuidManager(enabled: true)
        let vuid3 = manager.vuid

        XCTAssertTrue(vuid1 != vuid3)
    }
}
