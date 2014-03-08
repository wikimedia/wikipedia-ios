//  Created by Monte Hurd on 1/16/14.

#import "SearchOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "Defines.h"

@implementation SearchOp

- (id)initWithSearchTerm: (NSString *)searchTerm
         completionBlock: (void (^)(NSArray *))completionBlock
          cancelledBlock: (void (^)(NSError *))cancelledBlock
              errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        NSMutableDictionary *parameters = [@{
                                             @"action": @"opensearch",
                                             @"search": searchTerm,
                                             @"limit": SEARCH_MAX_RESULTS,
                                             @"format": @"json"
                                             } mutableCopy];
        
        
        self.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                             parameters: parameters
                        ];
        
        __weak SearchOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
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
                weakSelf.error = [NSError errorWithDomain:@"Search Op" code:001 userInfo:errorDict];
            }

            NSArray *output = @[];
            if(([[weakSelf.jsonRetrieved class] isSubclassOfClass:[NSArray class]])){
                NSArray *searchResults = (NSArray *)weakSelf.jsonRetrieved;
                if (searchResults.count == 2 && [searchResults[1] isKindOfClass:[NSArray class]]) {
                    output = (NSArray *)searchResults[1];
                }
            }
            
            if (output.count == 0) {
                NSMutableDictionary *errorDict = @{}.mutableCopy;
                
                errorDict[NSLocalizedDescriptionKey] = NSLocalizedString(@"search-no-matches", nil);
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Search Op" code:002 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            completionBlock(output);
        };
    }
    return self;
}

@end
