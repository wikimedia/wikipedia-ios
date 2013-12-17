//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) NSOperationQueue *articleRetrievalQ;
@property (strong, nonatomic) NSOperationQueue *searchQ;
@property (strong, nonatomic) NSOperationQueue *thumbnailQ;

+ (QueuesSingleton *)sharedInstance;

@end
