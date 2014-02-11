//  Created by Monte Hurd on 1/16/14.

#import "LoginTokenOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation LoginTokenOp

- (id)initWithUsername: (NSString *)userName
              password: (NSString *)password
                domain: (NSString *)domain
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        NSMutableDictionary *parameters = [@{
                                             @"action": @"login",
                                             @"lgname": userName,
                                             @"lgpassword": password,
                                             @"format": @"json"
                                             }mutableCopy];
        
        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: parameters
                        ];
        __weak LoginTokenOp *weakSelf = self;
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
                weakSelf.error = [NSError errorWithDomain:@"Login Token Op" code:001 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            //NSLog(@"loginTokenOp jsonRetrieved = %@", weakSelf.jsonRetrieved);

            NSString *token = weakSelf.jsonRetrieved[@"login"][@"token"];
            
            completionBlock(token);
        };
    }
    return self;
}

@end
