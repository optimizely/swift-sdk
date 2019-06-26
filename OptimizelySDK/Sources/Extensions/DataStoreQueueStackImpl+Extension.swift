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

extension DataStoreQueueStack {
    func getFirstItem() -> T? {
        return getFirstItems(count: 1)?.first
    }
    func getLastItem() -> T? {
        return getLastItems(count: 1)?.first
    }
    func removeFirstItem() -> T? {
        return removeFirstItems(count: 1)?.first
    }
    func removeLastItem() -> T? {
        return removeLastItems(count: 1)?.first
    }
 }
