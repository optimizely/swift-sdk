//
//  VariationViewController.h
//  DemoObjcApp
//
//  Created by Jae Kim on 1/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OptimizelyManager;

@interface VariationViewController : UIViewController
@property(nullable, nonatomic, strong) OptimizelyManager *optimizely;
@property(nonnull, nonatomic, strong) NSString *eventKey;
@property(nonnull, nonatomic, strong) NSString *variationKey;
@property(nonnull, nonatomic, strong) NSString *userId;

@end
