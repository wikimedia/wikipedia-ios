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

- (NSURLSessionTask *)performMediaWikiAPIPOSTForURL:(NSURL *)URL withBodyParameters:(NSDictionary<NSString *, NSString *> *)bodyParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    return [self.fetcher performMediaWikiAPIPOSTForURL:URL withBodyParameters:bodyParameters cancellationKey:nil completionHandler:completionHandler];
}

- (NSString *)performMediaWikiAPIPOSTWithCSRFTokenForURL:(NSURL *)URL withBodyParameters:(NSDictionary<NSString *, NSString *> *)bodyParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    return [self.fetcher performTokenizedMediaWikiAPIPOSTWithTokenType:WMFTokenTypeCsrf toURL:URL withBodyParameters:bodyParameters cancellationKey:nil completionHandler:completionHandler];
}

- (NSURLSessionTask *)performMediaWikiAPIGETForURL:(NSURL *)URL withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self performCancelableMediaWikiAPIGETForURL:URL cancellationKey:NSUUID.UUID.UUIDString withQueryParameters:queryParameters completionHandler:completionHandler];
}

- (NSURLSessionTask *)performCancelableMediaWikiAPIGETForURL:(NSURL *)URL cancellationKey:(NSString *)cancellationKey withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self.fetcher performMediaWikiAPIGETForURL:URL withQueryParameters:queryParameters cancellationKey:cancellationKey completionHandler:completionHandler];
}

- (void)cancelAllFetches {
    [self.fetcher cancelAllTasks];
}

- (void)cancelTaskWithCancellationKey:(NSString *)cancellationKey {
    [self.fetcher cancelTaskForKey:cancellationKey];
}

@end
