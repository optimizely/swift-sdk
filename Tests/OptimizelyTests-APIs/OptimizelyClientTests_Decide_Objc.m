/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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
#import <OCMock/OCMock.h>
@import Optimizely;

static NSString * const kUserId = @"tester";
static NSString * const kSdkKey = @"12345";
static NSString * const kErrorMessageUserNotSet = @"User not set properly yet";
static NSString * datafile;

@interface OptimizelyClientTests_Decide_Objc : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@end

@implementation OptimizelyClientTests_Decide_Objc

- (void)setUp {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"decide_datafile" ofType:@"json"];
    datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: kSdkKey];
    [self.optimizely startWithDatafile:datafile error:nil];
}

// MARK: - UserContext

- (void)testUserContext {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId
                                                                     attributes:nil];
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert(user.attributes.count == 0);
    
    user = [[OptimizelyUserContext alloc] initWithUserId:kUserId
                                              attributes:@{@"country": @"US", @"age": @"18"}];
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert([user.attributes[@"country"] isEqualToString:@"US"]);
    XCTAssert([user.attributes[@"age"] isEqualToString:@"18"]);
}

- (void)testUserContext_setAttribute {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId
                                                                     attributes:nil];
    [user setAttributeWithKey:@"country" value:@"US"];
    [user setAttributeWithKey:@"age" value:@"18"];

    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert([user.attributes[@"country"] isEqualToString:@"US"]);
    XCTAssert([user.attributes[@"age"] isEqualToString:@"18"]);
}

// MARK: - decide

- (void)testDecide {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:nil];
    [self.optimizely setUserContext:user];

    NSString *featureKey = @"feature_2";
    OptimizelyDecision *decision = [self.optimizely decideWithKey:featureKey user:nil options:nil];
    
    XCTAssertNotNil(decision.enabled);
    XCTAssertTrue(decision.enabled);
    XCTAssertNotNil(decision.variables);
    NSDictionary *variables = [decision.variables toMap];
    XCTAssert([variables[@"i_42"] intValue] == 42);
    XCTAssert([decision.variationKey isEqualToString:@"variation_with_traffic"]);
    XCTAssert([decision.flagKey isEqualToString:featureKey]);
    XCTAssert([decision.user.userId isEqualToString:kUserId]);
    XCTAssert(decision.reasons.count == 0);
}

- (void)testDecide_userNotSet {
    NSString *featureKey = @"feature_2";
    OptimizelyDecision *decision = [self.optimizely decideWithKey:featureKey user:nil options:nil];
    
    XCTAssertNil(decision.enabled);
    XCTAssertNil(decision.variables);
    XCTAssertNil(decision.variationKey);
    XCTAssert([decision.flagKey isEqualToString:featureKey]);
    XCTAssertNil(decision.user);
    XCTAssert(decision.reasons.count == 1);
    XCTAssert([decision.reasons[0] isEqualToString:kErrorMessageUserNotSet]);
}

- (void)testDecide_withUserContextInParamater {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:nil];

    NSString *featureKey = @"feature_2";
    OptimizelyDecision *decision = [self.optimizely decideWithKey:featureKey user:user options:nil];

    XCTAssertNotNil(decision.enabled);
    XCTAssertTrue(decision.enabled);
    XCTAssertNotNil(decision.variables);
    NSDictionary *variables = [decision.variables toMap];
    XCTAssert([variables[@"i_42"] intValue] == 42);
    XCTAssert([decision.variationKey isEqualToString:@"variation_with_traffic"]);
    XCTAssert([decision.flagKey isEqualToString:featureKey]);
    XCTAssert([decision.user.userId isEqualToString:kUserId]);
    XCTAssert(decision.reasons.count == 0);
}

// MARK: - decideAll

- (void)testDecideAll_twoFeatures {
    NSString *featureKey1 = @"feature_1";
    NSString *featureKey2 = @"feature_2";

    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:@{@"gender": @"f"}];
    [self.optimizely setUserContext:user];

    NSDictionary<NSString*,OptimizelyDecision*> *decisions;
    decisions = [self.optimizely decideAllWithKeys:@[featureKey1, featureKey2]
                                              user:nil
                                           options:nil];
    XCTAssert(decisions.count == 2);
    XCTAssertNotNil(decisions[featureKey1].enabled);
    XCTAssertNotNil(decisions[featureKey2].enabled);
}

- (void)testDecideAll_nilKeys {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:@{@"gender": @"f"}];
    [self.optimizely setUserContext:user];

    NSDictionary<NSString*,OptimizelyDecision*> *decisions = [self.optimizely decideAllWithKeys:nil
                                                                                           user:nil
                                                                                        options:nil];
    XCTAssert(decisions.count == 3);
    XCTAssertNotNil(decisions[@"feature_1"].enabled);
    XCTAssertNotNil(decisions[@"feature_2"].enabled);
    XCTAssertNotNil(decisions[@"feature_3"].enabled);
}

