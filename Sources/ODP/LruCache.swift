//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class LruCache<K: Hashable, V> {
        
    class CacheElement {
        var prev: CacheElement?
        var next: CacheElement?
        let key: K?
        let value: V?
        var time: TimeInterval
        
        init(key: K? = nil, value: V? = nil) {
            self.key = key
            self.value = value
            self.time = Date.timeIntervalSinceReferenceDate
        }
    }
    
    var map: [K: CacheElement]!
    var head: CacheElement!
    var tail: CacheElement!
    let queue = DispatchQueue(label: "LRU")
    let size: Int
    let timeoutInSecs: Int
    
    init(size: Int, timeoutInSecs: Int) {
        self.size = size
        self.timeoutInSecs = timeoutInSecs
        self.reset()
    }

    func lookup(key: K) -> V? {
        if size <= 0 { return nil }
        
        var element: CacheElement? = nil
        var needReset = false
        
        queue.sync {
            element = map[key]
            
            if let item = element {
                removeFromLink(item)
                
                if isValid(item) {
                    addToLink(item)
                } else {
                    map[key] = nil
                    element = nil
                    
                    // check if all are stale and can be reset.
                    needReset = isAllStale()
                }
            }
        }
        
        // reset is called outside the sync block to avoid deadlock
        if needReset {
            reset()
        }
        
        return element?.value
    }
    
    func save(key: K, value: V) {
        if size <= 0 { return }

        queue.async(flags: .barrier) {
            let oldSegments = self.map[key]
            let newSegments = CacheElement(key: key, value: value)
            self.map[key] = newSegments
            
            if let old = oldSegments {
                self.removeFromLink(old)
            }
            self.addToLink(newSegments)
            
            while self.map.count > self.size {
                guard let old = self.head.next, let oldKey = old.key else { break }
                self.removeFromLink(old)
                self.map[oldKey] = nil
            }
        }
    }
    
    // read cache contents without order update
    func peek(key: K) -> V? {
        if size <= 0 { return nil }

        var element: CacheElement? = nil
        queue.sync {
            element = map[key]
        }
        return element?.value
    }
    
    func reset() {
        if size <= 0 { return }

        queue.sync {
            map = [K: CacheElement]()
            head = CacheElement()
            tail = CacheElement()
            head.next = tail
            tail.prev = head
        }
    }
    
    // MARK: - Utils

    private func removeFromLink(_ item: CacheElement) {
        item.prev?.next = item.next
        item.next?.prev = item.prev
    }
    
    private func addToLink(_ item: CacheElement) {
        let prev = tail.prev!
        prev.next = item
        tail.prev = item
        
        item.next = tail
        item.prev = prev
    }
        
    private func isValid(_ item: CacheElement) -> Bool {
        if timeoutInSecs <= 0 { return true }
        return (Date.timeIntervalSinceReferenceDate - item.time) < Double(timeoutInSecs)
    }
    
    /// Check if all items in the cache is too old
    /// - Returns: true if the most recent item is stale
    private func isAllStale() -> Bool {
        guard let mostRecent = tail.prev else { return false }
        return !isValid(mostRecent)
    }

}
