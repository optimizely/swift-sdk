//
// Copyright 2019-2022, Optimizely, Inc. and contributors
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
        XCTAssertNoThrow(try optimizely?.start(datafile: datafile!))
    }

    override func tearDown() {
        optimizely = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConversionEventWithNoExperiment() {
        // serialized to JSON
        let conversion = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!,
                                                                 eventKey: eventWithNoExperimentKey,
                                                                 userId: userId,
                                                                 attributes: ["anyattribute": "value", "broswer_type": "firefox"],
                                                                 eventTags: ["browser": "chrome"])
        
        XCTAssertNotNil(conversion)
        
        // deserialized from JSON
        let batchEvent = try? JSONDecoder().decode(BatchEvent.self, from: conversion!)
        
        XCTAssertNotNil(batchEvent)
        
        XCTAssert((batchEvent?.enrichDecisions)! == true)
        XCTAssertEqual(batchEvent?.visitors[0].visitorID, userId)
    }

}
