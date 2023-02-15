#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFSession;
@class WMFConfiguration;
@class WMFFetcher;
@class MediaWikiAPIDisplayError;

// Bridge from old Obj-C fetcher classes to new Swift fetcher class
@interface WMFLegacyFetcher : NSObject

- (instancetype)initWithSession:(WMFSession *)session configuration:(WMFConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

@property (nonatomic, readonly) WMFSession *session;
@property (nonatomic, readonly) WMFConfiguration *configuration;
@property (nonatomic, strong, readonly) WMFFetcher *fetcher;

- (NSString *)performMediaWikiAPIPOSTWithCSRFTokenForURL:(NSURL *)URL withBodyParameters:(NSDictionary<NSString *, NSString *> *)bodyParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;
- (NSURLSessionTask *)performMediaWikiAPIGETForURL:(NSURL *)URL withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler;
- (NSURLSessionTask *)performMediaWikiAPIGETForURLRequest:(NSURLRequest *)urlRequest completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler;
- (NSURLSessionTask *)performCancelableMediaWikiAPIGETForURL:(NSURL *)URL cancellationKey:(NSString *)cancellationKey withQueryParameters:(NSDictionary<NSString *, id> *)queryParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler;
- (NSURLSessionTask *)performMediaWikiAPIPOSTForURL:(NSURL *)URL withBodyParameters:(NSDictionary<NSString *, id> *)bodyParameters completionHandler:(void (^)(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionHandler;

- (void)resolveMediaWikiApiErrorFromResult: (NSDictionary<NSString *, id> *)result siteURL:(NSURL *)siteURL completionHandler:(void (^)(MediaWikiAPIDisplayError * displayError)) completionHandler;

- (void)cancelAllFetches; // only cancels tasks started with the methods provided by WMFLegacyFetcher - tasks started directly on the session are not canceled
- (void)cancelTaskWithCancellationKey:(NSString *)cancellationKey;

@end

NS_ASSUME_NONNULL_END
