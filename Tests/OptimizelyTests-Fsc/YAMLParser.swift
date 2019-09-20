//
//  YAMLParser.swift
//  iOSSDKe2eTests
//
//  Created by Yasir Ali on 12/09/2019.
//  Copyright © 2019 Optimizely, Inc. All rights reserved.
//

import Foundation
import Yams

class YAMLParser: NSObject {
    
    static func getMapFromYAML(value: String) -> [String: Any]?{
        if let loadedDictionary = try? Yams.load(yaml: value) as? [String: Any] {
            return loadedDictionary
        }
        return nil
    }
    
}
