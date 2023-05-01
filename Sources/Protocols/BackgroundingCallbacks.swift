//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

#if os(watchOS)
import WatchKit
#elseif os(macOS)
import Cocoa
#else
import UIKit
#endif

@objc protocol BackgroundingCallbacks {
    func applicationDidEnterBackground()
    func applicationDidBecomeActive()
}

private extension NSNotification.Name {
    #if os(macOS)
    static let didEnterBackground = NSApplication.didResignActiveNotification
    static let didBecomeActive = NSApplication.didBecomeActiveNotification
    #elseif os(iOS) || os(tvOS)
    static let didEnterBackground = UIApplication.didEnterBackgroundNotification
    static let didBecomeActive = UIApplication.didBecomeActiveNotification
    #elseif os(watchOS)
    static let didEnterBackground = WatchBackgroundNotifier.watchAppDidEnterBackgroundNotification
    static let didBecomeActive = WatchBackgroundNotifier.watchAppDidBecomeActiveNotification
    #endif
}

extension BackgroundingCallbacks {
    func subscribe() {
        // swift4.2+
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .didEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .didBecomeActive, object: nil)
    }
    
    func unsubscribe() {
        // swift4.2+
        NotificationCenter.default.removeObserver(self, name: .didEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didBecomeActive, object: nil)
    }
}
