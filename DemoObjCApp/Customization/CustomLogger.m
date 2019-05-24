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
