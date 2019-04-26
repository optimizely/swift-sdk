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
import Optimizely

class CustomNotificationCenter: OPTNotificationCenter {
    
    var notificationId: Int
    
    required init() {
        notificationId = 0
    }
    
    static func createInstance() -> OPTNotificationCenter? {
        return CustomNotificationCenter()
    }

    func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int? {
        return nil
    }
    
    func removeNotificationListener(notificationId: Int) {
        //
    }
    
    func clearNotificationListeners(type: NotificationType) {
        //
    }
    
    func clearAllNotificationListeners() {
        //
    }
    
    func sendNotifications(type: Int, args: Array<Any?>) {
        //
    }
    
    func addActivateNotificationListener(activateListener: @escaping ActivateListener) -> Int? {
        //
        return nil
    }
    
    func addTrackNotificationListener(trackListener: @escaping TrackListener) -> Int? {
        //
        return nil
    }
    
    func addDecisionNotificationListener(decisionListener: @escaping DecisionListener) -> Int? {
        //
        return nil
    }
    
    func addDatafileChangeNotificationListener(datafileListener: @escaping DatafileChangeListener) -> Int? {
        return nil
    }
    
}
