//
//  OptimizelyManager+Extension.swift
//  OptimizelySwiftSDK-iOS
//
//  Created by Thomas Zurkan on 3/8/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

extension OptimizelyManager {
    func registerServices(sdkKey:String,
                          logger:OPTLogger,
                          eventDispatcher:OPTEventDispatcher,
                          datafileHandler:OPTDatafileHandler,
                          decisionService:OPTDecisionService,
                          notificationCenter:OPTNotificationCenter) {
        // bind it as a non-singleton.  so, we will create an instance anytime injected.
        // we don't associate the logger with a sdkKey at this time because not all components are sdkKey specific.
        let binder:Binder = Binder<OPTLogger>(service: OPTLogger.self).to(factory: type(of:logger).init)
        //Register my logger service.
        HandlerRegistryService.shared.registerBinding(binder: binder)
        
        // this is bound a reusable singleton. so, if we re-initalize, we will keep this.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTNotificationCenter>(service: OPTNotificationCenter.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance:notificationCenter).sdkKey(key: sdkKey))
        
        // the decision service is also a singleton that will reCreate on re-initalize
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTDecisionService>(service: OPTDecisionService.self).singetlon().using(instance:decisionService).sdkKey(key: sdkKey))
        
        // An event dispatcher.  We rely on the factory to create and mantain. Again, recreate on re-initalize.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTEventDispatcher>(service: OPTEventDispatcher.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance: eventDispatcher).sdkKey(key: sdkKey))
        
        // This is a singleton and might be a good candidate for reuse.  The handler supports mulitple
        // sdk keys without having to be created for every key.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).singetlon().reInitializeStrategy(strategy: .reUse).to(factory: type(of:datafileHandler).init).using(instance: datafileHandler).sdkKey(key: sdkKey))
    }
}
