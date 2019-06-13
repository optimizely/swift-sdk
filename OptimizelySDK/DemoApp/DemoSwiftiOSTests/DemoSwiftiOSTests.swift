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
import Optimizely
@testable import DemoSwiftiOS

open class DemoSwiftiOSTests: XCTestCase {
    
    var sut: AppDelegate!

    override open func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = AppDelegate()
    }

    override open func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBackgrounding() {
        
        let dispatcher = DefaultEventDispatcher.sharedInstance
        let eventsCount = dispatcher.dataStore.count
        print("# events before backgrounding:", eventsCount)
        
        // wait for app to load
        // press home, send app to background
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        // bring app back to foreground
//        let app = XCUIApplication()
        sleep(5)
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        
        let eventsCount2 = dispatcher.dataStore.count
        print("# events after backgrounding:", eventsCount2)
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
