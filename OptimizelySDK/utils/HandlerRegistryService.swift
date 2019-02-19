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
    
    func registerBinding(binder:BinderProtocol) throws {
        var shouldThrow = false
        dispatchQueue.sync {
            if let _ = binders.filter({(type(of: $0.service) == type(of: binder.service)) && $0.sdkKey == binder.sdkKey}).first {
                shouldThrow = true
            }
            else {
                binders.append(binder)
            }
        }
        
        if shouldThrow {
            throw HandlerRegistryServiceError.alreadyRegistered
        }
    }
    
    func injectComponent(service:Any, sdkKey:String? = nil, isReintialize:Bool=false) -> Any? {
        var result:Any?
        dispatchQueue.sync {
            if var binder = binders.filter({(type(of: $0.service) == type(of: service)) && $0.sdkKey == sdkKey}).first {
                if isReintialize && binder.stategy == .reCreate {
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
    
    func lookupComponents(sdkKey:String)->[Any?]? {
        var value:[Any]?
        
        dispatchQueue.sync {
            value = self.binders.filter({$0.sdkKey == sdkKey}).map({ self.injectComponent(service: $0.service) as Any })
        }
        return value
    }
}

enum reInitializeStrategy {
    case reCreate
    case reUse
}

protocol BinderProtocol {
    var sdkKey:String? { get }
    var stategy:reInitializeStrategy { get }
    var service:Any { get }
    var isSingleton:Bool { get }
    var factory:()->Any? { get }
    //var configure:(_ inst:Any?)->Any? { get }
    var instance:Any? { get set }
    
}
class Binder<T> : BinderProtocol {
    var sdkKey:String?
    var service: Any
    var stategy: reInitializeStrategy = .reCreate
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
    
    func reInitializeStategy(strategy:reInitializeStrategy) -> Binder {
        self.stategy = strategy
        
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
