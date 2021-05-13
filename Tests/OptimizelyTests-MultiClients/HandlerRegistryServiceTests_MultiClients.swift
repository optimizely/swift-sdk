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

class HandlerRegistryServiceTests_MultiClients: XCTestCase {

    func testConcurrentAccess_Singleton() {
        // this type used for all handlers except for logger
        
        let numThreads = 10
        let numEventsPerThread = 100

        let registry = HandlerRegistryService.shared
        
        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 300) { thIdx in
            for idx in 0..<numEventsPerThread {
                let sdkKey = String(thIdx * numEventsPerThread + idx)
                let strategy: ReInitializeStrategy = .reUse
                let isSingleton = true
                let isReinitialize = false
                
                let service = OPTLogger.self
                let componentIn = DefaultLogger()
                
                let binder = Binder(sdkKey: sdkKey,
                                    service: service,
                                    strategy: strategy,
                                    isSingleton: isSingleton,
                                    inst: componentIn)
                
                registry.registerBinding(binder: binder)
                if let componentOut = registry.injectComponent(service: service,
                                                               sdkKey: sdkKey,
                                                               isReintialize: isReinitialize) as? DefaultLogger {
                    XCTAssertEqual(String(describing: componentOut), String(describing: componentIn))
                } else {
                    self.dumpRegistry()
                    XCTAssert(false, "injectComponent failed: \(sdkKey) :: \(binder)")
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentAccess_NonSingleton() {
        // this type used for loggers

        let numThreads = 10
        let numEventsPerThread = 100

        let registry = HandlerRegistryService.shared
        
        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 300) { thIdx in
            for _ in 0..<numEventsPerThread {
                let isReinitialize = false
                
                let service = OPTLogger.self
                let componentIn = DefaultLogger()
                
                let binder = Binder<OPTLogger>(service: service,
                                               factory: type(of: componentIn).init)
                
                registry.registerBinding(binder: binder)
                if let componentOut = registry.injectComponent(service: service,
                                                               isReintialize: isReinitialize) as? DefaultLogger {
                    XCTAssertEqual(String(describing: componentOut), String(describing: componentIn))
                } else {
                    self.dumpRegistry()
                    XCTAssert(false, "injectComponent failed: \(binder)")
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

    func testConcurrentAccess_Random() {        
        let numThreads = 10
        let numEventsPerThread = 100

        let registry = HandlerRegistryService.shared
        
        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 300) { thIdx in
            for idx in 0..<numEventsPerThread {
                let sdkKey = String(thIdx * numEventsPerThread + idx)
                let strategy: ReInitializeStrategy = Bool.random() ? .reCreate : .reUse
                let isSingleton = Bool.random()
                let isReinitialize = Bool.random()
                
                let service = OPTLogger.self
                let componentIn = DefaultLogger()
                
                let binder = Binder(sdkKey: sdkKey,
                                    service: service,
                                    strategy: strategy,
                                    factory: type(of: componentIn).init,
                                    isSingleton: isSingleton,
                                    inst: componentIn)
                
                registry.registerBinding(binder: binder)
                if let componentOut = registry.injectComponent(service: service,
                                                               sdkKey: sdkKey,
                                                               isReintialize: isReinitialize) as? DefaultLogger {
                    XCTAssertEqual(String(describing: componentOut), String(describing: componentIn))
                } else {
                    self.dumpRegistry()
                    XCTAssert(false, "injectComponent failed: \(sdkKey) \(isReinitialize) :: \(binder)")
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

    // MARK: - Utils
    
    func dumpRegistry() {
        let registry = HandlerRegistryService.shared
        
        print("[MultiClients] binders --------------")
        registry.binders.performAtomic { prop in
            for sk in prop.keys {
                print("[MultiClients] binder for \(sk): \(prop[sk]!)")
            }
        }
    }
}
