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

class EventDispatcherTests: XCTestCase {
    
    var eventDispatcher: DefaultEventDispatcher!
    let sdkKey = "any key"
    lazy var simpleEvent = EventForDispatch(sdkKey: sdkKey, body: Data())

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if (!FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
                
            }
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        if let dispatcher = eventDispatcher {
            dispatcher.clear()
        }
        
        eventDispatcher = nil
    }

    func testDefaultDispatcher() {
        eventDispatcher = DefaultEventDispatcher(timerInterval: 10)
        eventDispatcher.clear()
        
        eventDispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)
        eventDispatcher.sync()
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventDispatcher?.dataStore.count == 1)
        } else {
            XCTAssert(eventDispatcher?.dataStore.count == 0)
        }
        eventDispatcher.flushEvents()
        eventDispatcher.sync()
        
        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testDispatcherZeroTimeInterval() {
        class InnerEventDispatcher: DefaultEventDispatcher {
            var once = false
            var events: [EventForDispatch] = [EventForDispatch]()
            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                events.append(event)
                if !once {
                    self.dataStore.save(item: EventForDispatch(sdkKey: "a", body: Data()))
                    once = true
                }
                completionHandler(.success(Data()))
            }
        }
        
        let dispatcher = InnerEventDispatcher(timerInterval: 0)

        // add two items.... call flush
        dispatcher.dataStore.save(item: simpleEvent)
        dispatcher.flushEvents()
        dispatcher.sync()
        
        XCTAssert(dispatcher.events.count == 2)
    }

    func testEventDispatcherFile() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .file)
        eventDispatcher.timerInterval = 1

        eventDispatcher.flushEvents()
        eventDispatcher.sync()
        
        eventDispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)
        eventDispatcher.sync()

        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventDispatcher?.dataStore.count == 1)
        } else {
            XCTAssert(eventDispatcher?.dataStore.count == 0)
        }

        eventDispatcher.flushEvents()
        eventDispatcher.sync()

        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEventDispatcherUserDefaults() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .userDefaults)
        eventDispatcher.timerInterval = 1

        eventDispatcher.flushEvents()
        eventDispatcher.sync()

        eventDispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)
        eventDispatcher.sync()

        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventDispatcher?.dataStore.count == 1)
        } else {
            XCTAssert(eventDispatcher?.dataStore.count == 0)
        }

        eventDispatcher.flushEvents()
        eventDispatcher.sync()

        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testEventDispatcherMemory() {
        eventDispatcher = DefaultEventDispatcher( backingStore: .memory)
        eventDispatcher.timerInterval = 1

        eventDispatcher.flushEvents()
        eventDispatcher.sync()

        eventDispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)
        eventDispatcher.sync()

        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventDispatcher?.dataStore.count == 1)
        } else {
            XCTAssert(eventDispatcher?.dataStore.count == 0)
        }

        eventDispatcher.flushEvents()
        eventDispatcher.sync()

        XCTAssert(eventDispatcher?.dataStore.count == 0)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testDispatcherCustom() {
        let dispatcher = FakeEventDispatcher()
        
        dispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)

        XCTAssert(dispatcher.events.count == 1)
        
        dispatcher.flushEvents()
        
        XCTAssert(dispatcher.events.count == 0)
    }
    
    func testDispatcherMethods() {
        eventDispatcher = DefaultEventDispatcher(timerInterval: 1)
        
        eventDispatcher.flushEvents()
        eventDispatcher.sync()
        
        eventDispatcher.dispatchEvent(event: simpleEvent, completionHandler: nil)
        eventDispatcher.sync()
        
        eventDispatcher.applicationDidBecomeActive()
        eventDispatcher.applicationDidEnterBackground()
        
        XCTAssert(eventDispatcher?.timer.property == nil)
        var sent = false
        
        let group = DispatchGroup()
        
        group.enter()
        
        eventDispatcher.sendEvent(event: simpleEvent) { (_) -> Void in
            sent = true
            group.leave()
        }
        group.wait()
        XCTAssert(sent)
        
        group.enter()
        
        eventDispatcher?.startTimer()
        
        DispatchQueue.global(qos: .background).async {
            group.leave()
        }
        group.wait()
        
        // we are on the main thread and set timer on async main thread
        // so, must be nil here
        XCTAssert(eventDispatcher?.timer.property == nil)

    }
    
    func testDispatcherZeroBatchSize() {
        let eventDispatcher = DefaultEventDispatcher(batchSize: 0, backingStore: .userDefaults, dataStoreName: "DoNothing", timerInterval: 0)
        
        XCTAssert(eventDispatcher.batchSize > 0)
    }
    
    func testDataStoreQueue() {
        let queue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreMemory<Array<Data>>(storeName: "backingStoreName"))
        
        queue.save(item: EventForDispatch(sdkKey: sdkKey, body: "Blah".data(using: .utf8)!))
        
        let event = queue.getFirstItem()
        let str = String(data: (event?.body)!, encoding: .utf8)
        
        XCTAssert(str == "Blah")
        
        XCTAssert(queue.count == 1)
        
        let event2 = queue.getLastItem()

        let str2 = String(data: (event2?.body)!, encoding: .utf8)
        
        XCTAssert(str2 == "Blah")
        
        XCTAssert(queue.count == 1)
        
        _ = queue.removeFirstItem()
        
        XCTAssert(queue.count == 0)
        
        _ = queue.removeLastItem()
        
        XCTAssert(queue.count == 0)
    }    
}
