//
//  SaveThumbnailFetcher.h
//  Wikipedia
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "ThumbnailFetcher.h"

@interface SaveThumbnailFetcher : ThumbnailFetcher <FetchFinishedDelegate>

@property (nonatomic, strong, readonly) MWKArticle *article;

// Kick-off method. Results are stored to the article.
-(instancetype)initAndFetchThumbnailFromURL: (NSString *)url
                                 forArticle: (MWKArticle *)article
                                withManager: (AFHTTPRequestOperationManager *)manager;

@end
