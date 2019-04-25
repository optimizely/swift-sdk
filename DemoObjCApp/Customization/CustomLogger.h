//
//  CustomLogger.h
//  DemoObjcApp
//
//  Created by Jae Kim on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OPTLogger;

@interface CustomLogger : NSObject <OPTLogger>
+ (enum OptimizelyLogLevel)logLevel;
+ (void)setLogLevel:(enum OptimizelyLogLevel)value;
- (nonnull instancetype)init;
- (void)logWithLevel:(enum OptimizelyLogLevel)level message:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
