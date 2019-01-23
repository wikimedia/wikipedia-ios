#import <WMF/AFNetworking.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) AFHTTPSessionManager *sectionWikiTextUploadManager;
@property (strong, nonatomic) AFHTTPSessionManager *sectionPreviewHtmlFetchManager;

- (void)reset;
+ (QueuesSingleton *)sharedInstance;

@end
