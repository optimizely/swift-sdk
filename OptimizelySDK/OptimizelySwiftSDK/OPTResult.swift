//
//  OPTResult.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/19/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public enum OPTResult {
    case success
    case failure(OPTError)
}

public enum OPTResultData<Value> {
    case success(Value)
    case failure(OPTError)
}
