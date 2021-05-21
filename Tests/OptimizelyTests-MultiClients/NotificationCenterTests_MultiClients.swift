//
// Copyright 2021, Optimizely, Inc. and contributors 
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

class NotificationCenterTests_MultiClients: XCTestCase {
    
    let notificationCenter = DefaultNotificationCenter()
    let lock = DispatchQueue(label: "notif-lock")
    var counter = NotificationsCounter()

    func testConcurrentSend() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        counter = NotificationsCounter()
        
        _ = self.addTrackListener()
        _ = self.addDecisionListener()
        _ = self.addDatafileChangeListener()
        _ = self.addLogEventListener()

        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            (0..<numEventsPerThread).forEach { idx in
                self.sendTrack()
                self.sendDecision()
                self.sendDatafileChange()
                self.sendLogEvent()
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        self.lock.sync {}

        XCTAssertEqual(counter.activate, 0)
        XCTAssertEqual(counter.track, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.decision, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.datafileChange, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.logEvent, numThreads * numEventsPerThread)
    }
    
    func testConcurrentAdd() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        counter = NotificationsCounter()
        
        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            (0..<numEventsPerThread).forEach { idx in
                _ = self.addTrackListener()
                _ = self.addDecisionListener()
                _ = self.addDatafileChangeListener()
                _ = self.addLogEventListener()
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        self.sendTrack()
        self.sendDecision()
        self.sendDatafileChange()
        self.sendLogEvent()

        self.lock.sync {}

        XCTAssertEqual(counter.activate, 0)
        XCTAssertEqual(counter.track, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.decision, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.datafileChange, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.logEvent, numThreads * numEventsPerThread)
    }
    
    func testConcurrentAddRemove() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        counter = NotificationsCounter()
        
        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            (0..<numEventsPerThread).forEach { idx in
                _ = self.addTrackListener()
                _ = self.addDecisionListener()
                let idDatafileChange = self.addDatafileChangeListener()
                let idLogEvent = self.addLogEventListener()
                
                self.notificationCenter.removeNotificationListener(notificationId: idDatafileChange!)
                if idx % 2 == 0 {
                    self.notificationCenter.removeNotificationListener(notificationId: idLogEvent!)
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")

        self.sendTrack()
        self.sendDecision()
        self.sendDatafileChange()
        self.sendLogEvent()

        self.lock.sync {}
        
        XCTAssertEqual(counter.activate, 0)
        XCTAssertEqual(counter.track, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.decision, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.datafileChange, 0)
        XCTAssertEqual(counter.logEvent, numThreads * numEventsPerThread / 2)
    }
    
    func testConcurrentAddClear() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        counter = NotificationsCounter()
        
        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            (0..<numEventsPerThread).forEach { idx in
                _ = self.addTrackListener()
                _ = self.addDecisionListener()
                _ = self.addDatafileChangeListener()
                _ = self.addLogEventListener()
                
                self.notificationCenter.clearNotificationListeners(type: .track)
                self.notificationCenter.clearNotificationListeners(type: .decision)
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")

        self.sendTrack()
        self.sendDecision()
        self.sendDatafileChange()
        self.sendLogEvent()

        self.lock.sync {}
        
        XCTAssertEqual(counter.activate, 0)
        XCTAssertEqual(counter.track, 0)
        XCTAssertEqual(counter.decision, 0)
        XCTAssertEqual(counter.datafileChange, numThreads * numEventsPerThread)
        XCTAssertEqual(counter.logEvent, numThreads * numEventsPerThread)
    }
    
    func testConcurrentAddClearAll() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        counter = NotificationsCounter()
        
        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            (0..<numEventsPerThread).forEach { idx in
                _ = self.addTrackListener()
                _ = self.addDecisionListener()
                _ = self.addDatafileChangeListener()
                _ = self.addLogEventListener()
                
                self.notificationCenter.clearAllNotificationListeners()
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")

        self.sendTrack()
        self.sendDecision()
        self.sendDatafileChange()
        self.sendLogEvent()

        self.lock.sync {}
        
        XCTAssertEqual(counter.activate, 0)
        XCTAssertEqual(counter.track, 0)
        XCTAssertEqual(counter.decision, 0)
        XCTAssertEqual(counter.datafileChange, 0)
        XCTAssertEqual(counter.logEvent, 0)
    }

    // MARK: - Utils
    
    struct NotificationsCounter {
        var activate = 0
        var track = 0
        var decision = 0
        var datafileChange = 0
        var logEvent = 0
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
    
    func addTrackListener() -> Int? {
        let id = notificationCenter.addTrackNotificationListener { (_, _, _, _, _) in
            self.lock.async {
                self.counter.track += 1
            }
        }
        return id
    }
    
    func addDecisionListener() -> Int? {
        let id = notificationCenter.addDecisionNotificationListener { (_, _, _, _) in
            self.lock.async {
                self.counter.decision += 1
            }
        }
        return id
    }
    
    func addDatafileChangeListener() -> Int? {
        let id = notificationCenter.addDatafileChangeNotificationListener { (_) in
            self.lock.async {
                self.counter.datafileChange += 1
            }
        }
        return id
    }
    
    func addLogEventListener() -> Int? {
        let id = notificationCenter.addLogEventNotificationListener { (_, _) in
            self.lock.async {
                self.counter.logEvent += 1
            }
        }
        return id
    }

}
