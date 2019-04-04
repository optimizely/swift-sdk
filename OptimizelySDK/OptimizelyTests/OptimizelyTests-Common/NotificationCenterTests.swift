//
//  NotificationCenterTests.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/20/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class NotificationCenterTests: XCTestCase {
    
    let notificationCenter:DefaultNotificationCenter = DefaultNotificationCenter()
    var experiment:Experiment?
    var variation:Variation?
    
    static var sampleVariation: [String : Any] = ["id": "553339214",
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
        notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment!, "userId", nil, variation!, ["url":"https://url.com/", "body": Data()]])

    }

    func sendTrack() {
        notificationCenter.sendNotifications(type: NotificationType.Track.rawValue, args: ["eventKey", "userId", nil, nil, ["url":"https://url.com/", "body": Data()]])
        
    }
    
    func sendDecision() {
        notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: [Constants.DecisionTypeKeys.experiment, "userId", nil, ["url":"https://url.com/", "body": Data()]])
        
    }

    func sendDatafileChange() {
        notificationCenter.sendNotifications(type: NotificationType.DatafileChange.rawValue, args: [Data()])
        
    }

    func sendFeatureFlagToggle() {
        notificationCenter.sendNotifications(type: NotificationType.FeatureFlagRolloutToggle.rawValue, args: ["featureFlagKey", FeatureFlagToggle.on])
        
    }

    func testNotificationCenterAddRemoveActivate() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        let _ = notificationCenter.addActivateNotificationListener { (experiment, userid, attributes, variation, logEvent) in
                called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .Activate)
        
        sendActivate()
        
        XCTAssertFalse(called)

        let id = notificationCenter.addActivateNotificationListener { (experiment, userid, attributes, variation, logEvent) in
            called = true
        }
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendActivate()
        
        XCTAssertFalse(called)

        let _ = notificationCenter.addActivateNotificationListener { (experiment, userid, attributes, variation, logEvent) in
            called = true
        }

        sendActivate()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveTrack() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        let _ = notificationCenter.addTrackNotificationListener { (eventKey, userId, attr, eventTags, logEvent) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .Track)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addTrackNotificationListener { (eventKey, userId, attr, eventTags, logEvent) in
            called = true
        }

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendTrack()
        
        XCTAssertFalse(called)
        
        let _ = notificationCenter.addTrackNotificationListener { (eventKey, userId, attr, eventTags, logEvent) in
            called = true
        }

        sendTrack()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveDecision() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        let _ = notificationCenter.addDecisionNotificationListener { (type, userId, attr, decisionInfo) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .Decision)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addDecisionNotificationListener { (type, userId, attr, decisionInfo) in
            called = true
        }
        
        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDecision()
        
        XCTAssertFalse(called)
        
        let _ = notificationCenter.addDecisionNotificationListener { (type, userId, attr, decisionInfo) in
            called = true
        }
        
        sendDecision()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveDatafileChange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        let _ = notificationCenter.addDatafileChangeNotificationListener { (data) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .DatafileChange)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addDatafileChangeNotificationListener { (data) in
            called = true
        }

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendDatafileChange()
        
        XCTAssertFalse(called)
        
        let _ = notificationCenter.addDatafileChangeNotificationListener { (data) in
            called = true
        }

        sendDatafileChange()
        
        XCTAssertTrue(called)
    }

    func testNotificationCenterAddRemoveFeatureFlagChange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var called = false
        
        let _ = notificationCenter.addFeatureFlagRolloutChangeListener { (featureKey, toggle) in
            called = true
        }
        
        notificationCenter.clearNotificationListeners(type: .FeatureFlagRolloutToggle)
        
        sendFeatureFlagToggle()
        
        XCTAssertFalse(called)
        
        let id = notificationCenter.addFeatureFlagRolloutChangeListener { (featureKey, toggle) in
            called = true
        }

        notificationCenter.removeNotificationListener(notificationId: id!)
        
        sendFeatureFlagToggle()
        
        XCTAssertFalse(called)
        
        let _ = notificationCenter.addFeatureFlagRolloutChangeListener { (featureKey, toggle) in
            called = true
        }

        sendFeatureFlagToggle()
        
        XCTAssertTrue(called)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
