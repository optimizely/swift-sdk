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
    
    subscript(index: Int) -> T {
        get {
            return getAtomic {
                _property[index]
            }!
        }
        set {
            performAtomic {
                self._property[index] = newValue
            }
        }
    }
    
    var count: Int {
        return getAtomic {
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
    
    func firstIndex(where predicate: (T) throws -> Bool) rethrows -> Int? {
        return getAtomic {
            try _property.firstIndex(where: predicate)
        }
    }
    
    func filter(_ isIncluded: (T) throws -> Bool) rethrows -> [T] {
        return getAtomic {
            try _property.filter(isIncluded)
        }!
    }
    
    func remove(at i: Int) -> T {
        return getAtomic {
            _property.remove(at: i)
        }!
    }
    
    func removeAll() {
        performAtomic {
            self._property.removeAll()
        }
    }

}

// MARK: - AtomicWrapper

class AtomicWrapper {
    var lock: DispatchQueue = {
        let name = "AtomicWrapper" + String(Int.random(in: 0..<100000))
        return DispatchQueue(label: name, attributes: .concurrent)
    }()

    func getAtomic<E>(_ action: () throws -> E?) -> E? {
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
