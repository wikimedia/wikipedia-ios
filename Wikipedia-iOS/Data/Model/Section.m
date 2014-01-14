//
//  Section.m
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import "Section.h"
#import "Article.h"
#import "Image.h"
#import "SectionImage.h"

#import "QueuesSingleton.h"
#import "MWNetworkOp.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "MWNetworkActivityIndicatorManager.h"

@implementation Section

@dynamic anchor;
@dynamic dateRetrieved;
@dynamic html;
@dynamic index;
@dynamic title;
@dynamic tocLevel;
@dynamic article;
@dynamic thumbnailImage;
@dynamic sectionImage;

- (void)getWikiTextThen:(void (^)(NSString *))block
{
    [[QueuesSingleton sharedInstance].sectionWikiTextQ cancelAllOperations];
   
//TODO: hook up "Searching..." mesage (once message label is available to any VCs)
    // Show "Searching..." message.
    //self.webViewController.alertLabel.text = SEARCH_LOADING_MSG_SEARCHING;
    
    MWNetworkOp *searchOp = [[MWNetworkOp alloc] init];
    //searchOp.delegate = self;
    searchOp.request = [NSURLRequest postRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                             parameters: @{
                                                           @"action": @"query",
                                                           @"prop": @"revisions",
                                                           @"rvprop": @"content",
                                                           @"rvlimit": @1,
                                                           @"rvsection": self.index,
                                                           @"titles": self.article.title,
                                                           @"format": @"json"
                                                           }
                        ];
    
    __weak MWNetworkOp *weakSearchOp = searchOp;

//TODO: hook up network activity indicator. (once networkActivityIndicatorPush is available to any VCs)
/*
    searchOp.aboutToStart = ^{
        //NSLog(@"search op aboutToStart for %@", searchTerm);
        [self networkActivityIndicatorPush];
    };
*/
    searchOp.completionBlock = ^(){
//        [self networkActivityIndicatorPop];
        if(weakSearchOp.isCancelled){
            //NSLog(@"search op completionBlock bailed (because op was cancelled) for %@", searchTerm);
            return;
        }

        if(weakSearchOp.error){
            //NSLog(@"search op completionBlock bailed on error %@", weakSearchOp.error);
            
            // Show error message.
            // (need to extract msg from error *before* main q block - the error is dealloc'ed by
            // the time the block is dequeued)
/*
            NSString *errorMsg = weakSearchOp.error.localizedDescription;
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.webViewController.alertLabel.text = errorMsg;
            }];
*/
            return;
        }else{
/*
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.webViewController.alertLabel.text = @"";
            }];
*/
        }

//TODO: hook up error message below if revision not found.
        NSDictionary *searchResults = (NSDictionary *)weakSearchOp.jsonRetrieved;
        NSDictionary *pages = searchResults[@"query"][@"pages"];//[@"5921"][@"revisions"][0][@"*"]

        if (pages) {
            NSDictionary *page = pages[pages.allKeys[0]];
            if (page) {
                NSString *revision = page[@"revisions"][0][@"*"];
                dispatch_async(dispatch_get_main_queue(), ^(){
                    block(revision);
                });
            }
        }
    };
    
    [[QueuesSingleton sharedInstance].searchQ addOperation:searchOp];
}

@end
