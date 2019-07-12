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


#import <XCTest/XCTest.h>
@import Optimizely;


static NSString * const kExperimentKey = @"exp_with_audience";
static NSString * const kVariationKey = @"a";
static NSString * const kVariationOtherKey = @"b";
static NSString * const kEventKey = @"event1";
static NSString * const kFeatureKey = @"feature_1";

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";

@interface OptimizelyClientTests_ObjcOthers : XCTestCase
@property(nonatomic) NSDictionary * attributes;
@end


// MARK: - Custom EventDispatcher

@interface MockOPTEventDispatcher: NSObject <OPTEventDispatcher>
@property(atomic, assign) int eventCount;
@end

@implementation MockOPTEventDispatcher
- (id)init {
    self = [super init];
    _eventCount = 0;
    return self;
}

- (void)dispatchEventWithEvent:(EventForDispatch * _Nonnull)event completionHandler:(void (^ _Nullable)(NSData * _Nullable, NSError * _Nullable))completionHandler {
    self.eventCount++;
    return;
}

- (void)flushEvents {
    return;
}
@end

@implementation OptimizelyClientTests_ObjcOthers

// MARK: - Test notification listners

- (void)testNotificationCenter_Activate {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    __block BOOL called = false;
    NSNumber *num = [optimizely.notificationCenter addActivateNotificationListenerWithActivateListener:^(NSDictionary<NSString *,id> * experiment,
                                                                                         NSString * userId,
                                                                                         NSDictionary<NSString *,id> * attributes,
                                                                                         NSDictionary<NSString *,id> * variation,
                                                                                         NSDictionary<NSString *,id> * event) {
        called = true;
    }];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    NSString *variationKey = [optimizely activateWithExperimentKey:kExperimentKey
                                                            userId:kUserId
                                                        attributes:@{@"key_1": @"value_1"}
                                                             error:nil];
    XCTAssert(called);
    NSLog(@"notification: (%@ %@)", num, variationKey);
}

- (void)testNotificationCenter_Track {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    __block BOOL called = false;
    NSNumber *num = [optimizely.notificationCenter addTrackNotificationListenerWithTrackListener:^(NSString * eventKey,
                                                                                         NSString * userId,
                                                                                         NSDictionary<NSString *,id> * attributes,
                                                                                         NSDictionary<NSString *,id> * eventTags,
                                                                                         NSDictionary<NSString *,id> * event) {
        called = true;
    }];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    [optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];
                              
    XCTAssert(called);
    NSLog(@"notification: (%@)", num);
}

- (void)testNotificationCenter_Decision {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    __block BOOL called = false;
    NSNumber *num = [optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                         NSString * userId,
                                                                                                         NSDictionary<NSString *,id> * attributes,
                                                                                                         NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    BOOL enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@ %d)", num, enabled);
}

- (void)testNotificationCenter_RemoveListener {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    __block BOOL called = false;
    NSNumber *num = [optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                         NSString * userId,
                                                                                                         NSDictionary<NSString *,id> * attributes,
                                                                                                         NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    BOOL enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssert(called);
    
    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssert(called);

    // remove notification listener with type
    [optimizely.notificationCenter clearNotificationListenersWithType:NotificationTypeDecision];
    
    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssertFalse(called);

    
    num = [optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                               NSString * userId,
                                                                                               NSDictionary<NSString *,id> * attributes,
                                                                                               NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];

    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssert(called);
    
    // remove notification listener with id
    [optimizely.notificationCenter removeNotificationListenerWithNotificationId:[num intValue]];
    
    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssertFalse(called);

    num = [optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                               NSString * userId,
                                                                                               NSDictionary<NSString *,id> * attributes,
                                                                                               NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssert(called);
    
    // remove all notification listeners
    [optimizely.notificationCenter clearAllNotificationListeners];
    
    called = false;
    enabled = [optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    XCTAssertFalse(called);
    
}

// MARK: - Test custom EventDispatcher

- (void)testCustomEventDispatcher_DefaultEventDispatcher {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    // check event init and members avialable to ObjC
    EventForDispatch *event = [[EventForDispatch alloc] initWithUrl:nil body:[NSData new]];
    XCTAssertNotNil(event.url);
    XCTAssert(event.body.length==0);
    
    // check DefaultEventDispatcher work OK with ObjC clients
    DefaultEventDispatcher *eventDispatcher = [[DefaultEventDispatcher alloc] initWithTimerInterval:0];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey
                                                                     logger:nil
                                                            eventDispatcher:eventDispatcher
                                                         userProfileService:nil
                                                   periodicDownloadInterval:@(0)
                                                            defaultLogLevel:OptimizelyLogLevelInfo];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"event"];
    
    __block BOOL status = false;
    [eventDispatcher dispatchEventWithEvent:event completionHandler:^(NSData * data, NSError * error) {
        status = (data != nil);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    XCTAssert(true);
    
    [eventDispatcher flushEvents];
    
    // empty completion handler
    [eventDispatcher dispatchEventWithEvent:event completionHandler:nil];
    XCTAssert(true);
}

- (void)testCustomEventDispatcher {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    // check DefaultEventDispatcher work OK with ObjC clients
    MockOPTEventDispatcher *customEventDispatcher = [[MockOPTEventDispatcher alloc] init];
    [customEventDispatcher flushEvents];
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:[self randomSdkKey]
                                                                     logger:nil
                                                            eventDispatcher:customEventDispatcher
                                                         userProfileService:nil
                                                   periodicDownloadInterval:@(0)
                                                            defaultLogLevel:OptimizelyLogLevelInfo];
    
    [optimizely startWithDatafile:datafile error:nil];
    
    XCTAssertEqual(customEventDispatcher.eventCount, 0);
    [optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];
    XCTAssertEqual(customEventDispatcher.eventCount, 1);
}

-(NSString*)randomSdkKey {
    return [NSString stringWithFormat:@"%u", arc4random()];
}

@end

