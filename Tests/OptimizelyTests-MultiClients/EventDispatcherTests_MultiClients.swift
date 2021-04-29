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

class EventDispatcherTests_MultiClients: XCTestCase {
    var dispatcher = DefaultEventDispatcher()

    override func setUpWithError() throws {
        OTUtils.createDocumentDirectoryIfNotAvailable()
    }

    override func tearDownWithError() throws {
        OTUtils.clearAllEventQueues()
    }

    func testConcurrentDispatchEvents() {
        
    }
    
    func testConcurrentFlushEvents() {
        
    }
    
    func testConcurrentSendEvents() {
        
    }
    
    func testConcurrentStartTimer() {
        let result = OTUtils.runConcurrent(count: 5, timeoutInSecs: 30) { idx in
            (0..<1).forEach { _ in
                self.dispatcher.startTimer()
                print("MultiClients] before sleep: \(idx)")
                
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.main.async {
                    group.leave()
                }
                group.wait()
                print("MultiClients] end sleep: \(idx)")
                self.dispatcher.stopTimer()
            }
            
            print("MultiClients] end of each")

        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}
