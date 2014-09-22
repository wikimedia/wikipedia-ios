//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaZeroMessageFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"

@interface WikipediaZeroMessageFetcher()

@property (strong, nonatomic) NSString *domain;

@end

@implementation WikipediaZeroMessageFetcher

-(instancetype)initAndFetchMessageForDomain: (NSString *)domain
                                withManager: (AFHTTPRequestOperationManager *)manager
                         thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.domain = domain ? domain : @"";
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForDomain:self.domain];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        
        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Wikipedia Zero message not found."}};
        }

        //NSLog(@"WIKIPEDIA ZERO MESSAGE RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Wikipedia Zero Message Fetcher"
                                        code: WIKIPEDIA_ZERO_MESSAGE_FETCH_ERROR_API
                                    userInfo: errorDict];
        }

        NSString *output = @"";
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        [self finishWithError: error
                     userData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"WIKIPEDIA ZERO MESSAGE FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                     userData: nil];
    }];
}

-(NSDictionary *)getParams
{
    NSString *agent = [WikipediaAppUtils versionedUserAgent];
    return @{
             @"action": @"zeroconfig",
             @"type": @"message",
             @"agent": agent ? agent : @""
             };
}

-(NSString *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSString *zeroRatedMessage = rawResponse.count > 0 ? [rawResponse objectForKey:@"message"] : nil;
    
    // For testing Wikipedia Zero visual flourishes.
    // Go to WebViewController.m and uncomment the W0 part,
    // then when running the app in the simulator fire the
    // memory warning to toggle the fake state on or off.
    if ([SessionSingleton sharedInstance].zeroConfigState.fakeZeroOn) {
        zeroRatedMessage = @"Free Wikipedia by Test Operator";
    }
    return zeroRatedMessage;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING LANGUAGE LINKS FETCHER!");
}
*/

@end
