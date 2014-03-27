//  Created by Monte Hurd on 1/16/14.

#import "DownloadLangLinksOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation DownloadLangLinksOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
          allLanguages: (NSMutableArray *)allLanguages
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"query",
                                                           @"prop": @"langlinks",
                                                           @"titles": title,
                                                           @"lllimit": @"500",
                                                           @"redirects": @"",
                                                           @"format": @"json"
                                                           }
                        ];
        __weak DownloadLangLinksOp *weakSelf = self;
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
                weakSelf.error = [NSError errorWithDomain:@"Lang Links Op" code:001 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            //NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);

            NSArray *langLinks = @[];
            NSDictionary *pages = weakSelf.jsonRetrieved[@"query"][@"pages"];
            if (pages) {
                NSDictionary *page = pages[pages.allKeys[0]];
                if (page) {
                    langLinks = page[@"langlinks"];
                }
            }

            // Get dictionary with lang code as key and the localized title as the value
            NSMutableDictionary *langCodeToLocalTitleDict = [@{} mutableCopy];
            for (NSDictionary *d in langLinks) {
                langCodeToLocalTitleDict[d[@"lang"]] = d[@"*"];
            }
            
            // Loop through the data from the languages file and add an entry to the
            // output array for each match found in langCodeToLocalTitleDict including
            // all of the keys from the lang file and the local title from the downloaded
            // results. The end results is an array containing dictionaries containing
            // the lang code, lang name, lang canonical name, and the localized title.
            // (Also, the output array's lang codes will be ordered the same as they are
            // in the lang file.)
            NSMutableArray *outputArray = [@[] mutableCopy];
            for (NSDictionary *fileDict in allLanguages) {
                if ([langCodeToLocalTitleDict objectForKey:fileDict[@"code"]]) {
                
                    if ([[SessionSingleton sharedInstance].unsupportedCharactersLanguageIds indexOfObject:fileDict[@"code"]] != NSNotFound) continue;

                    [outputArray addObject:@{
                                             @"code": fileDict[@"code"],
                                             @"canonical_name": fileDict[@"canonical_name"],
                                             @"name": fileDict[@"name"],
                                             @"*": langCodeToLocalTitleDict[fileDict[@"code"]],
                                             }];
                }
            }

            completionBlock(outputArray);
        };
    }
    return self;
}

@end
