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

class AtomicDictionary<K, V>: AtomicWrapper where K: Hashable {
    private var _property: [K: V]
         
    init(_ property: [K: V] = [:]) {
        self._property = property
    }
    
    subscript(key: K) -> V? {
        get {
            return getAtomic {
                _property[key]
            }
        }
        set {
            performAtomic {
                self._property[key] = newValue
            }
        }
    }
    
    var count: Int {
        return getAtomic {
            _property.count
        }!
    }
}
