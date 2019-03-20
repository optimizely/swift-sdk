//
//  EventDispatcherTest.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/19/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class EventDispatcherTest: XCTestCase {
    
    var eventDispatcher:DefaultEventDispatcher?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if (!FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                }
                catch {
                    print(error)
                }
                
            }
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let group = DispatchGroup()
        group.enter()
        
        if let dispatcher = eventDispatcher {
            dispatcher.flushEvents()
            dispatcher.dispatcher.sync {
                group.leave()
            }
            group.wait()
        }
        
        eventDispatcher = nil
        
    }

    func testDefaultDispatcher() {
        eventDispatcher = DefaultEventDispatcher()
        let pEventD:OPTEventDispatcher = eventDispatcher!
        eventDispatcher?.timerInterval = 1
        let group = DispatchGroup()
        
        pEventD.flushEvents()
        
        group.enter()
        
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        
        group.wait()
        
        pEventD.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            
        }
        
        group.enter()
        
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        
        group.wait()

        XCTAssert(eventDispatcher?.dataStore.count == 1)
        
        eventDispatcher?.flushEvents()
        
        group.enter()
        
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        
        group.wait()

        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEventDispatcherFile() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .file)
        let pEventD:OPTEventDispatcher = eventDispatcher!
        eventDispatcher?.timerInterval = 1
        
        pEventD.flushEvents()
        
        sleep(3)
        
        pEventD.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            
        }
        
        sleep(2)
        
        XCTAssert(eventDispatcher?.dataStore.count == 1)
        
        sleep(2)
        
        eventDispatcher?.flushEvents()
        
        sleep(3)
        
        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEventDispatcherUserDefaults() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .userDefaults)
        let pEventD:OPTEventDispatcher = eventDispatcher!
        eventDispatcher?.timerInterval = 1
        
        pEventD.flushEvents()
        
        sleep(3)
        
        pEventD.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            
        }
        
        sleep(2)
        
        XCTAssert(eventDispatcher?.dataStore.count == 1)
        
        sleep(2)
        
        eventDispatcher?.flushEvents()
        
        sleep(3)
        
        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEventDispatcherMemory() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .memory)
        let pEventD:OPTEventDispatcher = eventDispatcher!
        eventDispatcher?.timerInterval = 1
        
        pEventD.flushEvents()
        
        sleep(3)
        
        pEventD.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            
        }
        
        let group = DispatchGroup()
        
        group.enter()
        
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        
        group.wait()
        
        XCTAssert(eventDispatcher?.dataStore.count == 1)
        
        
        group.enter()
        eventDispatcher?.flushEvents()
        
        eventDispatcher?.dispatcher.async {
            group.leave()
        }
        
        group.wait()
        
        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testDispatcherCustom() {
        class Dispatcher: OPTEventDispatcher {
            var events:[EventForDispatch] = [EventForDispatch]()
            
            required init() {
                
            }
            
            func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                events.append(event)
            }
            
            func flushEvents() {
                events.removeAll()
            }
        }
        
        let dispatcher = Dispatcher() as OPTEventDispatcher
        
        dispatcher.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            
        }
        
        XCTAssert((dispatcher as! Dispatcher).events.count == 1)
        
        dispatcher.flushEvents()
        
        XCTAssert((dispatcher as! Dispatcher).events.count == 0)
    }
    
    func testDispatcherMethods() {
        eventDispatcher = DefaultEventDispatcher()
        let group = DispatchGroup()
        
        group.enter()
        eventDispatcher?.flushEvents()
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        group.wait()
        
        group.enter()
        
        eventDispatcher?.dispatchEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
        }
        
        eventDispatcher?.dispatcher.sync {
            group.leave()
        }
        
        group.wait()
        
        eventDispatcher?.applicationDidBecomeActive()

        eventDispatcher?.applicationDidEnterBackground()
        
        XCTAssert(eventDispatcher?.timer.property == nil)
        var sent = false
        group.enter()
        
        eventDispatcher?.sendEvent(event: EventForDispatch(body: Data())) { (result) -> (Void) in
            sent = true
            group.leave()
        }
        group.wait()
        XCTAssert(sent)
        
        eventDispatcher?.setTimer()
        
        sleep(4)
        
        // we are on the main thread and set timer on async main thread
        // so, must be nil here
        XCTAssert(eventDispatcher?.timer.property == nil)

    }
    
    func testDataStoreQueue() {
        let queue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreMemory<Array<Data>>(storeName: "backingStoreName"))
        
        queue.save(item: EventForDispatch(body: "Blah".data(using: .utf8)!))
        
        let event = queue.getFirstItem()
        let str = String(data: (event?.body)!, encoding: .utf8)
        
        XCTAssert(str == "Blah")
        
        XCTAssert(queue.count == 1)
        
        let event2 = queue.getLastItem()

        let str2 = String(data: (event2?.body)!, encoding: .utf8)
        
        XCTAssert(str2 == "Blah")
        
        XCTAssert(queue.count == 1)
        
        let _ = queue.removeFirstItem()
        
        XCTAssert(queue.count == 0)
        
        let _ = queue.removeLastItem()
        
        XCTAssert(queue.count == 0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
