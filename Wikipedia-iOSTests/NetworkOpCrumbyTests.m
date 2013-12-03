//
//  NetworkOpTests.m
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 11/13/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURLRequest+DictionaryRequest.h"
#import "MWCrumbyTest.h"
#import "MWNetworkOp.h"
#import "NSRunLoop+TimeOutAndFlag.h"

#pragma mark - Defines

#define TEST_ACCOUNT_USERNAME @"montehurd"
#define TEST_ACCOUNT_PASSWORD @""
#define TEST_URL @"https://commons.wikimedia.org/w/api.php" //@"https://test.wikipedia.org/w/api.php"
#define TEST_MAX_DURATION 8.0

@interface NetworkOpCrumbyTests : XCTestCase {
    NSString *userName_;
    NSString *userPassword_;
    __strong MWCrumbyTest *goodPasswordTest;
    __strong MWCrumbyTest *badPasswordTest;
}

@end

@implementation NetworkOpCrumbyTests

#pragma mark - setUp and tearDown

- (void)setUp
{
    userName_ = TEST_ACCOUNT_USERNAME;
    userPassword_ = TEST_ACCOUNT_PASSWORD;

    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

/*
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    MWCrumbyTest *test = (MWCrumbyTest *)object;
    
    NSString *statusDescription = [NSString stringWithFormat:
                                   @"%@\nTrailhead: %@ | Expected trail: %@ | Trail hiked so far: %@ | Test status: %@",
                                   test.description,
                                   NSStringFromSelector(test.kickoffSelector),
                                   test.expectedTrail,
                                   (test.trailSoFar.length == 0) ? @"*" : test.trailSoFar,
                                   [test displayNameForStatus:test.status]
                                   ];
    
    NSLog(@"\n\nTEST STATUS CHANGED, TEST = %@\n\n", statusDescription);
}
*/

#pragma mark - Test validation

-(void)validateTest:(MWCrumbyTest *)test
{
    NSLog(@"\
    \n\nMWCrumbyTest: [%p] \'%@\'\
    \n\tFinal State: %@\
    \n\tFinal Trail: %@\
    \n\tExpected Trail: %@\
    ",
        test,
        test.description,
        [test displayNameForStatus:test.status],
        test.trailSoFar,
        test.expectedTrail
    );
    XCTAssertEqual(test.status, CRUMBY_STATUS_ARRIVED_SAFELY, @"MWCrumbyTest failure: Unexpected Final State.");
}

#pragma mark - Tests

- (void)testTokenLoginAndFileNameCheckWithGoodPassword
{
return;
    // Note: If enough failed attempts happen, the api appears to sometimes respond with "WrongPass" if correct password is
    // provided soon after too many failed attempts.

    // Only run this test if a password has been supplied
    if (userPassword_ == nil) return;
    if (userPassword_.length == 0) return;

    goodPasswordTest = [[MWCrumbyTest alloc] initWithTrailhead : @selector(test_token_login_namecheck:)
                                                  target : self
                                           trailExpected : @"ABCDEFggg"
                                             description : @"Test token, login and namecheck with good password"
                  ];
    //[test addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    [goodPasswordTest hike];
    
    // Schedule a results check so XCTAssert's can verify and report back.
    // Needs to be scheduled before runUntilTimeout:orFinishedFlag: is called!
    [self performSelector:@selector(validateTest:) withObject:goodPasswordTest afterDelay:TEST_MAX_DURATION];

    // Give the async test just a bit more time than maxTestDuration to finish
    // Don't move this into the "setUp" method! Needs to happen after "hike" is called!
    __block BOOL asyncTestDone = NO;
    [[NSRunLoop mainRunLoop] runUntilTimeout:TEST_MAX_DURATION + 0.1 orFinishedFlag:&asyncTestDone];
}

- (void)testTokenLoginAndFileNameCheckWithBadPassword
{
return;
    // Force a bad password.
    userPassword_ = @"asdfasdf";

    badPasswordTest = [[MWCrumbyTest alloc] initWithTrailhead : @selector(test_token_login_namecheck:)
                                                  target : self
                                           trailExpected : @"ABCDggg"
                                             description : @"Test token, login and namecheck with bad password"
                  ];
    //[test addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    [badPasswordTest hike];
    
    // Schedule a results check so XCTAssert's can verify and report back.
    // Needs to be scheduled before runUntilTimeout:orFinishedFlag: is called!
    [self performSelector:@selector(validateTest:) withObject:badPasswordTest afterDelay:TEST_MAX_DURATION];

    // Give the async test just a bit more time than maxTestDuration to finish
    // Don't move this into the "setUp" method! Needs to happen after "hike" is called!
    __block BOOL asyncTestDone = NO;
    [[NSRunLoop mainRunLoop] runUntilTimeout:TEST_MAX_DURATION + 0.1 orFinishedFlag:&asyncTestDone];
}

#pragma mark - Test forests

-(void)test_token_login_namecheck:(MWCrumbyTest *)test
{
return;
    // Logout op ------
    MWNetworkOp *logoutOp = [[MWNetworkOp alloc] init];
    //__weak MWNetworkOp *weakLogoutOp = logoutOp;

    logoutOp.request = [NSURLRequest postRequestWithURL:[NSURL URLWithString:TEST_URL]
                                             parameters:@{
                                                          @"action": @"logout",
                                                          @"format": @"json"
                                                          }
                        ];
    
    logoutOp.aboutToStart = ^(){
        
    };
    logoutOp.completionBlock = ^{
        
    };
    logoutOp.aboutToDealloc = ^{
        
    };
    // --------

    // Get token op ------
    MWNetworkOp *getTokenOp = [[MWNetworkOp alloc] init];
    //__weak MWNetworkOp *weakGetTokenOp = getTokenOp;

    [test dropCrumb:@"A"];
    
    [getTokenOp addDependency:logoutOp];
    getTokenOp.request = [NSURLRequest postRequestWithURL:[NSURL URLWithString:TEST_URL]
                                               parameters:@{
                                                            @"action": @"login",
                                                            @"lgname": userName_,
                                                            @"format": @"json"
                                                            }
                          ];

    getTokenOp.completionBlock = ^{
        [test dropCrumb:@"B"];
    };
    
    getTokenOp.aboutToDealloc = ^{
        [test dropCrumb:@"g"];
    };
    // --------

    // Login op ------
    MWNetworkOp *loginOpWithToken = [[MWNetworkOp alloc] init];
    __weak MWNetworkOp *weakLoginOpWithToken = loginOpWithToken;

    [loginOpWithToken addDependency:getTokenOp];
    
    loginOpWithToken.aboutToStart = ^(){
        
        [test dropCrumb:@"C"];
        NSDictionary *json = getTokenOp.jsonRetrieved;
        NSString *token = json[@"login"][@"token"];
        NSLog(@"\n\n\nTOKEN RETRIEVED: %@\n\n\n", token);
        if(!token){
            [weakLoginOpWithToken cancel];
        }else{
            weakLoginOpWithToken.request = [NSURLRequest postRequestWithURL:[NSURL URLWithString:TEST_URL]
                                                                 parameters:@{
                                                                              @"action": @"login",
                                                                              @"lgname": userName_,
                                                                              @"lgpassword": userPassword_,
                                                                              @"format": @"json",
                                                                              @"lgtoken": token
                                                                              }];
        }
    };

    loginOpWithToken.completionBlock = ^{
        [test dropCrumb:@"D"];
        NSString *result = weakLoginOpWithToken.jsonRetrieved[@"login"][@"result"];
        NSLog(@"Login results = %@", weakLoginOpWithToken.jsonRetrieved);
        if (![result isEqualToString:@"Success"]){
            // Set error so child ops don't even start!
            weakLoginOpWithToken.error = [NSError errorWithDomain:@"Login" code:001 userInfo:nil];
        }
    };
    
    loginOpWithToken.aboutToDealloc = ^{
        [test dropCrumb:@"g"];
    };
    // --------

    // Name check op ------
    MWNetworkOp *nameCheckOp = [[MWNetworkOp alloc] init];
    __weak MWNetworkOp *weakNameCheckOp = nameCheckOp;

    [nameCheckOp addDependency:loginOpWithToken];

    nameCheckOp.aboutToStart = ^(){
        [test dropCrumb:@"E"];
            weakNameCheckOp.request = [NSURLRequest getRequestWithURL:[NSURL URLWithString:TEST_URL]
                                                           parameters:@{
                                                                        @"action": @"query",
                                                                        @"prop": @"imageinfo",
                                                                        @"format": @"json",
                                                                        @"titles": @"File:Asfafasdfas87876.jpg",
                                                                        }
                                       ];
    };
    
    nameCheckOp.completionBlock = ^(){
        [test dropCrumb:@"F"];
        if (!weakNameCheckOp.error) {
            NSError *error = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:weakNameCheckOp.dataRetrieved options:0 error:&error];
            NSLog(@"Name check results = %@", result);
        }
    };
    
    nameCheckOp.aboutToDealloc = ^{
        [test dropCrumb:@"g"];
    };
    // --------

    // Queue! --------
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    [opQueue addOperation:logoutOp];
    [opQueue addOperation:getTokenOp];
    [opQueue addOperation:loginOpWithToken];
    [opQueue addOperation:nameCheckOp];
    // --------
}

@end
