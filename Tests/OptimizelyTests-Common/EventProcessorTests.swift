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

class EventProcessorTests: XCTestCase {
    
    var eventProcessor: BatchEventProcessor!
    var eventDispatcher: HTTPEventDispatcher!
    
    let sdkKey = "any key"
    let userId = "a"
    let experimentKey = "exp_with_audience"

    var simpleBatchEvent: EventForDispatch {
        return EventForDispatch(sdkKey: sdkKey, body: Data())
    }
    var simpleUserEvent: UserEvent {
        let data = OTUtils.loadJSONDatafile("empty_datafile")!
        let config = try! ProjectConfig(datafile: data, sdkKey: sdkKey)
        let userContext = UserContext(config: config, userId: userId, attributes: nil)

        return ImpressionEvent(userContext: userContext,
                                               layerId: "a",
                                               experimentKey: "e",
                                               experimentId: "e",
                                               variationKey: "v",
                                               variationId: "v")
    }
            
    override func setUp() {
    }

    override func tearDown() {
        eventProcessor?.clear()
        eventProcessor = nil
    }
    
    func testOptimizelyInit_DefaultEventProcessor() {
        let eventDispatcher = MockEventDispatcher()
        
        let optimizely = OTUtils.createOptimizely(sdkKey: sdkKey,
                                                  datafileName: "api_datafile",
                                                  clearUserProfileService: true,
                                                  eventProcessor: nil,
                                                  eventDispatcher: eventDispatcher)!
        _ = try! optimizely.activate(experimentKey: experimentKey, userId: userId)

        optimizely.eventProcessor!.clear()
        XCTAssertEqual(eventDispatcher.events.count, 1)
    }

    func testOptimizelyInit_CustomEventProcessor() {
        let eventDispatcher = MockEventDispatcher()
        let eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher, batchSize: 1)
        
        let optimizely = OTUtils.createOptimizely(sdkKey: sdkKey,
                                                  datafileName: "api_datafile",
                                                  clearUserProfileService: true,
                                                  eventProcessor: eventProcessor)!
        _ = try! optimizely.activate(experimentKey: experimentKey, userId: userId)

        eventProcessor.clear()
        XCTAssertEqual(eventDispatcher.events.count, 1)
    }
    
    func testDefaultDispatcher() {
        eventDispatcher = HTTPEventDispatcher()
        eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher,
                                             timerInterval: 10)
        eventProcessor.clear()
        
        eventProcessor.process(event: simpleUserEvent, completionHandler: nil)
        eventProcessor.sync()
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventProcessor.dataStore.count == 1)
        } else {
            XCTAssert(eventProcessor.dataStore.count == 0)
        }
        eventProcessor.flush()
        eventProcessor.sync()
        
        XCTAssert(eventProcessor.dataStore.count == 0)
    }
    
    func testEventDispatcherFile() {
        eventDispatcher = HTTPEventDispatcher()
        eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher,
                                             timerInterval: 1,
                                             backingStore: .file)
        eventProcessor.clear()
        
        eventProcessor.process(event: simpleUserEvent, completionHandler: nil)
        eventProcessor.sync()
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventProcessor.dataStore.count == 1)
        } else {
            XCTAssert(eventProcessor.dataStore.count == 0)
        }
        eventProcessor.flush()
        eventProcessor.sync()
        
        XCTAssert(eventProcessor.dataStore.count == 0)
    }
    
    func testEventDispatcherUserDefaults() {
        eventDispatcher = HTTPEventDispatcher()
        eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher,
                                             timerInterval: 1,
                                             backingStore: .userDefaults)
        eventProcessor.clear()
        
        eventProcessor.process(event: simpleUserEvent, completionHandler: nil)
        eventProcessor.sync()
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventProcessor.dataStore.count == 1)
        } else {
            XCTAssert(eventProcessor.dataStore.count == 0)
        }
        eventProcessor.flush()
        eventProcessor.sync()
        
        XCTAssert(eventProcessor.dataStore.count == 0)
    }

    func testEventDispatcherMemory() {
        eventDispatcher = HTTPEventDispatcher()
        eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher,
                                             timerInterval: 1,
                                             backingStore: .memory)
        eventProcessor.clear()
        
        eventProcessor.process(event: simpleUserEvent, completionHandler: nil)
        eventProcessor.sync()
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssert(eventProcessor.dataStore.count == 1)
        } else {
            XCTAssert(eventProcessor.dataStore.count == 0)
        }
        eventProcessor.flush()
        eventProcessor.sync()
        
        XCTAssert(eventProcessor.dataStore.count == 0)
    }

    func testDispatcherMethods() {
        eventDispatcher = HTTPEventDispatcher()
        eventProcessor = BatchEventProcessor(eventDispatcher: eventDispatcher,
                                             timerInterval: 10)
        eventProcessor.clear()

        eventProcessor.process(event: simpleUserEvent, completionHandler: nil)
        eventProcessor.sync()

        eventProcessor.applicationDidBecomeActive()
        eventProcessor.applicationDidEnterBackground()

        XCTAssert(eventProcessor.timer.property == nil)
        var sent = false

        let group = DispatchGroup()

        group.enter()
        eventDispatcher.dispatch(event: simpleBatchEvent) { _ in
            sent = true
            group.leave()
        }
        group.wait()
        XCTAssert(sent)

        group.enter()
        eventProcessor.startTimer()
        DispatchQueue.global(qos: .background).async {
            group.leave()
        }
        group.wait()

        // we are on the main thread and set timer on async main thread
        // so, must be nil here
        XCTAssert(eventProcessor.timer.property == nil)
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
