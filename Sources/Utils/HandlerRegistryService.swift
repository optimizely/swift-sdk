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

import Foundation

class HandlerRegistryService {
    
    static let shared = HandlerRegistryService()
    
    struct ServiceKey: Hashable {
        var service: String
        var sdkKey: String?
    }
    
    var binders: AtomicProperty<[ServiceKey: BinderProtocol]> = {
        
        var binders = AtomicProperty<[ServiceKey: BinderProtocol]>()
        binders.property = [ServiceKey: BinderProtocol]()
        return binders
    }()
    
    private init() {
        
    }
    
    func registerBinding(binder: BinderProtocol) {
        let sk = ServiceKey(service: "\(type(of: binder.service))", sdkKey: binder.sdkKey)
        if binders.property?[sk] != nil {
        } else {
            binders.property?[sk] = binder
        }
    }
    
    func injectComponent(service: Any, sdkKey: String? = nil, isReintialize: Bool=false) -> Any? {
        var result: Any?
        // first look up global.  Then look up if there is a local.
        let skLocal = ServiceKey(service: "\(type(of: service))", sdkKey: sdkKey)
        let skGlobal = ServiceKey(service: "\(type(of: service))", sdkKey: nil)
        
        let binderToUse = binders.property?[skLocal] ?? binders.property?[skGlobal]
        
        if var binder = binderToUse {
            if isReintialize && binder.strategy == .reCreate {
                binder.instance = binder.factory()
                result = binder.instance
            } else if let inst = binder.instance, binder.isSingleton {
                result = inst
            } else {
                let inst = binder.factory()
                binder.instance = inst
                result = inst
            }
        }
        return result
    }
    
    func reInitializeComponent(service: Any, sdkKey: String? = nil) {
            _ = injectComponent(service: service, sdkKey: sdkKey, isReintialize: true)
    }
    
    func lookupComponents(sdkKey: String)->[Any]? {
        if let value = self.binders.property?.keys
            .filter({$0.sdkKey == sdkKey})
            .compactMap({ self.injectComponent(service: self.binders.property![$0]!.service, sdkKey: sdkKey) }) {
            return value
        }
        
        return nil
    }
}

enum ReInitializeStrategy {
    case reCreate
    case reUse
}

protocol BinderProtocol {
    var sdkKey: String? { get }
    var strategy: ReInitializeStrategy { get }
    var service: Any { get }
    var isSingleton: Bool { get }
    var factory:()->Any? { get }
    //var configure:(_ inst:Any?)->Any? { get }
    var instance: Any? { get set }
    
}
class Binder<T>: BinderProtocol {
    var sdkKey: String?
    var service: Any
    var strategy: ReInitializeStrategy = .reCreate
    var factory: (() -> Any?) = { ()->Any? in { return nil as Any? }}
    //var configure: ((Any?) -> Any?) = { (_)->Any? in { return nil as Any? }}
    var isSingleton = false
    var inst: T?
    
    var instance: Any? {
        get {
            return inst as Any?
        }
        set {
            if let v = newValue as? T {
                inst = v
            }
        }
    }
    
    init(service: Any) {
        self.service = service
    }
    
    func sdkKey(key: String) -> Binder {
        self.sdkKey = key
        return self
    }
    
    func singetlon() -> Binder {
        isSingleton = true
        return self
    }
    
    func reInitializeStrategy(strategy: ReInitializeStrategy) -> Binder {
        self.strategy = strategy
        
        return self
    }
    
    func using(instance: T) -> Binder {
        self.inst = instance
        return self
    }
    
    func to(factory:@escaping () -> T?) -> Binder {
        self.factory = factory
        return self
    }
}

extension HandlerRegistryService {
    func injectLogger(sdkKey: String? = nil, isReintialize: Bool=false) -> OPTLogger? {
        return injectComponent(service: OPTLogger.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTLogger?
    }
    
    func injectNotificationCenter(sdkKey: String? = nil, isReintialize: Bool=false) -> OPTNotificationCenter? {
        return injectComponent(service: OPTNotificationCenter.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTNotificationCenter?
    }
    func injectDecisionService(sdkKey: String? = nil, isReintialize: Bool=false) -> OPTDecisionService? {
        return injectComponent(service: OPTDecisionService.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDecisionService?
    }

    func injectEventDispatcher(sdkKey: String? = nil, isReintialize: Bool=false) -> OPTEventDispatcher? {
        return injectComponent(service: OPTEventDispatcher.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTEventDispatcher?
    }
    
    func injectDatafileHandler(sdkKey: String? = nil, isReintialize: Bool=false) -> OPTDatafileHandler? {
        return injectComponent(service: OPTDatafileHandler.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDatafileHandler?
    }    
}
