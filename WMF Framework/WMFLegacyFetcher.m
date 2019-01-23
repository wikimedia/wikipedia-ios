#import "WMFLegacyFetcher.h"
#import <WMF/WMF-Swift.h>

@interface WMFLegacyFetcher ()

@property (nonatomic, strong, readwrite) WMFFetcher *fetcher;

@end

@implementation WMFLegacyFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fetcher = [[WMFFetcher alloc] initWithSession:[WMFSession shared] configuration:[WMFConfiguration current]];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllFetches];
}

- (WMFSession *)session {
    return self.fetcher.session;
}

- (WMFConfiguration *)configuration {
    return self.fetcher.configuration;
}

- (NSURLSessionTask *)performMediaWikiAPIGETForURL:(NSURL *)URL withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self performCancelableMediaWikiAPIGETForURL:URL cancellationKey:NSUUID.UUID.UUIDString withQueryParameters:queryParameters completionHandler:completionHandler];
}

- (NSURLSessionTask *)performCancelableMediaWikiAPIGETForURL:(NSURL *)URL cancellationKey:(NSString *)cancellationKey withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    NSURLComponents *components = [self.configuration mediaWikiAPIURLComponentsForHost:URL.host withQueryParameters:queryParameters];
    NSURLSessionTask *task = [self.session getJSONDictionaryFromURL:components.URL ignoreCache:NO completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        completionHandler(result, response, error);
        [self.fetcher untrackTaskForKey:cancellationKey];
    }];
    [self.fetcher trackTask:task forKey:cancellationKey];
    return task;
}

- (void)cancelAllFetches {
    [self.fetcher cancelAllTasks];
}

- (void)cancelTaskWithCancellationKey:(NSString *)cancellationKey {
    [self.fetcher cancelTaskForKey:cancellationKey];
}

@end
