//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DownloadTitlesForRandomArticlesOp.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSString+Extras.h"

@implementation DownloadTitlesForRandomArticlesOp

- (id)initForDomain: (NSString *)domain
    completionBlock: (void (^)(NSString *))completionBlock
     cancelledBlock: (void (^)(NSError *))cancelledBlock
         errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        // FUTURE FEATURE: Get multiple titles, and cache them so they're readily available
        // Will need to consider things like article language changes, though.
        self.request = [NSURLRequest getRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"query",
                                                           @"list": @"random",
                                                           @"rnlimit": @"1",
                                                           @"rnnamespace": @"0",
                                                           @"format": @"json"
                                                           }
                        ];
        __weak DownloadTitlesForRandomArticlesOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            // Check for error
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Random Titles Op" code:001 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            NSArray *randomArticles = (NSArray *)weakSelf.jsonRetrieved[@"query"][@"random"];
            NSDictionary *article = [randomArticles objectAtIndex:0];
            NSString *title = article[@"title"];

            completionBlock(title);
        };
    }
    return self;
}

@end
