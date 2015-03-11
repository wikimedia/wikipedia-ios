//  Wikipedia
//
//  Created by Brian Gerstle on 2/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "FetcherBase.h"

@class MWKArticle;
@class MWKSite;
@class AFHTTPRequestOperation;
@class AFHTTPRequestOperationManager;

@protocol MWKImageInfoRequest <NSObject>

- (void)cancel;

@end

@interface MWKImageInfoFetcher : FetcherBase

- (instancetype)initWithDelegate:(id<FetchFinishedDelegate>)delegate;

/**
 * Fetch the imageinfo for the given image page titles.
 * @param imageTitles One or more page titles to get imageinfo for (e.g. @c "File:My_Image_Title.jpg).
 * @param site        The wikipedia site which should be targeted (e.g. @c "en").
 * @return An operation which can be used to set success and failure handling or cancel the originating request.
 */
- (id<MWKImageInfoRequest>)fetchInfoForPageTitles:(NSArray*)imageTitles
                                         fromSite:(MWKSite*)site
                                          success:(void (^)(NSArray* infoObjects))success
                                          failure:(void (^)(NSError* error))failure;

@end
