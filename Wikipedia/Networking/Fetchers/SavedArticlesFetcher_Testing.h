//
//  SavedArticlesFetcher_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SavedArticlesFetcher.h"

@interface SavedArticlesFetcher ()

/**
 *  The queue used to send and receive responses to article requests.
 *
 *  Exposed so tests can enqueue state checks to ensure they happen after the expected action on the fetcher's
 *  internal queue.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t accessQueue;

@end
