/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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
    
#if os(iOS) && (DEBUG || OPT_DBG)

import Foundation
import CoreData

extension Variation: CustomReflectable {

    var customMirror: Mirror {
        
        var children: KeyValuePairs<String, Any>
        if let enabled = featureEnabled {
            children = [
                "id": id,
                "key": key,
                "featureEnabled": enabled,
                "variablesMap": variablesMap]
        } else {
            children = [
                "id": id,
                "key": key,
                "variablesMap": variablesMap]
        }
        
        return Mirror(self, children: children)
    }
    
}

#endif
