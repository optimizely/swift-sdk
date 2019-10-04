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
    var called = false
    
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
        notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: [Constants.DecisionType.featureVariable.rawValue, "userId", nil, ["url": "https://url.com/", "body": Data()]])
    }

    func sendDatafileChange() {
        notificationCenter.sendNotifications(type: NotificationType.datafileChange.rawValue, args: [Data()])
    }
    
    func sendLogEvent() {
        notificationCenter.sendNotifications(type: NotificationType.logEvent.rawValue, args: ["https://url.com/", [:]])
    }
    
    func addActivateListener() -> Int? {
        let id = notificationCenter.addActivateNotificationListener { (_, _, _, _, _) in
            self.called = true
        }
        return id
    }
    
    func addTrackListener() -> Int? {
        let id = notificationCenter.addTrackNotificationListener { (_, _, _, _, _) in
            self.called = true
        }
        return id
    }
    
    func addDecisionListener() -> Int? {
        let id = notificationCenter.addDecisionNotificationListener { (_, _, _, _) in
            self.called = true
        }
        return id
    }
    
    func addDatafileChangeListener() -> Int? {
        let id = notificationCenter.addDatafileChangeNotificationListener { (_) in
            self.called = true
        }
        return id
    }
    
    func addLogEventListener() -> Int? {
        let id = notificationCenter.addLogEventNotificationListener { (_, _) in
            self.called = true
        }
        return id
    }

    

    func testNotificationCenterAddRemoveActivate() {
        called = false
        
        _ = self.addActivateListener()
        
        notificationCenter.clearNotificationListeners(type: .activate)
        
        sendActivate()
        
        XCTAssertFalse(called)

        let id = self.addActivateListener()
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendActivate()
        
        XCTAssertFalse(called)

        _ = addActivateListener()

        sendActivate()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveTrack() {
        called = false
        
        _ = self.addTrackListener()
        
        notificationCenter.clearNotificationListeners(type: .track)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        let id = self.addTrackListener()

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        _ = self.addTrackListener()

        sendTrack()
        
        XCTAssertTrue(called)
    }
    
    func testNotificationCenterAddRemoveDecision() {
        called = false
        
        _ = self.addDecisionListener()
        
        notificationCenter.clearNotificationListeners(type: .decision)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        let id = self.addDecisionListener()
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        _ = self.addDecisionListener()
        
        sendDecision()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveDatafileChange() {
        called = false
        
        _ = self.addDatafileChangeListener()
        
        notificationCenter.clearNotificationListeners(type: .datafileChange)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        let id = self.addDatafileChangeListener()

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        _ = self.addDatafileChangeListener()

        sendDatafileChange()
        
        XCTAssertTrue(called)
    }
    
    func testNotificationCenterAddRemoveLogEvent() {
        called = false
        
        _ = addLogEventListener()
        
        notificationCenter.clearNotificationListeners(type: .logEvent)
        
        sendLogEvent()
        
        XCTAssertFalse(called)
        
        let id = addLogEventListener()
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendLogEvent()
        
        XCTAssertFalse(called)
        
        _ = addLogEventListener()
        
        sendLogEvent()
        
        XCTAssertTrue(called)
    }
    


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
