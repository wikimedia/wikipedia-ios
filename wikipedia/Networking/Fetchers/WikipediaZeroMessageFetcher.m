//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikipediaZeroMessageFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "Defines.h"
#import "WikipediaAppUtils.h"
#import "WMF_Colors.h"

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
        
        // If we're simulating with memory warnings in WebViewcontroller.m,
        // don't trigger an error for non-dictionary responses, but rather
        // simulate a received message.
        // But if we're not simulating, force an error on non-dictionary responses.
        if ([SessionSingleton sharedInstance].zeroConfigState.fakeZeroOn) {
            responseObject = @{
                     @"message": @"Free Wikipedia by Test Operator",
                     @"foreground": @"#00FF00",
                     @"background": @"#ff69b4"
                     };
        } else if (![responseObject isDict]) {
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

        NSDictionary *output;
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

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    // For testing Wikipedia Zero visual flourishes,
    // go to WebViewController.m and uncomment the W0 part,
    // then when running the app in the simulator fire the
    // memory warning to toggle the fake state on or off.
    if (rawResponse.count == 0) {
        return nil;
    }
    
    NSString *message = rawResponse[@"message"];
    UIColor *foreground = [self UIColorFromHexString:rawResponse[@"foreground"]];
    UIColor *background = [self UIColorFromHexString:rawResponse[@"background"]];
    
    if (message && foreground && background) {
        return @{
                 @"message": message,
                 @"foreground": foreground,
                 @"background": background
                 };
    }
    return nil;
}

-(UIColor *)UIColorFromHexString:(NSString*)hexString
{
    if (hexString && [hexString hasPrefix:@"#"] && hexString.length == 7) {
        @try {
            // Tip from https://stackoverflow.com/questions/3010216/how-can-i-convert-rgb-hex-string-into-uicolor-in-objective-c/13648705#13648705
            NSScanner *scanner = [NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(1, 6)]];
            unsigned hex;
            if (![scanner scanHexInt:&hex]) return nil;
            return UIColorFromRGBWithAlpha(hex,1.0);
        }
        
        @catch (NSException *e) {
            return nil;
        }
    }
    return nil;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING LANGUAGE LINKS FETCHER!");
}
*/

@end
