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

class DemoSwiftiOSUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        
        // To disable animations during UI Test, uncomment line below.
        // app.launchEnvironment = ["UITEST_DISABLE_ANIMATIONS" : "YES"]
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitialLayout() {
        // Tests if initial layout loads all expected elements.
        
        // given
        let variationText = app.staticTexts["VARIATION"]
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let a_Element = app.otherElements.containing(.staticText, identifier:"A").element
        let a_Text = app.staticTexts["A"]
        let b_Element = app.otherElements.containing(.staticText, identifier:"B").element
        let b_Text = app.staticTexts["B"]
        
        // then
        XCTAssertTrue(variationText.exists)
        XCTAssertTrue(testConversionButton.exists)
        XCTAssertTrue(a_Element.exists || b_Element.exists)
        if a_Element.exists {
            XCTAssertTrue(a_Text.exists)
            XCTAssertFalse(b_Element.exists)
            XCTAssertFalse(b_Text.exists)
        } else if b_Element.exists {
            XCTAssertTrue(b_Text.exists)
            XCTAssertFalse(a_Element.exists)
            XCTAssertFalse(a_Text.exists)
        }
    }

    func testConversion() {
        // Tests if Test Conversion button works and variation persists.
        
        // given
        let variationText = app.staticTexts["VARIATION"]
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let a_Element = app.otherElements.containing(.staticText, identifier:"A").element
        let a_Text = app.staticTexts["A"]
        let b_Element = app.otherElements.containing(.staticText, identifier:"B").element
        let b_Text = app.staticTexts["B"]
        
        // then
        XCTAssertTrue(variationText.exists)
        XCTAssertTrue(testConversionButton.exists)
        var variation: String!
        if a_Element.exists {
            variation = "A"
            XCTAssertTrue(a_Text.exists)
            XCTAssertFalse(b_Element.exists)
            XCTAssertFalse(b_Text.exists)
        } else if b_Element.exists {
            variation = "B"
            XCTAssertTrue(b_Text.exists)
            XCTAssertFalse(a_Element.exists)
            XCTAssertFalse(a_Text.exists)
        }
        
        // Click Test Conversion button
        testConversionButton.tap()
        
        // given
        let backButton = app.buttons["BACK"]
        let conversionElement = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element
        let conversionTextView = conversionElement.children(matching: .textView).element
  
        // then
        XCTAssertTrue(backButton.exists)
        XCTAssertTrue(conversionElement.exists)
        XCTAssertTrue(conversionTextView.exists)
        
        // Click back button
        backButton.tap()
        if variation == "A" {
            XCTAssertTrue(A_Element.exists)
            XCTAssertTrue(A_Text.exists)
            XCTAssertFalse(B_Element.exists)
            XCTAssertFalse(B_Text.exists)
        } else if variation == "B" {
            XCTAssertTrue(B_Element.exists)
            XCTAssertTrue(B_Text.exists)
            XCTAssertFalse(A_Element.exists)
            XCTAssertFalse(A_Text.exists)
        }
    }
    
    func testVariationPersistsInBackground() {
        // given
        let a_Text = app.staticTexts["A"]
        let b_Text = app.staticTexts["B"]
        
        // then
        var variation: String!
        if a_Text.exists {
            variation = "A"
            XCTAssertFalse(b_Text.exists)
        } else if b_Text.exists {
            variation = "B"
            XCTAssertFalse(a_Text.exists)
        }
        
        // press home, send app to background
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        // bring app back to foreground
        app.activate()
        
        // ensure that variation persists
        if variation == "A" {
            XCTAssertTrue(a_Text.exists)
            XCTAssertFalse(b_Text.exists)
        } else if variation == "B" {
            XCTAssertTrue(b_Text.exists)
            XCTAssertFalse(a_Text.exists)
        }
    }
    
    func testFlushBackground() {
        let staticLabel = app.staticTexts["Current # of Optimizely events:"]
        let testConversionButton = app.buttons["TEST CONVERSION"]
        let backButton = app.buttons["BACK"]
        XCTAssertTrue(staticLabel.exists)
        
        // Perform one conversion
        testConversionButton.tap()
        backButton.tap()
        
        // Background and foreground
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        app.activate()
        
        // async check if # of events flushes to 0.
        let zeroLabel = app.staticTexts["0"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: zeroLabel, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
