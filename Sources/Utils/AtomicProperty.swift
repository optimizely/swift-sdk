//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class AtomicProperty<T> {
    private var _property: T?
    var property: T? {
        get {
            var retVal: T?
            lock.sync {
                retVal = _property
            }
            return retVal
        }
        set {
            lock.async(flags: DispatchWorkItemFlags.barrier) {
                self._property = newValue
            }
        }
    }
    private let lock: DispatchQueue

    init(property: T?, lock: DispatchQueue? = nil) {
        self._property = property
        self.lock = lock ?? {
            var name = "AtomicProperty" + String(Int.random(in: 0...100000))
            let className = String(describing: T.self)
            name += className
            return DispatchQueue(label: name, attributes: .concurrent)
        }()
    }

    convenience init() {
        self.init(property: nil, lock: nil)
    }
    
    // perform an atomic operation on the atomic property
    // the operation will not run if the property is nil.
    func performAtomic(atomicOperation: (_ prop:inout T) -> Void) {
        lock.sync(flags: DispatchWorkItemFlags.barrier) {
            if var prop = _property {
                atomicOperation(&prop)
                _property = prop
            }
        }
    }

}
