//
//  File.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

class AtomicProperty<T> {
    private var _property:T?
    var property:T? {
        get {
            var retVal:T? = nil
            lock.sync {
                retVal = _property
            }
            return retVal
        }
        set {
            lock.sync {
                self._property = newValue
            }
        }
    }
    private let lock:DispatchQueue =  {
        var name = "AtomicProperty" + String(Int.random(in: 0...100000))
        let clzzName = String(describing: T.self)
        name += clzzName
        return DispatchQueue(label: name)
    }()

    init(property:T) {
        self.property = property
    }

    init() {

    }
    
    // perform an atomic operation on the atomic property
    // the operation will not run if the property is nil.
    public func performAtomic(atomicOperation:((_ prop:inout T)->Void)) {
        lock.sync {
            if var prop = _property {
                atomicOperation(&prop)
                _property = prop
            }
        }
    }

}
