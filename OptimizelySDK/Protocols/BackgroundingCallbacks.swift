//
//  File.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
@objc protocol BackgroundingCallbacks {
    func applicationDidEnterBackground()
    func applicationDidBecomeActive()
}

extension BackgroundingCallbacks {
    #if os(iOS) || os(tvOS)
    func subscribe() {
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
    
    func unsubscribe()  {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
    #elseif os(macOS)
    func subscribe() {
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .NSApplictionDidResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .NSApplicationDidBecomeActive, object: nil)
        #endif
    }
    
    func unsubscribe()  {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: .NSApplicationDidResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .NSApplicationDidBecomeActiveNotification, object: nil)
        #endif
    }

    #endif
}
