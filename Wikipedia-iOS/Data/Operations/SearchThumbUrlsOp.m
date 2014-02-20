//  Created by Monte Hurd on 1/16/14.

#import "SearchThumbUrlsOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "Defines.h"

@implementation SearchThumbUrlsOp

- (id)initWithCompletionBlock: (void (^)(NSDictionary *))completionBlock
          cancelledBlock: (void (^)(NSError *))cancelledBlock
              errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
    
        __weak SearchThumbUrlsOp *weakSelf = self;
        
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
            
            NSString *barDelimitedTitles = [weakSelf.titles componentsJoinedByString:@"|"];
            //NSLog(@"barDelimitedTitles = %@", barDelimitedTitles);
            
            NSMutableDictionary *parameters = [@{
                                                 @"action": @"query",
                                                 @"prop": @"pageimages",
                                                 @"action": @"query",
                                                 @"piprop": @"thumbnail|name",
                                                 @"pilimit": SEARCH_MAX_RESULTS,
                                                 @"pithumbsize": [NSString stringWithFormat:@"%d", SEARCH_THUMBNAIL_WIDTH],
                                                 @"titles": barDelimitedTitles,
                                                 @"format": @"json"
                                                 } mutableCopy];
            
            //NSLog(@"parameters = %@", parameters);
            
            weakSelf.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                                 parameters: parameters
                            ];
        };
        
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            //NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);
            
            // Check for error.
            if(([[weakSelf.jsonRetrieved class] isSubclassOfClass:[NSDictionary class]]) && weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Search Thumb Urls Op" code:001 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            NSMutableDictionary *output = @{}.mutableCopy;
            NSDictionary *results = (NSDictionary *)weakSelf.jsonRetrieved;
            if (results.count > 0) {
                NSDictionary *pages = results[@"query"][@"pages"];
                for (NSDictionary *page in pages) {
                    if (pages[page][@"thumbnail"] && pages[page][@"title"]){
                        output[pages[page][@"title"]] = pages[page][@"thumbnail"];
                    }
                }
            }
            
            completionBlock(output);
        };
    }
    return self;
}

@end
