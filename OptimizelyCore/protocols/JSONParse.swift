//
//  File.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/5/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

protocol JSONParser {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T
    func encode<T>(_ type: T.Type) -> Data?
}
