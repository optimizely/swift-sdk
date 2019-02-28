//
//  BatchEventBuilderTest.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 2/28/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class BatchEventBuilderTest: XCTestCase {
    
    let datafileName = "feature_experiments"
    let featureExperimentKey = "feature_targeted_exp"
    let eventWithNoExperimentKey = "unused_event"
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
        optimizely = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConversionEventWithNoExperiment() {
        let conversion = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!, decisionService: (optimizely?.decisionService)!, eventKey: eventWithNoExperimentKey, userId: userId, attributes: ["anyattribute":"value", "broswer_type":"firefox"], eventTags: nil)
        
        XCTAssertNotNil(conversion)
        
        let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: conversion!)
        
        XCTAssertNotNil(batchEvent)
        
        XCTAssert((batchEvent?.enrichDecisions)! == true)
        
    }

    func testImpressionEventWithNoExperiment() {
        let experiment = optimizely?.config.project.experiments.filter({$0.key == featureExperimentKey}).first
        let variation = experiment?.variations[0]
        
        let impression = BatchEventBuilder.createImpressionEvent(config: (optimizely?.config)!, decisionService: (optimizely?.decisionService)!, experiment: experiment!, varionation: variation!, userId: userId, attributes: ["customattr": "yes" ])
        
        XCTAssertNotNil(impression)
        let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: impression!)
        
        XCTAssertNotNil(batchEvent)
        
        XCTAssert((batchEvent?.enrichDecisions)! == true)
        
        XCTAssert(batchEvent?.visitors[0].attributes[0].key == "customattr")
        //XCTAssert(batchEvent?.visitors[0].attributes[0].value == .string)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
