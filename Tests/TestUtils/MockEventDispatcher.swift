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

import Foundation

class MockEventDispatcher: OPTEventDispatcher {
    public var events = [EventForDispatch]()
    public var totalEventsFlushed: Int
    
    init() {
        totalEventsFlushed = 0
    }
    
    func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        events.append(event)
    }
    
    func flushEvents() {
        totalEventsFlushed += events.count
        events.removeAll()
    }
}

class MockDefaultEventDispatcher: DefaultEventDispatcher {
    var withError: Bool

    init(withError: Bool) {
        self.withError = withError
        super.init()
    }

    override func getSession() -> URLSession {
        return MockUrlSession(withError: withError)
    }
}


class DumpEventDispatcher: DefaultEventDispatcher {
    public var totalEventsSent: Int

    init(dataStoreName: String = "OPTEventQueue", timerInterval: TimeInterval = DefaultValues.timeInterval) {
        totalEventsSent = 0
        super.init(dataStoreName: dataStoreName, timerInterval: timerInterval)
    }

    override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        if let decodedEvent = try? JSONDecoder().decode(BatchEvent.self, from: event.body) {
            totalEventsSent += decodedEvent.visitors.count
        }
    
        completionHandler(.success(Data()))
    }
}

