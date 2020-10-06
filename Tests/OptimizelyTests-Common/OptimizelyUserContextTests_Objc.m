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
static NSString * datafile;

@interface OptimizelyUserContextTests_Objc : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@end

@implementation OptimizelyUserContextTests_Objc

- (void)setUp {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"decide_datafile" ofType:@"json"];
    datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: kSdkKey];
    [self.optimizely startWithDatafile:datafile error:nil];
}

// MARK: - UserContext

- (void)testUserContext {
    OptimizelyUserContext *user = [[OptimizelyUserContext alloc] initWithOptimizely:self.optimizely
                                                                             userId:kUserId
                                                                         attributes:nil];
    XCTAssert([user.optimizely isEqual:self.optimizely]);
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert(user.attributes.count == 0);
    
    user = [[OptimizelyUserContext alloc] initWithOptimizely:self.optimizely
                                                      userId:kUserId
                                              attributes:@{@"country": @"US", @"age": @"18"}];
    XCTAssert([user.optimizely isEqual:self.optimizely]);
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert([user.attributes[@"country"] isEqualToString:@"US"]);
    XCTAssert([user.attributes[@"age"] isEqualToString:@"18"]);
}

- (void)testCreateUserContext {
    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"country": @"US", @"age": @"18"}];
    
    XCTAssert([user.optimizely isEqual:self.optimizely]);
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert([user.attributes[@"country"] isEqualToString:@"US"]);
    XCTAssert([user.attributes[@"age"] isEqualToString:@"18"]);
}

- (void)testUserContext_setAttribute {
    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:nil];
    [user setAttributeWithKey:@"country" value:@"US"];
    [user setAttributeWithKey:@"age" value:@"18"];

    XCTAssert([user.optimizely isEqual:self.optimizely]);
    XCTAssert([user.userId isEqualToString:kUserId]);
    XCTAssert([user.attributes[@"country"] isEqualToString:@"US"]);
    XCTAssert([user.attributes[@"age"] isEqualToString:@"18"]);
}

// MARK: - decide

- (void)testDecide {
    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:nil];

    NSString *featureKey = @"feature_2";
    OptimizelyDecision *decision = [user decideWithKey:featureKey options:nil];

    XCTAssert([decision.variationKey isEqualToString:@"variation_with_traffic"]);
    XCTAssertTrue(decision.enabled);
    XCTAssertNotNil(decision.variables);
    NSDictionary *variables = [decision.variables toMap];
    XCTAssert([variables[@"i_42"] intValue] == 42);
    XCTAssertNil(decision.ruleKey);
    XCTAssert([decision.flagKey isEqualToString:featureKey]);
    XCTAssert([decision.userContext.userId isEqualToString:kUserId]);
    XCTAssert(decision.reasons.count == 0);
}

- (void)testDecide_reasons {
    // new optimizely instance not started yet (SDK not ready)
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey: kSdkKey];

    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:nil];

    NSString *featureKey = @"feature_2";
    OptimizelyDecision *decision = [user decideWithKey:featureKey options:nil];

    XCTAssertNil(decision.variationKey);
    XCTAssertFalse(decision.enabled);
    XCTAssertNil(decision.variables);
    XCTAssertNil(decision.ruleKey);
    XCTAssert([decision.flagKey isEqualToString:featureKey]);
    XCTAssert([decision.userContext.userId isEqualToString:kUserId]);
    XCTAssert(decision.reasons.count == 1);
    XCTAssert([decision.reasons[0] isEqualToString:@"Optimizely SDK not configured properly yet"]);
}

//// MARK: - decideAll

- (void)testDecideAll_twoFeatures {
    NSString *featureKey1 = @"feature_1";
    NSString *featureKey2 = @"feature_2";

    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];

    NSDictionary<NSString*,OptimizelyDecision*> *decisions;
    decisions = [user decideAllWithKeys:@[featureKey1, featureKey2] options:nil];
    
    XCTAssert(decisions.count == 2);
    XCTAssertTrue(decisions[featureKey1].enabled);
    XCTAssertTrue(decisions[featureKey2].enabled);
}

