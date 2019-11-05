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
#import "OptimizelyTests_Legacy_iOS-Swift.h"

static NSString * const kExperimentKey = @"exp_with_audience";
static NSString * const kVariationKey = @"a";
static NSString * const kVariationOtherKey = @"b";
static NSString * const kEventKey = @"event1";
static NSString * const kFeatureKey = @"feature_1";

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";

@interface ED_OptimizelyClientTests_ObjcOthers : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@property(nonatomic) NSString *datafile;
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

@implementation ED_OptimizelyClientTests_ObjcOthers

- (void)setUp {
    [OTUtils clearRegistryService];

    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    self.datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    [OTUtils clearRegistryService];
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"];
}

- (void)tearDown {
    [OTUtils clearRegistryService];
}

// MARK: - Test API with legacy EventDispatcher

- (void)testCustomEventDispatcher {
    // check DefaultEventDispatcher work OK with ObjC clients
    
    MockOPTEventDispatcher *customEventDispatcher = [[MockOPTEventDispatcher alloc] init];
    [customEventDispatcher flushEvents];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"
                                                        logger:nil
                                               eventDispatcher:customEventDispatcher
                                            userProfileService:nil
                                      periodicDownloadInterval:@(0)
                                               defaultLogLevel:OptimizelyLogLevelInfo];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    XCTAssertEqual(customEventDispatcher.eventCount, 0);
    [self.optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];
    sleep(1);
    XCTAssertEqual(customEventDispatcher.eventCount, 1);
}

- (void)testCustomEventDispatcher_DefaultEventDispatcher {
    // check event init and members avialable to ObjC
    
    EventForDispatch *event = [[EventForDispatch alloc] initWithUrl:nil sdkKey:@"a" body:[NSData new]];
    XCTAssertNotNil(event.url);
    XCTAssert(event.body.length==0);
    
    // check DefaultEventDispatcher work OK with ObjC clients
    DefaultEventDispatcher *eventDispatcher = [[DefaultEventDispatcher alloc] initWithBatchSize:10 timerInterval:1 maxQueueSize:1000];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"
                                                        logger:nil
                                               eventDispatcher:eventDispatcher
                                            userProfileService:nil
                                      periodicDownloadInterval:@(0)
                                               defaultLogLevel:OptimizelyLogLevelInfo];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
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

// MARK: - Test notification listners
// activate/track notification calls through EventDispatcher, so should be tested with legacy

- (void)testNotificationCenter_Activate {
    XCTestExpectation *exp = [self expectationWithDescription:@"x"];
    
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addActivateNotificationListenerWithActivateListener:^(NSDictionary<NSString *,id> * experiment,
                                                                                                              NSString * userId,
                                                                                                              NSDictionary<NSString *,id> * attributes,
                                                                                                              NSDictionary<NSString *,id> * variation,
                                                                                                              NSDictionary<NSString *,id> * event) {
        called = true;
        [exp fulfill];
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    NSString *variationKey = [self.optimizely activateWithExperimentKey:kExperimentKey
                                                                 userId:kUserId
                                                             attributes:@{@"key_1": @"value_1"}
                                                                  error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@ %@)", num, variationKey);
}

- (void)testNotificationCenter_Track {
    XCTestExpectation *exp = [self expectationWithDescription:@"x"];
    
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addTrackNotificationListenerWithTrackListener:^(NSString * eventKey,
                                                                                                        NSString * userId,
                                                                                                        NSDictionary<NSString *,id> * attributes,
                                                                                                        NSDictionary<NSString *,id> * eventTags,
                                                                                                        NSDictionary<NSString *,id> * event) {
        called = true;
        [exp fulfill];
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    [self.optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@)", num);
}

@end

