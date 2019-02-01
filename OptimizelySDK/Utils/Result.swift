//
//  File.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/3/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}
