//
//  BatchEventBuilderTest.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 2/28/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class BatchEventBuilderTest: XCTestCase {
    
    let datafileName = "valid-project-config-v4"
    let basicExperimentKey = "basic_experiment"
    let eventWithNoExperimentKey = "event_with_no_experiment"
    let userId = "userId"
    var optimizely:OptimizelyManager?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        optimizely = OptimizelyManager(sdkKey: "", periodicDownloadInterval: 0)
        
        let datafile = loadJSONDatafileIntoDataObject(datafile: datafileName)
        do {
            try optimizely?.initializeSDK(datafile: datafile!)
        }
        catch {
            print(error)
            XCTAssert(false)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let conversion = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!, decisionService: (optimizely?.decisionService)!, eventKey: eventWithNoExperimentKey, userId: userId, attributes: ["anyattribute":"value", "broswer_type":"firefox"], eventTags: nil)
        
        XCTAssertNotNil(conversion)
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
