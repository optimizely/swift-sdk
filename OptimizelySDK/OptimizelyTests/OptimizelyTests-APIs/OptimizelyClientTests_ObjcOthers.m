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

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";

@interface OptimizelyClientTests_ObjcOthers : XCTestCase
@property(nonatomic) NSDictionary * attributes;
@end


@implementation OptimizelyClientTests_ObjcOthers

// MARK: - Others

- (void)testCustomNotificationCenter {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    NSString *datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    
    OptimizelyClient *optimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey];
    
    [optimizely.notificationCenter addActivateNotificationListenerWithActivateListener:^(NSDictionary<NSString *,id> * experiment,
                                                                                         NSString * userId,
                                                                                         NSDictionary<NSString *,id> * attributes,
                                                                                         NSDictionary<NSString *,id> * variation,
                                                                                         NSDictionary<NSString *,id> * event) {
    }];
    
    [optimizely.notificationCenter addTrackNotificationListenerWithTrackListener:^(NSString * eventKey,
                                                                                   NSString * userId,
                                                                                   NSDictionary<NSString *,id> * attributes,
                                                                                   NSDictionary<NSString *,id> * eventTags,
                                                                                   NSDictionary<NSString *,id> * event) {
        
    }];
     
     [optimizely.notificationCenter addD]

    
    [optimizely startWithDatafile:datafile error:nil];

}

- (void)testCustomEventDispatcher {
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
    
    //
    [optimizely startWithDatafile:datafile error:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"event"];
    
    __block BOOL status = false;
    [eventDispatcher dispatchEventWithEvent:event completionHandler:^(NSData * data, NSError * error) {
        if(data != nil) {
            status = true;
        } else {
            status = false;
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    XCTAssert(true);

    // empty completion handler
    [eventDispatcher dispatchEventWithEvent:event completionHandler:nil];
    XCTAssert(true);
}



@end

