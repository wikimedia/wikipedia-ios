#import <Foundation/Foundation.h>

#import <AFNetworking/AFNetworking.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) AFHTTPSessionManager *sectionWikiTextDownloadManager;
@property (strong, nonatomic) AFHTTPSessionManager *sectionWikiTextUploadManager;
@property (strong, nonatomic) AFHTTPSessionManager *sectionPreviewHtmlFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager *languageLinksFetcher;
@property (strong, nonatomic) AFHTTPSessionManager *assetsFetchManager;

- (void)reset;
+ (QueuesSingleton *)sharedInstance;

@end
