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
// Modified version of this github implementation:
//https://github.com/jpedrosa/sua/blob/master/Sources/murmurhash3.swift
public class MurmurHash3 {
    
    // MurmurHash3 32 bits.
    // Translated to Swift by referring to the following sources:
    // * https://github.com/jwerle/murmurhash.c
    // * https://en.wikipedia.org/wiki/MurmurHash
    public static func doHash32(key: UnsafePointer<UInt8>, maxBytes: Int,
                                seed: UInt32 = 0) -> UInt32 {
        let c1: UInt32 = 0xcc9e2d51
        let c2: UInt32 = 0x1b873593
        let r1: UInt32 = 15
        let r2: UInt32 = 13
        let m: UInt32 = 5
        let n: UInt32 = 0xe6546b64
        var hash: UInt32 = seed
        var k: UInt32 = 0
        let l = maxBytes / 4 // chunk length
        key.withMemoryRebound(to: UInt32.self, capacity: l) { (key32) -> Void in
            let chunks = UnsafeBufferPointer<UInt32>(
                start: UnsafePointer<UInt32>(key32), count: l)
            for chunk in chunks {
                k = chunk &* c1
                k = (k << r1) | (k >> (32 - r1))
                k = k &* c2
                hash ^= k
                hash = (hash << r2) | (hash >> (32 - r2))
                hash = ((hash &* m) &+ n)
            }
        }
        
        let tail = UnsafeBufferPointer<UInt8>(
            start: UnsafePointer<UInt8>(key) + (l * 4), count: 4)
    
        k = 0
        
        // remainder
        switch maxBytes & 3 { // `len % 4'
        case 3:
            k ^= UInt32(tail[2]) << 16
            fallthrough
        case 2:
            k ^= UInt32(tail[1]) << 8
            fallthrough
        case 1:
            k ^= UInt32(tail[0])
            k = k &* c1
            k = (k << r1) | (k >> (32 - r1))
            k = k &* c2
            hash ^= k
        default: () // Ignore.
        }
        
        hash ^= UInt32(maxBytes)
        
        hash ^= hash >> 16
        hash = hash &* 0x85ebca6b
        hash ^= hash >> 13
        hash = hash &* 0xc2b2ae35
        hash ^= hash >> 16
        
        return hash
    }
    
    public static func hash32(key: String, seed: UInt32 = 0) -> UInt32 {
        var a = [UInt8](key.utf8)
        return doHash32(key: &a, maxBytes: a.count, seed: seed)
    }
    
    public static func hash32CChar(key: [CChar], maxBytes: Int,
                                   seed: UInt32 = 0) -> UInt32 {
        return key.withUnsafeBufferPointer { (pointer) -> UInt32 in
            guard let baseAddress = pointer.baseAddress else {
                return 0
            }
            return baseAddress.withMemoryRebound(to: UInt8.self, capacity: pointer.count, { (uint8pointer) -> UInt32 in
                return doHash32(key: uint8pointer, maxBytes: maxBytes, seed: seed)
            })
        }
    }
    
    public static func hash32Bytes(key: [UInt8], maxBytes: Int,
                                   seed: UInt32 = 0) -> UInt32 {
        var a = key
        return doHash32(key: &a, maxBytes: maxBytes, seed: seed)
    }
    
