//  Created by Monte Hurd on 1/16/14.

#import "DownloadSectionWikiTextOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation DownloadSectionWikiTextOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSNumber *)section
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"query",
                                                           @"prop": @"revisions",
                                                           @"rvprop": @"content",
                                                           @"rvlimit": @1,
                                                           @"rvsection": section,
                                                           @"titles": title,
                                                           @"format": @"json"
                                                           }
                        ];
        __weak DownloadSectionWikiTextOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            // Check for error retrieving section zero data.
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Download Wikitext Op" code:001 userInfo:errorDict];
            }
         
            NSString *revision = nil;
            NSDictionary *pages = weakSelf.jsonRetrieved[@"query"][@"pages"];
            if (pages) {
                NSDictionary *page = pages[pages.allKeys[0]];
                if (page) {
                    revision = page[@"revisions"][0][@"*"];
                }
            }

            if (!weakSelf.error && !revision) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = NSLocalizedString(@"wikitext-download-failed", nil);
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Download Wikitext Op" code:002 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            completionBlock(revision);
        };
    }
    return self;
}

@end
