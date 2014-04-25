//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PreviewWikiTextOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@implementation PreviewWikiTextOp

- (id)initWithDomain: (NSString *)domain
               title: (NSString *)title
            wikiText: (NSString *)wikiText
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        NSMutableDictionary *parameters = [@{
                                             @"action": @"parse",
                                             @"sectionpreview": @"true",
                                             @"pst": @"true",
                                             @"mobileformat": @"true",
                                             @"title": title,
                                             @"prop": @"text",
                                             @"text": wikiText,
                                             @"format": @"json"
                                             }mutableCopy];
        
        // Note: "Preview should probably stay as a post, since the wikitext chunk may be pretty long and there may or may not be a limit on URL length some" - Brion
        self.request = [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: parameters
                        ];
        
        __weak PreviewWikiTextOp *weakSelf = self;
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
                weakSelf.error = [NSError errorWithDomain:@"Preview WikiText Op" code:001 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            //NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);
            NSString *result = weakSelf.jsonRetrieved[@"parse"][@"text"][@"*"];
            
            completionBlock(result);
        };
    }
    return self;
}

@end
