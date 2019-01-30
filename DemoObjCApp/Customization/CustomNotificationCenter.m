//
//  CustomNotificationCenter.m
//  DemoObjcApp
//
//  Created by Jae Kim on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import "CustomNotificationCenter.h"
@import Optimizely;

@implementation CustomNotificationCenter

-(instancetype)init {
    self = [super init];
    if (self != nil) {
        _notificationId = 0;
    }
    
    return self;
}

@end
