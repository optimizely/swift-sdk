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

class NotificationCenterTests: XCTestCase {
    
    let notificationCenter: DefaultNotificationCenter = DefaultNotificationCenter()
    var experiment: Experiment?
    var variation: Variation?
    
    static var sampleVariation: [String: Any] = ["id": "553339214",
                                  "key": "house",
                                  "featureEnabled": true]
    
    static var sampleExperiment: [String: Any] = ["id": "11111",
                                            "key": "background",
                                            "status": "Running",
                                            "layerId": "22222",
                                            "variations": [sampleVariation],
                                            "trafficAllocation": [["entityId": "553339214", "endOfRange": 5000]],
                                            "audienceIds": ["33333"],
                                            "audienceConditions": [],
                                            "forcedVariations": ["12345": "1234567890"]]

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let data: [String: Any] = NotificationCenterTests.sampleExperiment
        
        experiment = try! OTUtils.model(from: data)
        
        variation = experiment!.variations[0]

        notificationCenter.clearAllNotificationListeners()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        notificationCenter.clearAllNotificationListeners()
    }
    
    func sendActivate() {
        notificationCenter.sendNotifications(type: NotificationType.activate.rawValue, args: [experiment!, "userId", nil, variation!, ["url": "https://url.com/", "body": Data()]])

    }

    func sendTrack() {
        notificationCenter.sendNotifications(type: NotificationType.track.rawValue, args: ["eventKey", "userId", nil, nil, ["url": "https://url.com/", "body": Data()]])
        
    }

    func sendDecision() {
        notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: [Constants.DecisionTypeKeys.featureVariable, "userId", nil, ["url": "https://url.com/", "body": Data()]])
        
    }

    func sendDatafileChange() {
        notificationCenter.sendNotifications(type: NotificationType.datafileChange.rawValue, args: [Data()])
        
    }

    func testNotificationCenterAddRemoveActivate() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        _ = notificationCenter.addActivateNotificationListener { (_, _, _, _, _) in
                called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .activate)
        
        sendActivate()
        
        XCTAssertFalse(called)

        let id = notificationCenter.addActivateNotificationListener { (_, _, _, _, _) in
            called = true
        }
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendActivate()
        
        XCTAssertFalse(called)

        _ = notificationCenter.addActivateNotificationListener { (_, _, _, _, _) in
            called = true
        }

        sendActivate()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveTrack() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        _ = notificationCenter.addTrackNotificationListener { (_, _, _, _, _) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .track)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addTrackNotificationListener { (_, _, _, _, _) in
            called = true
        }

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        _ = notificationCenter.addTrackNotificationListener { (_, _, _, _, _) in
            called = true
        }

        sendTrack()
        
        XCTAssertTrue(called)
    }
    
    func testNotificationCenterAddRemoveDecision() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, _) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .decision)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addDecisionNotificationListener { (_, _, _, _) in
            called = true
        }
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, _) in
            called = true
        }
        
        sendDecision()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveDatafileChange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        _ = notificationCenter.addDatafileChangeNotificationListener { (_) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .datafileChange)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addDatafileChangeNotificationListener { (_) in
            called = true
        }

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        _ = notificationCenter.addDatafileChangeNotificationListener { (_) in
            called = true
        }

        sendDatafileChange()
        
        XCTAssertTrue(called)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
