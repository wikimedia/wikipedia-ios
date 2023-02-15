#import "WMFLegacyFetcher.h"
#import <WMF/WMF-Swift.h>

@interface WMFLegacyFetcher ()

@property (nonatomic, strong, readwrite) WMFFetcher *fetcher;

@end

@implementation WMFLegacyFetcher

- (instancetype)init {
    // SINGLETONTODO
    MWKDataStore *dataStore = [MWKDataStore shared];
    self = [self initWithSession:dataStore.session configuration:dataStore.configuration];
    return self;
}

- (instancetype)initWithSession:(WMFSession *)session configuration:(WMFConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.fetcher = [[WMFFetcher alloc] initWithSession:session configuration:configuration];
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
    return [self.fetcher performMediaWikiAPIPOSTForURL:URL withBodyParameters:bodyParameters cancellationKey:nil reattemptLoginOn401Response:true completionHandler:completionHandler];
}

- (NSString *)performMediaWikiAPIPOSTWithCSRFTokenForURL:(NSURL *)URL withBodyParameters:(NSDictionary<NSString *, NSString *> *)bodyParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    return [self.fetcher performTokenizedMediaWikiAPIPOSTWithTokenType:WMFTokenTypeCsrf toURL:URL withBodyParameters:bodyParameters cancellationKey:nil reattemptLoginOn401Response:true completionHandler:completionHandler];
}

- (NSURLSessionTask *)performMediaWikiAPIGETForURL:(NSURL *)URL withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self performCancelableMediaWikiAPIGETForURL:URL cancellationKey:NSUUID.UUID.UUIDString withQueryParameters:queryParameters completionHandler:completionHandler];
}

- (NSURLSessionTask *)performMediaWikiAPIGETForURLRequest:(NSURLRequest *)urlRequest completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self performCancelableMediaWikiAPIGETForURLRequest:urlRequest cancellationKey:NSUUID.UUID.UUIDString  completionHandler:completionHandler];
}

- (NSURLSessionTask *)performCancelableMediaWikiAPIGETForURL:(NSURL *)URL cancellationKey:(NSString *)cancellationKey withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self.fetcher performMediaWikiAPIGETForURL:URL withQueryParameters:queryParameters cancellationKey:cancellationKey completionHandler:completionHandler];
}

- (NSURLSessionTask *)performCancelableMediaWikiAPIGETForURLRequest:(NSURLRequest *)urlRequest cancellationKey:(NSString *)cancellationKey completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler {
    return [self.fetcher performMediaWikiAPIGETForURLRequest:urlRequest cancellationKey:cancellationKey completionHandler:completionHandler];
}

- (void)resolveMediaWikiApiErrorFromResult: (NSDictionary<NSString *, id> *)result siteURL:(NSURL *)siteURL completionHandler:(void (^)(MediaWikiAPIDisplayError * displayError)) completionHandler {
    [self.fetcher resolveMediaWikiApiErrorFromResult:result siteURL:siteURL completionHandler:completionHandler];
}

- (void)cancelAllFetches {
    [self.fetcher cancelAllTasks];
}

- (void)cancelTaskWithCancellationKey:(NSString *)cancellationKey {
    [self.fetcher cancelTaskForKey:cancellationKey];
}

@end
