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

class AtomicArray<T>: AtomicWrapper {
    private var _property: [T]
         
    init(_ property: [T] = []) {
        self._property = property
    }
    
    subscript(index: Int) -> T? {
        get {
            returnAtomic {
                _property[index]
            }
        }
        set {
            performAtomic {
                if let value = newValue {
                    self._property[index] = value
                }
            }
        }
    }
    
    var count: Int {
        returnAtomic {
            _property.count
        }!
    }
    
    func append(_ item: T) {
        performAtomic {
            self._property.append(item)
        }
    }
    
    func append(contentsOf items: [T]) {
        performAtomic {
            self._property.append(contentsOf: items)
        }
    }
}

// MARK: - AtomicWrapper

class AtomicWrapper {
    var lock: DispatchQueue = {
        let name = "AtomicCollection" + String(Int.random(in: 0..<100000))
        return DispatchQueue(label: name, attributes: .concurrent)
    }()

    func returnAtomic<E>(_ action: () throws -> E?) -> E? {
        var result: E?
        lock.sync {
            result = try? action()
        }
        return result
    }
    
    func performAtomic(_ action: @escaping () throws -> Void) {
        lock.async(flags: .barrier) {
            try? action()
        }
    }
}
