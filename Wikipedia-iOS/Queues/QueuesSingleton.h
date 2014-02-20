//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) NSOperationQueue *loginQ;
@property (strong, nonatomic) NSOperationQueue *articleRetrievalQ;
@property (strong, nonatomic) NSOperationQueue *searchQ;
@property (strong, nonatomic) NSOperationQueue *thumbnailQ;
@property (strong, nonatomic) NSOperationQueue *zeroRatedMessageStringQ;

@property (strong, nonatomic) NSOperationQueue *sectionWikiTextQ;
@property (strong, nonatomic) NSOperationQueue *langLinksQ;
@property (strong, nonatomic) NSOperationQueue *accountCreationQ;

+ (QueuesSingleton *)sharedInstance;

@end
