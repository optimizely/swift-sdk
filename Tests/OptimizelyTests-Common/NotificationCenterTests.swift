//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class NotificationCenterTests: XCTestCase {
    
    var notificationCenter: DefaultNotificationCenter!
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
         super.setUp()
        
        let data: [String: Any] = NotificationCenterTests.sampleExperiment
        
        experiment = try! OTUtils.model(from: data)
        
        variation = experiment!.variations[0]

        notificationCenter = DefaultNotificationCenter()
        notificationCenter.clearAllNotificationListeners()
    }

    override func tearDown() {
        notificationCenter.clearAllNotificationListeners()
        notificationCenter = nil  // deinit immediately after each test
        super.tearDown()
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
    
    func testNotificationCenterThreadSafe() {
        let numConcurrency = 5
        
        let exp = expectation(description: "x")
        exp.expectedFulfillmentCount = numConcurrency

        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(0)) {
            _ = self.addActivateListener()
            for _ in 0..<100000 { self.sendActivate() }
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(100)) {
            _ = self.addTrackListener()
            for _ in 0..<10000 { self.sendTrack() }
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(200)) {
            _ = self.addDecisionListener()
            for _ in 0..<1000 { self.sendDecision() }
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            _ = self.addDatafileChangeListener()
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(20)) {
            _ = self.addLogEventListener()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10.0)
        XCTAssertEqual(notificationCenter.notificationId - 1, numConcurrency)
    }
    
    func testNotificationCenterThreadSafe_Remove() {
        let numConcurrency = 5
        
        let exp = expectation(description: "x")
        exp.expectedFulfillmentCount = numConcurrency

        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(0)) {
            _ = self.addActivateListener()
            for _ in 0..<100 { self.sendActivate() }
            self.notificationCenter.clearNotificationListeners(type: .activate)
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            _ = self.addTrackListener()
            for _ in 0..<100 { self.sendTrack() }
            self.notificationCenter.clearNotificationListeners(type: .track)
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            _ = self.addDecisionListener()!
            for _ in 0..<100 { self.sendDecision() }
            self.notificationCenter.clearNotificationListeners(type: .decision)
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            let id = self.addDatafileChangeListener()!
            for _ in 0..<100 { self.sendDatafileChange() }
            self.notificationCenter.removeNotificationListener(notificationId: id)
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            let id = self.addLogEventListener()!
            for _ in 0..<100 { self.sendLogEvent() }
            self.notificationCenter.removeNotificationListener(notificationId: id)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10.0)
        
        self.called = false
        
        sendActivate()
        sendTrack()
        sendDecision()
        sendDatafileChange()
        sendLogEvent()

        XCTAssertFalse(called)
    }
    
    func testNotificationCenterThreadSafe_AddRemove() {
        let numConcurrency = 3
        
        let exp = expectation(description: "x")
        exp.expectedFulfillmentCount = numConcurrency

        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(0)) {
            for _ in 0..<1000 {
                let id = self.addActivateListener()!
                self.notificationCenter.removeNotificationListener(notificationId: id)
            }
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            for _ in 0..<1000 {
                let id = self.addTrackListener()!
                self.notificationCenter.removeNotificationListener(notificationId: id)
            }
            exp.fulfill()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(10)) {
            for _ in 0..<1000 {
                let id = self.addDecisionListener()!
                self.notificationCenter.removeNotificationListener(notificationId: id)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 10.0)

        self.called = false
        
        sendActivate()
        sendTrack()

        XCTAssertFalse(called)
    }
    
}
