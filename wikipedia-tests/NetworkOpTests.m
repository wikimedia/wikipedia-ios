//  Created by Monte Hurd on 10/30/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

// Note: these tests aren't very atomic. Probably refactor when better async unit testing
// support comes to XCode.

#import <XCTest/XCTest.h>
#import "MWNetworkOp.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSRunLoop+TimeOutAndFlag.h"

@interface NetworkOpTests : XCTestCase
{
    NSString *url_;

    // Reminder: do not move NSOperationQueue or asyncTestDone flag here.
    // These need to be per-test!
}

@end

@implementation NetworkOpTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    //url_ = @"https://commons.wikimedia.org/w/api.php";
    url_ = @"https://test.wikipedia.org/w/api.php";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    // Add some vertical space between each test's terminal output.
    NSLog(@"\n\n\n\n\n\n\n\n");
}

- (void)testTokenRetrievalOp
{
    // Simple op configured to request a token.
    NSLog(@"%@", NSStringFromSelector(_cmd));

    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    __block BOOL asyncTestDone = NO;

    // To login a token is first retrieved.
    MWNetworkOp *op = [[MWNetworkOp alloc] init];
    op.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:url_]
                                       parameters: @{
                                                     @"action": @"login",
                                                     @"lgname": @"MHurd (WMF)",
                                                     @"format": @"json"
                                                     }
                  ];

    __weak MWNetworkOp *weakOp = op;

    op.completionBlock = ^(){
        XCTAssertNil(weakOp.error);
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:weakOp.dataRetrieved options:0 error:nil];
        NSLog(@"\n%s data retrieved = %@", __PRETTY_FUNCTION__, result);
        XCTAssertNotNil(result[@"login"]);
        XCTAssertNotNil(result[@"login"][@"token"]);
        asyncTestDone = YES;
    };

    [q addOperation:op];

    // Give the async test a bit of time to finish.
    [[NSRunLoop mainRunLoop] runUntilTimeout:10.0 orFinishedFlag:&asyncTestDone];
}

- (void)testLoginWithTokenOp
{
    // Op configured to request a token, then token used with second op to attempt login. Only
    // asserts that a result was retrieved from the login attempt - that way no actual account
    // credentials are recorded in the code here.
    NSLog(@"%@", NSStringFromSelector(_cmd));

    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    __block BOOL asyncTestDone = NO;

    // First retrieve token.
    MWNetworkOp *getTokenOp = [[MWNetworkOp alloc] init];
    getTokenOp.request = [NSURLRequest postRequestWithURL:[NSURL URLWithString:url_]
                                       parameters:@{
                                                    @"action": @"login",
                                                    @"lgname": @"MHurd (WMF)",
                                                    @"format": @"json"
                                                    }
    ];

    // Now make op to take token and use it and a pwd for actual login attempt.
    MWNetworkOp *loginWithTokenOp = [[MWNetworkOp alloc] init];
    
    // The login attempt op should happen *after* the getToken op, so add dependency.
    [loginWithTokenOp addDependency:getTokenOp];
    __weak MWNetworkOp *weakLoginWithTokenOp = loginWithTokenOp;
    
    // loginWithTokenOp is dependent on getTokenOp, so "aboutToStart" won't fire until getTokenOp is done.
    loginWithTokenOp.aboutToStart = ^(){
        XCTAssertNotNil(getTokenOp.dataRetrieved);
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:getTokenOp.dataRetrieved options:0 error:nil];
        NSLog(@"\n%s token retrieved = %@", __PRETTY_FUNCTION__, result);
        XCTAssertNotNil(result[@"login"]);
        XCTAssertNotNil(result[@"login"][@"token"]);
        NSString *token = result[@"login"][@"token"];
        weakLoginWithTokenOp.request = [NSURLRequest postRequestWithURL:[NSURL URLWithString:url_]
            parameters:@{
                         @"action": @"login",
                         @"lgname": @"MHurd (WMF)",
                         @"lgpassword": @"NOT MY REAL PWD",
                         @"format": @"json",
                         @"lgtoken": token
        }];
    };

    // Confirm that a login result was obtained.
    loginWithTokenOp.completionBlock = ^(){
        XCTAssertNotNil(weakLoginWithTokenOp.dataRetrieved);
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:weakLoginWithTokenOp.dataRetrieved options:0 error:nil];
        NSLog(@"\n%s login data retrieved = %@", __PRETTY_FUNCTION__, result);
        XCTAssertNotNil(result[@"login"]);
        XCTAssertNotNil(result[@"login"][@"result"]);

        // Let the run loop know it can stop waiting.
        asyncTestDone = YES;
    };

    // Add the token retrieval and login attempt ops to the q.
    [q addOperation:getTokenOp];
    [q addOperation:loginWithTokenOp];

    // Gives the ops a time window within which to complete their tasks before the XCTest considers this unit test done.
    [[NSRunLoop mainRunLoop] runUntilTimeout:10.0 orFinishedFlag:&asyncTestDone];
}

-(void)testNameCheckOp
{
    // Simple op configured to check if a file name already exists on server.
    NSLog(@"%@", NSStringFromSelector(_cmd));

    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    __block BOOL asyncTestDone = NO;

    MWNetworkOp *op = [[MWNetworkOp alloc] init];
    op.request = [NSURLRequest getRequestWithURL: [NSURL URLWithString:url_]
                                      parameters: @{
                                                    @"action": @"query",
                                                    @"prop": @"imageinfo",
                                                    @"format": @"json",
                                                    @"titles": @"File:Asfafasdfas87876.jpg",
                                                    }
                  ];

    __weak MWNetworkOp *weakOp = op;

    op.completionBlock = ^(){
        XCTAssertNil(weakOp.error);
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:weakOp.dataRetrieved options:0 error:nil];
        NSLog(@"\n%s data retrieved = %@", __PRETTY_FUNCTION__, result);
        XCTAssertNotNil(result[@"query"]);
        XCTAssertNotNil(result[@"query"][@"pages"]);
        NSLog(@"\n%s file name already taken = %@", __PRETTY_FUNCTION__, result[@"query"][@"pages"][@"-1"] == nil ? @"YES" : @"NO");
        asyncTestDone = YES;
    };

    [q addOperation:op];

    // Give the async test a bit of time to finish.
    [[NSRunLoop mainRunLoop] runUntilTimeout:10.0 orFinishedFlag:&asyncTestDone];
}

@end