    // MurmurHash3 128 bits.
    // Translated it to Swift using the following references:
    // * [qhash.c](https://github.com/wolkykim/qlibc/blob/8e5e6669fae0eb63e4fb171e7c84985b0828c720/src/utilities/qhash.c)
    // * [MurmurHash3.cpp](https://code.google.com/p/smhasher/source/browse/trunk/MurmurHash3.cpp)
    public static func doHash128(key: UnsafePointer<UInt8>, maxBytes: Int,
                                 seed: UInt64 = 0) -> (h1: UInt64, h2: UInt64) {
        let c1: UInt64 = 0x87c37b91114253d5
        let c2: UInt64 = 0x4cf5ad432745937f
        let nblocks = maxBytes / 16
        var h1 = seed
        var h2 = seed
        var k1: UInt64 = 0
        var k2: UInt64 = 0
        
        key.withMemoryRebound(to: UInt64.self, capacity: nblocks * 2) { (key64) -> Void in
            let blocks = UnsafeBufferPointer<UInt64>(
                start: UnsafePointer<UInt64>(key64), count: nblocks * 2)
            for i in 0..<nblocks {
                k1 = blocks[(i * 2) + 0]
                k2 = blocks[(i * 2) + 1]
                
                k1 = k1 &* c1
                k1 = (k1 << 31) | (k1 >> (64 - 31))
                k1 = k1 &* c2
                h1 ^= k1
                
                h1 = (h1 << 27) | (h1 >> (64 - 27))
                h1 = h1 &+ h2
                h1 = (h1 &* 5) &+ 0x52dce729
                
                k2 = k2 &* c2
                k2 = (k2 << 33) | (k2 >> (64 - 33))
                k2 = k2 &* c1
                h2 ^= k2
                
                h2 = (h2 << 31) | (h2 >> (64 - 31))
                h2 = h2 &+ h1
                h2 = (h2 &* 5) &+ 0x38495ab5
            }
        }
        
        let tail = UnsafeBufferPointer<UInt8>(
            start: UnsafePointer<UInt8>(key) + (nblocks * 16), count: 16)
        
        k1 = 0
        k2 = 0
        
        // Remainder.
        switch maxBytes & 15 { // maxBytes % 15
        case 15:
            k2 ^= UInt64(tail[14]) << 48
            fallthrough
        case 14:
            k2 ^= UInt64(tail[13]) << 40
            fallthrough
        case 13:
            k2 ^= UInt64(tail[12]) << 32
            fallthrough
        case 12:
            k2 ^= UInt64(tail[11]) << 24
            fallthrough
        case 11:
            k2 ^= UInt64(tail[10]) << 16
            fallthrough
        case 10:
            k2 ^= UInt64(tail[9]) << 8
            fallthrough
        case 9:
            k2 ^= UInt64(tail[8]) << 0
            k2 = k2 &* c2
            k2 = (k2 << 33) | (k2 >> (64 - 33))
            k2 = k2 &* c1
            h2 ^= k2
            fallthrough
        case 8:
            k1 ^= UInt64(tail[7]) << 56
            fallthrough
        case 7:
            k1 ^= UInt64(tail[6]) << 48
            fallthrough
        case 6:
            k1 ^= UInt64(tail[5]) << 40
            fallthrough
        case 5:
            k1 ^= UInt64(tail[4]) << 32
            fallthrough
        case 4:
            k1 ^= UInt64(tail[3]) << 24
            fallthrough
        case 3:
            k1 ^= UInt64(tail[2]) << 16
            fallthrough
        case 2:
            k1 ^= UInt64(tail[1]) << 8
            fallthrough
        case 1:
            k1 ^= UInt64(tail[0]) << 0
            k1 = k1 &* c1
            k1 = (k1 << 31) | (k1 >> (64 - 31))
            k1 = k1 &* c2
            h1 ^= k1
        default: () // Ignore.
        }
        
        h1 ^= UInt64(maxBytes)
        h2 ^= UInt64(maxBytes)
        
        h1 = h1 &+ h2
        h2 = h2 &+ h1
        
        h1 ^= h1 >> 33
        h1 = h1 &* 0xff51afd7ed558ccd
        h1 ^= h1 >> 33
        h1 = h1 &* 0xc4ceb9fe1a85ec53
        h1 ^= h1 >> 33
        
        h2 ^= h2 >> 33
        h2 = h2 &* 0xff51afd7ed558ccd
        h2 ^= h2 >> 33
        h2 = h2 &* 0xc4ceb9fe1a85ec53
        h2 ^= h2 >> 33
        
        h1 = h1 &+ h2
        h2 = h2 &+ h1
        
        return (h1, h2)
    }
    
    public static func hash128(key: String, seed: UInt64 = 0)
        -> (h1: UInt64, h2: UInt64) {
            var a = [UInt8](key.utf8)
            return doHash128(key: &a, maxBytes: a.count, seed: seed)
    }
    
    public static func hash128CChar(key: [CChar], maxBytes: Int,
                                    seed: UInt64 = 0) -> (h1: UInt64, h2: UInt64) {
        return key.withUnsafeBufferPointer { (pointer) -> (h1: UInt64, h2: UInt64) in
            guard let baseAddress = pointer.baseAddress else {
                return (0, 0)
            }
            return baseAddress.withMemoryRebound(to: UInt8.self, capacity: pointer.count, { (uint8pointer) -> (h1: UInt64, h2: UInt64) in
                return doHash128(key: uint8pointer, maxBytes: maxBytes, seed: seed)
            })
        }
    }
    
    public static func hash128Bytes(key: [UInt8], maxBytes: Int,
                                    seed: UInt64 = 0) -> (h1: UInt64, h2: UInt64) {
        var a = key
        return doHash128(key: &a, maxBytes: maxBytes, seed: seed)
    }
    
}
