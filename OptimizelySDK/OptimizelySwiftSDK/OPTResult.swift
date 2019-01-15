//
//  OPTResult.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/19/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public enum OPTResult<Value> {
    case success(Value)
    case failure(OPTError)
}
