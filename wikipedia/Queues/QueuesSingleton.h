//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) NSOperationQueue *loginQ;
@property (strong, nonatomic) NSOperationQueue *articleRetrievalQ;
@property (strong, nonatomic) NSOperationQueue *searchQ;
@property (strong, nonatomic) NSOperationQueue *thumbnailQ;
@property (strong, nonatomic) NSOperationQueue *zeroRatedMessageStringQ;

@property (strong, nonatomic) NSOperationQueue *sectionWikiTextDownloadQ;
@property (strong, nonatomic) NSOperationQueue *sectionWikiTextUploadQ;
@property (strong, nonatomic) NSOperationQueue *sectionWikiTextPreviewQ;
@property (strong, nonatomic) NSOperationQueue *langLinksQ;
@property (strong, nonatomic) NSOperationQueue *accountCreationQ;

@property (strong, nonatomic) NSOperationQueue *randomArticleQ;

@property (strong, nonatomic) NSOperationQueue *eventLoggingQ;
@property (strong, nonatomic) NSOperationQueue *pageHistoryQ;

@property (strong, nonatomic) NSOperationQueue *assetsFileSyncQ;
@property (strong, nonatomic) NSOperationQueue *nearbyQ;

+ (QueuesSingleton *)sharedInstance;

@end
