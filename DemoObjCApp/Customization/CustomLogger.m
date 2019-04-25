//
//  CustomLogger.m
//  DemoObjcApp
//
//  Created by Jae Kim on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import "CustomLogger.h"
@import Optimizely;

@implementation CustomLogger

-(instancetype)init {
    self = [super init];
    if (self != nil) {
        //
    }
    
    return self;
}

- (void)logWithLevel:(enum OptimizelyLogLevel)level message:(NSString * _Nonnull)message {
    if (level <= CustomLogger.logLevel) {
        NSLog(@"🐱 - [\(level.name)] Kitty - %@", message);
    }
}

static enum OptimizelyLogLevel logLevel = OptimizelyLogLevelInfo;
+(enum OptimizelyLogLevel)logLevel {
    return logLevel;
}
+(void)setLogLevel:(enum OptimizelyLogLevel)value {
    logLevel = value;
}

@end
