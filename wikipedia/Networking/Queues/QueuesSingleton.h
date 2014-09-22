//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperationManager.h"

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) AFHTTPRequestOperationManager *loginFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *articleFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *savedPagesFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *searchResultsFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *zeroRatedMessageFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *sectionWikiTextDownloadManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *sectionWikiTextUploadManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *sectionPreviewHtmlFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *languageLinksFetcher;
@property (strong, nonatomic) AFHTTPRequestOperationManager *accountCreationFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *pageHistoryFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *assetsFetchManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *nearbyFetchManager;

+ (QueuesSingleton *)sharedInstance;

@end
