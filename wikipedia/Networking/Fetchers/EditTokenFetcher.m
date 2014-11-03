//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "EditTokenFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface EditTokenFetcher()

@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) MWKTitle *title;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSString *summary;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaWord;
@property (strong, nonatomic) NSString *token;

@end

@implementation EditTokenFetcher

-(instancetype)initAndFetchEditTokenForWikiText: (NSString *)wikiText
                                      pageTitle: (MWKTitle *)title
                                        section: (NSString *)section
                                        summary: (NSString *)summary
                                      captchaId: (NSString *)captchaId
                                    captchaWord: (NSString *)captchaWord
                                    withManager: (AFHTTPRequestOperationManager *)manager
                             thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.wikiText = wikiText ? wikiText : @"";
        self.title = title;
        assert(title != nil);
        self.section = section ? section : @"";
        self.summary = summary ? summary : @"";
        self.captchaId = captchaId ? captchaId : @"";
        self.captchaWord = captchaWord ? captchaWord : @"";
        self.token = @"";

        self.fetchFinishedDelegate = delegate;
        [self fetchTokenWithManager:manager];
    }
    return self;
}

- (void)fetchTokenWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.title.site.language];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Edit token not found."}};
        }
        
        //NSLog(@"EDIT TOKEN DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Edit Token Fetcher"
                                        code: EDIT_TOKEN_ERROR_API
                                    userInfo: errorDict];
        }

        NSDictionary *output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        self.token = output[@"token"] ? output[@"token"] : @"";

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"EDIT TOKEN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    return @{
             @"action": @"query",
             @"meta": @"tokens",
             @"format": @"json"
             }.mutableCopy;
}

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    if([rawResponse isDict]){
        id query = rawResponse[@"query"];
        if([query isDict]){
            id tokens = query[@"tokens"];
            if([tokens isDict]){
                NSString *token = tokens[@"csrftoken"];
                if (token) {
                    return @{@"token": token};
                }
            }
        }
    }
    
    return @{};
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING EDIT TOKEN FETCHER!");
}
*/

@end
