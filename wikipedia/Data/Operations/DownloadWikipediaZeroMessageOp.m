//  Created by Adam Baso on 2/5/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DownloadWikipediaZeroMessageOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "WikipediaAppUtils.h"

@implementation DownloadWikipediaZeroMessageOp

- (id)initForDomain: (NSString *)domain
    completionBlock: (void (^)(NSString *))completionBlock
     cancelledBlock: (void (^)(NSError *))cancelledBlock
         errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"zeroconfig",
                                                           @"type": @"message",
                                                           @"agent": [WikipediaAppUtils appVersion]
                                                           }
                        ];
        __weak DownloadWikipediaZeroMessageOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }
            
            NSDictionary *json = weakSelf.jsonRetrieved;
            
            // Check for error retrieving message data
            if(json.count > 0 && json[@"error"]){
                NSMutableDictionary *errorDict = [json[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Wikipedia Zero Message Op" code:001 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            // NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);
            
            NSString *zeroRatedMessage = json.count > 0 ? [json objectForKey:@"message"] : nil;
            
            // For testing Wikipedia Zero visual flourishes.
            // Go to WebViewController.m and uncomment the W0 part,
            // then when running the app in the simulator fire the
            // memory warning to toggle the fake state on or off.
            if ([SessionSingleton sharedInstance].zeroConfigState.fakeZeroOn) {
                zeroRatedMessage = @"Free Wikipedia by Test Operator";
            }
            
            if (zeroRatedMessage) {
                completionBlock(zeroRatedMessage);
            }
        };
    }
    return self;
}

@end
