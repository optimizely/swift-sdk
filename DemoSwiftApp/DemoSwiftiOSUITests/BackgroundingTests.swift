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

class BackgroundingTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        
        // To disable animations during UI Test, uncomment line below.
        app.launchEnvironment = ["UITEST_DISABLE_ANIMATIONS" : "YES"]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFlushBackground() {
        // Tests if dataStore queue size flushes to 0 after performing one conversion and backgrounding.
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        
        // Perform 1 conversion
        testConversionButton.tap()
        backButton.tap()
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // async check if dataStore queue size is 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testEmptyQueueFlush() {
        // Tests to ensure nothing breaks when backgrounding with an empty queue.
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        
        // Perform 1 conversion
        testConversionButton.tap()
        backButton.tap()
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // async check if dataStore queue size is 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // Background and foreground again
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // check again if queue size is 0.
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testBatchFlush() {
        // Tests if dataStore queue size flushes to 0 after performing five conversions and backgrounding.
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        
        // Initial queue flush.
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // Perform 5 conversions
        for _ in 1...5 {
            testConversionButton.tap()
            backButton.tap()
        }
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // async check if dataStore queue size is 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGreaterThanBatchFlush() {
        // Tests if dataStore queue size flushes completely after performing twelve conversions and backgrounding.
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        
        // Initial queue flush.
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // async check if queue size is 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // Perform 12 conversions
        for _ in 1...12 {
            testConversionButton.tap()
            backButton.tap()
        }
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        
        // async check if entire queue is flushed.
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testBackgroundingTwice() {
        // Tests if backgrounding, adding more events to queue, and backgrounding again flushes the queue completely.
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        
        // Initial queue flush.
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        // async check if queue size is 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // Perform 16 conversions
        for _ in 1...16 {
            testConversionButton.tap()
            backButton.tap()
        }
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        
        // async check if all events are flushed.
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        // Perform 7 more conversions.
        for _ in 1...7 {
            testConversionButton.tap()
            backButton.tap()
        }
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        
        
        // async check if all events are flushed.
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}

