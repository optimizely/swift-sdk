//
//  File.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 2/5/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

enum HandlerRegistryServiceError: Error {
    case alreadyRegistered
    
    var localizedDescription: String {
        get {
            return "Already registered Service"
        }
    }
}

class HandlerRegistryService {
    
    static let shared = HandlerRegistryService()
    
    let dispatchQueue = DispatchQueue(label: "com.optimizely.HandlerRegistryService")
    
    var binders = [BinderProtocol]()
    
    private init() {
        
    }
    
    func registerBinding(binder:BinderProtocol) {
        dispatchQueue.sync {
            if let _ = binders.filter({(type(of: $0.service) == type(of: binder.service)) && $0.sdkKey == binder.sdkKey}).first {
            }
            else {
                binders.append(binder)
            }
        }        
    }
    
    func injectComponent(service:Any, sdkKey:String? = nil, isReintialize:Bool=false) -> Any? {
        var result:Any?
        dispatchQueue.sync {
            if var binder = binders.filter({(type(of: $0.service) == type(of: service)) && $0.sdkKey == sdkKey}).first {
                if isReintialize && binder.strategy == .reCreate {
                    binder.instance = binder.factory()
                    result = binder.instance
                }
                else if let inst = binder.instance, binder.isSingleton {
                    result = inst
                }
                else {
                    let inst = binder.factory()
                    binder.instance = inst
                    result = inst
                }
            }
        }
        return result
    }
    
    func reInitializeComponent(service:Any, sdkKey:String? = nil) {
            let _ = injectComponent(service: service, sdkKey: sdkKey, isReintialize: true)
    }
    
    func lookupComponents(sdkKey:String)->[Any?]? {
        var value:[Any]?
        
        value = self.binders.filter({$0.sdkKey == sdkKey}).map({ self.injectComponent(service: $0.service) as Any })

        return value
    }
}

enum ReInitializeStrategy {
    case reCreate
    case reUse
}

protocol BinderProtocol {
    var sdkKey:String? { get }
    var strategy:ReInitializeStrategy { get }
    var service:Any { get }
    var isSingleton:Bool { get }
    var factory:()->Any? { get }
    //var configure:(_ inst:Any?)->Any? { get }
    var instance:Any? { get set }
    
}
class Binder<T> : BinderProtocol {
    var sdkKey:String?
    var service: Any
    var strategy: ReInitializeStrategy = .reCreate
    var factory: (() -> Any?) = { ()->Any? in { return nil as Any? }}
    //var configure: ((Any?) -> Any?) = { (_)->Any? in { return nil as Any? }}
    var isSingleton = false
    var inst:T?
    
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
    
    init(service:Any) {
        self.service = service
    }
    
    func sdkKey(key:String) -> Binder {
        self.sdkKey = key
        return self
    }
    
    func singetlon() -> Binder {
        isSingleton = true
        return self
    }
    
    func reInitializeStrategy(strategy:ReInitializeStrategy) -> Binder {
        self.strategy = strategy
        
        return self
    }
    
    func using(instance:T) -> Binder {
        self.inst = instance
        return self
    }
    
    func to(factory:@escaping ()->T?) -> Binder {
        self.factory = factory
        return self
    }
}

extension HandlerRegistryService {
    func injectLogger(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTLogger? {
        return injectComponent(service: OPTLogger.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTLogger?
    }
    
    func injectNotificationCenter(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTNotificationCenter? {
        return injectComponent(service: OPTNotificationCenter.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTNotificationCenter?
    }
    func injectDecisionService(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTDecisionService? {
        return injectComponent(service: OPTDecisionService.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDecisionService?
    }
    func injectBucketer(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTBucketer? {
        return injectComponent(service: OPTBucketer.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTBucketer?
    }
    
    func injectEventDispatcher(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTEventDispatcher? {
        return injectComponent(service: OPTEventDispatcher.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTEventDispatcher?
    }
    
    func injectDatafileHandler(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTDatafileHandler? {
        return injectComponent(service: OPTDatafileHandler.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDatafileHandler?
    }
    
    func injectUserProfileService(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTUserProfileService? {
        return injectComponent(service: OPTUserProfileService.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTUserProfileService?
    }
    
}

