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

class BatchEventBuilderTests: XCTestCase {
    
    let datafileName = "feature_experiments"
    let featureExperimentKey = "feature_targeted_exp"
    let eventWithNoExperimentKey = "unused_event"
    let userId = "userId"
    var optimizely: OptimizelyClient?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        optimizely = OptimizelyClient(sdkKey: "", periodicDownloadInterval: 0)
        
        let datafile = OTUtils.loadJSONDatafile(datafileName)
        do {
            try optimizely?.start(datafile: datafile!)
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
        let conversion = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!,  eventKey: eventWithNoExperimentKey, userId: userId, attributes: ["anyattribute":"value", "broswer_type":"firefox"], eventTags: nil)
        
        XCTAssertNotNil(conversion)
        
        let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: conversion!)
        
        XCTAssertNotNil(batchEvent)
        
        XCTAssert((batchEvent?.enrichDecisions)! == true)
        
    }

    func testImpressionEventWithNoExperiment() {
        let experiment = optimizely?.config?.project.experiments.filter({$0.key == featureExperimentKey}).first
        let variation = experiment?.variations[0]
        
        let impression = BatchEventBuilder.createImpressionEvent(config: (optimizely?.config)!, experiment: experiment!, varionation: variation!, userId: userId, attributes: ["customattr": "yes" ])
        
        XCTAssertNotNil(impression)
        let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: impression!)
        
        XCTAssertNotNil(batchEvent)
        
        XCTAssert((batchEvent?.enrichDecisions)! == true)
        
        XCTAssert(batchEvent?.visitors[0].attributes[0].key == "customattr")
        //XCTAssert(batchEvent?.visitors[0].attributes[0].value == .string)
    }

}