- (void)testDecideAll_allFeatures {
    NSString *featureKey1 = @"feature_1";
    NSString *featureKey2 = @"feature_2";
    NSString *featureKey3 = @"feature_3";

    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];

    NSDictionary<NSString*,OptimizelyDecision*> *decisions = [user decideAllWithOptions:nil];
            
    XCTAssert(decisions.count == 3);
    XCTAssertTrue(decisions[featureKey1].enabled);
    XCTAssertTrue(decisions[featureKey2].enabled);
    XCTAssertFalse(decisions[featureKey3].enabled);
}

// MARK: - OptimizelyDecideOptions

- (void)testDecide_options {
    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];

    // array of NSNumber for OptimizelyDecideOption objc type (do not use integer directly since it may change)
    NSArray *optionsInObjcFormat = @[@(OptimizelyDecideOptionEnabledOnly)];
    NSDictionary<NSString*,OptimizelyDecision*> *decisions1 = [user decideAllWithOptions:nil];
    
    XCTAssert(decisions1.count == 3);
    XCTAssertTrue(decisions1[@"feature_1"].enabled);
    XCTAssertTrue(decisions1[@"feature_2"].enabled);
    XCTAssertFalse(decisions1[@"feature_3"].enabled);

    NSDictionary<NSString*,OptimizelyDecision*> *decisions2 = [user decideAllWithOptions:optionsInObjcFormat];
    XCTAssert(decisions2.count == 2);
    XCTAssertTrue(decisions2[@"feature_1"].enabled);
    XCTAssertTrue(decisions2[@"feature_2"].enabled);
}

- (void)testDecide_defaultOptions {
    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];
    NSDictionary<NSString*,OptimizelyDecision*> *decisions1 = [user decideAllWithOptions:nil];
    
    XCTAssert(decisions1.count == 3);
    XCTAssertTrue(decisions1[@"feature_1"].enabled);
    XCTAssertTrue(decisions1[@"feature_2"].enabled);
    XCTAssertFalse(decisions1[@"feature_3"].enabled);

    // array of NSNumber for OptimizelyDecideOption objc type (do not use integer directly since it may change)
    NSArray *defaultOptionsInObjcFormat = @[@(OptimizelyDecideOptionEnabledOnly)];
    OptimizelyClient *newOtimizely = [[OptimizelyClient alloc] initWithSdkKey:kSdkKey
                                                                       logger:nil
                                                              eventDispatcher:nil
                                                           userProfileService:nil
                                                     periodicDownloadInterval:0
                                                              defaultLogLevel:OptimizelyLogLevelDebug
                                                         defaultDecideOptions:defaultOptionsInObjcFormat];
    [newOtimizely startWithDatafile:datafile error:nil];

    user = [newOtimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];
    NSDictionary<NSString*,OptimizelyDecision*> *decisions2 = [user decideAllWithOptions:nil];
    
    XCTAssert(decisions2.count == 2);
    XCTAssertTrue(decisions2[@"feature_1"].enabled);
    XCTAssertTrue(decisions2[@"feature_2"].enabled);
}

// MARK: - legacy APIs with UserContext

- (void)testTrackWithUserContext {
    id<OPTEventDispatcher> mockEventDispatcher = [self injectMockEventDispatcher];
    OCMExpect([mockEventDispatcher dispatchEventWithEvent:[OCMArg isNotNil]
                                        completionHandler:nil]);

    OptimizelyUserContext *user = [self.optimizely createUserContextWithUserId:kUserId attributes:@{@"gender": @"f"}];

    NSError *error = nil;
    BOOL status = [user trackEventWithEventKey:@"event1" eventTags:nil error:&error];

    XCTAssertTrue(status);
    OCMVerifyAllWithDelay(mockEventDispatcher, 1.0);   // event-dispatch non-blocking
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
