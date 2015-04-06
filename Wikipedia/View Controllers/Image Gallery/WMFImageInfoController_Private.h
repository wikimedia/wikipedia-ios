//
//  Created by Brian Gerstle on 3/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageInfoController.h"

// Model
#import "MWKArticle.h"
#import "MWKDataStore.h"
#import "MWKImage.h"
#import "MWKImageList.h"
#import "MWKImageInfo+MWKImageComparison.h"

// Networking
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+UniqueRequests.h"
#import "MWKImageInfoFetcher.h"
#import "MWKImageInfoResponseSerializer.h"

extern NSDictionary* WMFIndexImageInfo(NSArray* imageInfo);

@interface WMFImageInfoController ()

@property (nonatomic, strong, readonly) NSMutableIndexSet* fetchedIndices;

/// Map of canonical filenames to image info objects.
@property (nonatomic, strong, readonly) NSDictionary* indexedImageInfo;

@property (nonatomic, strong, readonly) MWKImageInfoFetcher* imageInfoFetcher;

/// Convenience getter for the receiver's <code>article.dataStore</code>.
@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

/// Lazily calculated array of "File:" titles from the contents of @c uniqueArticleImages
@property (nonatomic, strong, readonly) NSArray* imageFilePageTitles;

- (BOOL)hasFetchedAllItems;

- (NSRange)batchRangeForTargetIndex:(NSUInteger)index;

- (id<MWKImageInfoRequest>)fetchBatch:(NSRange)batch;

@end
