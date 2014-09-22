//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, ArticleSectionType) {
    ARTICLE_SECTION_TYPE_LEAD,
    ARTICLE_SECTION_TYPE_NON_LEAD
};

@class Article, AFHTTPRequestOperationManager;

@interface ArticleFetcher : FetcherBase

@property (strong, nonatomic, readonly) Article *article;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchSectionsForArticle: (Article *)article
                                  withManager: (AFHTTPRequestOperationManager *)manager
                           thenNotifyDelegate: (id <FetchFinishedDelegate>) delegate;

@end