- (void)testDecideAll_userNotSet {
    NSDictionary *decisions = [self.optimizely decideAllWithKeys:nil
                                                            user:nil
                                                         options:nil];
    XCTAssert(decisions.count == 0);
}

- (void)testDecideAll_withUserContextInParamater {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:@{@"gender": @"f"}];
    NSDictionary<NSString*,OptimizelyDecision*> *decisions = [self.optimizely decideAllWithKeys:nil
                                                                                           user:user
                                                                                        options:nil];
    XCTAssert(decisions.count == 3);
    XCTAssertNotNil(decisions[@"feature_1"].enabled);
    XCTAssertNotNil(decisions[@"feature_2"].enabled);
    XCTAssertNotNil(decisions[@"feature_3"].enabled);
}

// MARK: - OptimizelyDecideOptions

- (void)testDecide_options {
    NSArray *options = @[@(OptimizelyDecideOptionEnabledOnly)];

    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:@{@"gender": @"f"}];
    [self.optimizely setUserContext:user];
    
    NSDictionary<NSString*,OptimizelyDecision*> *decisions1 = [self.optimizely decideAllWithKeys:nil
                                                                                            user:nil
                                                                                         options:nil];
    XCTAssert(decisions1.count == 3);

    NSDictionary<NSString*,OptimizelyDecision*> *decisions2 = [self.optimizely decideAllWithKeys:nil
                                                                                           user:nil
                                                                                        options:options];
    XCTAssert(decisions2.count == 2);
    XCTAssertNotNil(decisions2[@"feature_1"].enabled);
    XCTAssertNotNil(decisions2[@"feature_2"].enabled);
}

- (void)testDecide_defaultOptions {
    NSArray *defaultOptions = @[@(OptimizelyDecideOptionEnabledOnly)];

    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:@{@"gender": @"f"}];
    [self.optimizely setUserContext:user];

    NSDictionary<NSString*,OptimizelyDecision*> *decisions1 = [self.optimizely decideAllWithKeys:nil
                                                                                            user:nil
                                                                                         options:nil];
    XCTAssert(decisions1.count == 3);

    [self.optimizely setDefaultDecideOptions:defaultOptions];
    NSDictionary<NSString*,OptimizelyDecision*> *decisions = [self.optimizely decideAllWithKeys:nil
                                                                                           user:nil
                                                                                        options:nil];
    XCTAssert(decisions.count == 2);
    XCTAssertNotNil(decisions[@"feature_1"].enabled);
    XCTAssertNotNil(decisions[@"feature_2"].enabled);
}

// MARK: - legacy APIs with UserContext

- (void)testTrackWithUserContext {
    id<OPTEventDispatcher> mockEventDispatcher = [self injectMockEventDispatcher];
    OCMExpect([mockEventDispatcher dispatchEventWithEvent:[OCMArg isNotNil]
                                        completionHandler:nil]);

    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:nil];
    [self.optimizely setUserContext:user];

    NSError *error = nil;
    BOOL status = [self.optimizely trackWithEventKey:@"event1" user:nil eventTags:nil error:&error];

    XCTAssertTrue(status);
    OCMVerifyAllWithDelay(mockEventDispatcher, 1.0);   // event-dispatch non-blocking
}

- (void)testTrackWithUserContext_withUserContextInParamater {
    id<OPTEventDispatcher> mockEventDispatcher = [self injectMockEventDispatcher];
    OCMExpect([mockEventDispatcher dispatchEventWithEvent:[OCMArg isNotNil]
                                        completionHandler:nil]);

    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithUserId:kUserId attributes:nil];

    NSError *error = nil;
    BOOL status = [self.optimizely trackWithEventKey:@"event1" user:user eventTags:nil error:&error];

    XCTAssertTrue(status);
    OCMVerifyAllWithDelay(mockEventDispatcher, 1.0);   // event-dispatch non-blocking
}

- (void)testTrackWithUserContext_userNotSet {
    NSError *error = nil;
    BOOL status = [self.optimizely trackWithEventKey:@"any-event" user:nil eventTags:nil error:&error];
    
    XCTAssertFalse(status);
    XCTAssertNotNil(error);
    XCTAssert([error.localizedDescription isEqualToString:kErrorMessageUserNotSet]);
}

// MARK: - Utils

- (id<OPTEventDispatcher>)injectMockEventDispatcher {
    id<OPTEventDispatcher>  mockEventDispatcher = OCMClassMock([DefaultEventDispatcher class]);
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:[NSString stringWithFormat:@"%d", arc4random()]
                                                        logger:nil
                                               eventDispatcher:mockEventDispatcher
                                            userProfileService:nil
                                      periodicDownloadInterval:0
                                               defaultLogLevel:OptimizelyLogLevelDebug];
    [self.optimizely startWithDatafile:datafile error:nil];
    return mockEventDispatcher;
}

@end
