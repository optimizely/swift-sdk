//
//  CustomLogger.h
//  DemoObjcApp
//
//  Created by Jae Kim on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OPTLogger

@end
@interface CustomLogger : NSObject <OPTLogger>
@end

NS_ASSUME_NONNULL_END
