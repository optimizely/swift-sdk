//
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

#if os(watchOS)
import Foundation

/// watchOS adds support for background notifications in watchOS 7.0 with `WKExtension.applicationDidEnterBackgroundNotification`
/// and related notifications. But since this SDK is backwards compatible with watchOS 3.0, these notifications are not available. Instead, the user
/// should implement the appropriate background methods on their Extension Delegate and call the `WatchBackgroundNotifier` from those
/// methods.
public final class WatchBackgroundNotifier {
    private init() {}

    public static func applicationDidBecomeActive() {
        NotificationCenter.default.post(name: Self.watchAppDidBecomeActiveNotification, object: self)
    }

    public static func applicationDidEnterBackground() {
        NotificationCenter.default.post(name: Self.watchAppDidEnterBackgroundNotification, object: self)
    }
}

public extension WatchBackgroundNotifier {
    static let watchAppDidBecomeActiveNotification = NSNotification.Name(
        rawValue: "com.optimizely.watchAppWillEnterForegroundNotification"
    )

    static let watchAppDidEnterBackgroundNotification = NSNotification.Name(
        rawValue: "com.optimizely.watchAppDidEnterBackgroundNotification"
    )
}
#endif
