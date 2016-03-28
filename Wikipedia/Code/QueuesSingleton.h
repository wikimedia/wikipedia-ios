
#import <Foundation/Foundation.h>

#import <AFNetworking/AFNetworking.h>

@interface QueuesSingleton : NSObject

@property (strong, nonatomic) AFHTTPSessionManager* loginFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* articleFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* searchResultsFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* zeroRatedMessageFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* sectionWikiTextDownloadManager;
@property (strong, nonatomic) AFHTTPSessionManager* sectionWikiTextUploadManager;
@property (strong, nonatomic) AFHTTPSessionManager* sectionPreviewHtmlFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* languageLinksFetcher;
@property (strong, nonatomic) AFHTTPSessionManager* accountCreationFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* pageHistoryFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* assetsFetchManager;
@property (strong, nonatomic) AFHTTPSessionManager* nearbyFetchManager;

- (void)            reset;
+ (QueuesSingleton*)sharedInstance;

@end
