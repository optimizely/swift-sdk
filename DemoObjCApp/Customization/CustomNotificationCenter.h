//
//  CustomNotificationCenter.h
//  DemoObjcApp
//
//  Created by Jae Kim on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OPTNotificationCenter

@end
@interface CustomNotificationCenter : NSObject <OPTNotificationCenter>
@property(nonatomic, assign) int notificationId;
@end

NS_ASSUME_NONNULL_END
