//
//  SavedArticlesFetcher_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SavedArticlesFetcher.h"

@class MWKImageInfoFetcher;

@interface SavedArticlesFetcher ()

@property(nonatomic, strong, readonly) dispatch_queue_t accessQueue;

- (instancetype)initWithSavedPageList:(MWKSavedPageList *)savedPageList
                       articleFetcher:(WMFArticleFetcher *)articleFetcher
                      imageController:(WMFImageController *)imageController
                     imageInfoFetcher:(MWKImageInfoFetcher *)imageInfoFetcher
    NS_DESIGNATED_INITIALIZER;

@end
