#import "WMFProxyServer.h"
@import GCDWebServers;
#import <WMF/NSURL+WMFProxyServer.h>
#import "Wikipedia-Swift.h"
#import <WMF/WMFImageTag.h>
#import <WMF/WMFImageTag+TargetImageWidthURL.h>
#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/WMFFIFOCache.h>
#import "MWKArticle.h"

NSString *const WMFProxyServerArticleSectionDataBasePath = @"articleSectionData";
NSString *const WMFProxyServerArticleKeyQueryItem = @"articleKey";
NSString *const WMFProxyServerImageWidthQueryItem = @"imageWidth";

static const NSInteger WMFCachedResponseCountLimit = 6;

@interface WMFProxyServerResponse : NSObject
@property (nonatomic, copy) NSData *data;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, readonly) GCDWebServerResponse *GCDWebServerResponse;
+ (WMFProxyServerResponse *)responseWithData:(NSData *)data contentType:(NSString *)contentType;
@end

@interface WMFProxyServer () <GCDWebServerDelegate>
@property (nonatomic, strong) WMFFIFOCache<NSString *, WMFProxyServerResponse *> *responseCache;
@property (nonatomic, strong) WMFFIFOCache<NSString *, MWKArticle *> *articleCache;
@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic) NSUInteger port;
@property (nonatomic, copy, nonnull) NSString *secret;
@property (nonatomic, copy, nonnull) NSString *hostedFolderPath;
@property (nonatomic) NSURLComponents *hostURLComponents;
@property (nonatomic, readonly) GCDWebServerAsyncProcessBlock defaultHandler;
@end

@implementation WMFProxyServer

+ (WMFProxyServer *)sharedProxyServer {
    static dispatch_once_t onceToken;
    static WMFProxyServer *sharedProxyServer;
    dispatch_once(&onceToken, ^{
        [GCDWebServer setLogLevel:3]; // 3 = Warning
        sharedProxyServer = [[WMFProxyServer alloc] init];
    });
    return sharedProxyServer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.port = 0; // setting the port to 0 allows the OS to pick a random port on the first pass

    self.responseCache = [[WMFFIFOCache alloc] initWithCountLimit:WMFCachedResponseCountLimit];
    self.articleCache = [[WMFFIFOCache alloc] initWithCountLimit:WMFCachedResponseCountLimit];

    NSString *secret = [[NSUUID UUID] UUIDString];
    self.secret = secret;

    self.hostedFolderPath = [WikipediaAppUtils assetsPath];

    self.webServer = [[GCDWebServer alloc] init];

    self.webServer.delegate = self;

    [self.webServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] asyncProcessBlock:self.defaultHandler];

    [self start];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)start {
    if (self.isRunning) {
        return;
    }

    NSDictionary *options = @{ GCDWebServerOption_BindToLocalhost: @(YES), //only accept requests from localhost
                               GCDWebServerOption_Port: @(self.port),
                               GCDWebServerOption_AutomaticallySuspendInBackground: @(NO) };

    NSError *serverStartError = nil;
    NSUInteger attempts = 0;
    NSUInteger attemptLimit = 5;
    BOOL didStartServer = false;

    while (!didStartServer && attempts < attemptLimit) {
        didStartServer = [self.webServer startWithOptions:options error:&serverStartError];
        if (didStartServer) {
            self.port = self.webServer.port; // store the port to re-use on app resume - fixes mismatched image URLs causing images to remain blank
        } else {
            self.port = 0; // setting the port to 0 will pick a new random port on the next pass
            DDLogError(@"Error starting proxy: %@", serverStartError);
            attempts++;
            if (attempts == attemptLimit) {
                DDLogError(@"Unable to start the proxy.");
#if DEBUG
                [[WMFAlertManager sharedInstance] showEmailFeedbackAlertViewWithError:serverStartError];
#else
                NSString *errorMessage = WMFLocalizedStringWithDefaultValue(@"article-unable-to-load-article", nil, nil, @"Unable to load article.", @"Alert text shown when unable to load an article");
                [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:errorMessage
                                                                     sticky:YES
                                                      dismissPreviousAlerts:YES
                                                                tapCallBack:^{
                                                                    [self start];
                                                                }];
#endif
            }
        }
    }
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }

    [self.webServer stop];
}

#pragma mark - GCDWebServer

- (void)webServerDidStop:(GCDWebServer *)server {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) { //restart the server if it fails for some reason other than being in the background
        [self start];
    }
}

- (void)appDidEnterBackground:(NSNotification *)note {
    [self stop];
}

- (void)appWillEnterForeground:(NSNotification *)note {
    [self start];
}

- (BOOL)isRunning {
    return self.webServer.isRunning;
}

#pragma mark - Proxy Request Handler

- (GCDWebServerAsyncProcessBlock)defaultHandler {
    @weakify(self);
    return ^(GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        dispatch_block_t notFound = ^{
            completionBlock([GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"404"]);
        };

        @strongify(self);
        if (!self) {
            notFound();
            return;
        }

        NSString *path = request.path;
        NSArray *components = [path pathComponents];

        if (components.count < 3) { //ensure components exist and there are at least three
            notFound();
            return;
        }

        if (![components[1] isEqualToString:self.secret]) { //ensure the second component is the secret
            notFound();
            return;
        }

        NSString *baseComponent = components[2];

        if ([baseComponent isEqualToString:WMFProxyFileBasePath]) {
            NSArray *localPathComponents = [components subarrayWithRange:NSMakeRange(3, components.count - 3)];
            NSString *relativePath = [NSString pathWithComponents:localPathComponents];
            [self handleFileRequestForRelativePath:relativePath completionBlock:completionBlock];
        } else if ([baseComponent isEqualToString:WMFProxyImageBasePath]) {
            NSString *originalSrc = request.query[WMFProxyImageOriginalSrcKey];
            if (!originalSrc) {
                notFound();
                return;
            }

            if ([originalSrc hasPrefix:@"//"]) {
                originalSrc = [@"https:" stringByAppendingString:originalSrc];
            }

            NSURL *imgURL = [NSURL URLWithString:originalSrc];
            if (!imgURL) {
                notFound();
                return;
            }

            [self handleImageRequestForURL:imgURL completionBlock:completionBlock];
        } else if ([baseComponent isEqualToString:WMFProxyServerArticleSectionDataBasePath]) {
            NSString *articleKey = [request.URL wmf_valueForQueryKey:WMFProxyServerArticleKeyQueryItem];
            if (!articleKey) {
                notFound();
                return;
            }
            MWKArticle *article = [self articleForKey:articleKey];
            if (!article) {
                notFound();
                return;
            }
            NSString *imageWidthString = [request.URL wmf_valueForQueryKey:WMFProxyServerImageWidthQueryItem];
            if (!imageWidthString) {
                notFound();
                return;
            }
            NSInteger imageWidth = [imageWidthString integerValue];
            if (imageWidth <= 0) {
                notFound();
                return;
            }
            MWKSectionList *sections = article.sections;
            NSInteger count = sections.count;
            NSMutableArray *sectionJSONs = [NSMutableArray arrayWithCapacity:count];
            NSURL *baseURL = article.url;
            for (MWKSection *section in sections) {
                NSString *sectionHTML = [self stringByReplacingImageURLsWithProxyURLsInHTMLString:section.text withBaseURL:baseURL targetImageWidth:imageWidth];
                if (!sectionHTML) {
                    continue;
                }
                NSMutableDictionary *sectionJSON = [NSMutableDictionary dictionaryWithCapacity:5];
                sectionJSON[@"id"] = @(section.sectionId);
                sectionJSON[@"line"] = section.line;
                sectionJSON[@"level"] = section.level;
                sectionJSON[@"anchor"] = section.anchor;
                sectionJSON[@"text"] = sectionHTML;
                [sectionJSONs addObject:sectionJSON];
            }
            NSMutableDictionary *responseJSON = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary *mobileviewJSON = [NSMutableDictionary dictionaryWithCapacity:1];
            mobileviewJSON[@"sections"] = sectionJSONs;
            responseJSON[@"mobileview"] = mobileviewJSON;
            NSError *JSONError = nil;
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:responseJSON options:0 error:&JSONError];
            if (!JSONData) {
                DDLogError(@"Error serializing mobileview JSON: %@", JSONError);
                notFound();
                return;
            }
            GCDWebServerResponse *response = [GCDWebServerDataResponse responseWithData:JSONData contentType:@"application/json; charset=utf-8"];
            completionBlock(response);
        } else if ([baseComponent isEqualToString:WMFProxyAPIBasePath]) {
            NSAssert(components.count == 6, @"Expected 6 components when using WMFProxyAPIBasePath");
            if (components.count == 6) {

                // APIURL is APIProxyURL with components[3] as the host, components[4..5] as the path.
                NSURLComponents *APIProxyURLComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
                APIProxyURLComponents.path = [NSString pathWithComponents:@[@"/", components[4], components[5]]];
                APIProxyURLComponents.host = components[3];
                APIProxyURLComponents.scheme = @"https";
                NSURL *APIURL = APIProxyURLComponents.URL;
                [self handleAPIRequestForURL:APIURL completionBlock:completionBlock];

                return;
            }
            notFound();
        } else {
            notFound();
        }
    };
}

#pragma mark - Specific Handlers

- (void)handleAPIRequestForURL:(NSURL *)URL completionBlock:(GCDWebServerCompletionBlock)completionBlock {
    GCDWebServerErrorResponse *notFound = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Wikipedia API endpoint not found"];
    NSAssert(URL, @"Wikipedia API URL should not be nil");

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDataTask *APIRequestTask =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            if (response && data) {
                                                completionBlock([[GCDWebServerDataResponse alloc] initWithData:data contentType:response.MIMEType]);
                                            } else {
                                                completionBlock(notFound);
                                            }
                                        }];
    APIRequestTask.priority = NSURLSessionTaskPriorityLow;
    [APIRequestTask resume];
}

- (void)handleFileRequestForRelativePath:(NSString *)relativePath completionBlock:(GCDWebServerCompletionBlock)completionBlock {
    WMFProxyServerResponse *response = [self responseForPath:relativePath];
    if (response == nil) {
        NSString *fullPath = [self.hostedFolderPath stringByAppendingPathComponent:relativePath];
        NSURL *localFileURL = [NSURL fileURLWithPath:fullPath];
        NSNumber *isRegularFile = nil;
        NSError *fileReadError = nil;
        if ([localFileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&fileReadError] && [isRegularFile boolValue]) {
            NSData *data = [NSData dataWithContentsOfURL:localFileURL];
            NSString *contentType = GCDWebServerGetMimeTypeForExtension([localFileURL pathExtension], nil);
            response = [WMFProxyServerResponse responseWithData:data contentType:contentType];
            [self setResponseData:data withContentType:contentType forPath:relativePath];
            completionBlock(response.GCDWebServerResponse);
        } else {
            completionBlock([GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"404"]);
        }
    } else {
        completionBlock(response.GCDWebServerResponse);
    }
}

- (void)handleImageRequestForURL:(NSURL *)imgURL completionBlock:(GCDWebServerCompletionBlock)completionBlock {
    GCDWebServerErrorResponse *notFound = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Image not found"];
    NSAssert(imgURL, @"imageProxy URL should not be nil");

    NSURLCache *URLCache = [NSURLCache sharedURLCache];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imgURL];
    [request setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSCachedURLResponse *cachedResponse = [URLCache cachedResponseForRequest:request];

    if (cachedResponse.response && cachedResponse.data) {
        NSString *mimeType = cachedResponse.response.MIMEType;
        if (mimeType == nil) {
            mimeType = [imgURL wmf_mimeTypeForExtension];
        }
        NSAssert(mimeType != nil, @"MIME type not found for URL %@", imgURL);
        GCDWebServerDataResponse *gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:cachedResponse.data contentType:mimeType];
        completionBlock(gcdResponse);
    } else {
        NSURLSessionDataTask *downloadImgTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                                completionHandler:^(NSData *imgData, NSURLResponse *response, NSError *error) {
                                                                                    if (response && imgData) {
                                                                                        GCDWebServerDataResponse *gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:imgData contentType:response.MIMEType];
                                                                                        completionBlock(gcdResponse);
                                                                                        NSCachedURLResponse *responseToCache = [[NSCachedURLResponse alloc] initWithResponse:response data:imgData];
                                                                                        [URLCache storeCachedResponse:responseToCache forRequest:request];
                                                                                    } else {
                                                                                        completionBlock(notFound);
                                                                                    }
                                                                                }];
        downloadImgTask.priority = NSURLSessionTaskPriorityLow;
        [downloadImgTask resume];
    }
}

#pragma - File Proxy Paths &URLs

- (NSURL *)proxyURLForRelativeFilePath:(NSString *)relativeFilePath fragment:(NSString *)fragment {
    NSString *secret = self.secret;
    NSURL *serverURL = self.webServer.serverURL;
    if (relativeFilePath == nil || secret == nil || serverURL == nil) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, WMFProxyFileBasePath, relativeFilePath]];
    components.fragment = fragment;
    return components.URL;
}

- (NSURL *)proxyURLForWikipediaAPIHost:(NSString *)host {
    NSString *secret = self.secret;
    NSURL *serverURL = self.webServer.serverURL;
    if (secret == nil || serverURL == nil) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, WMFProxyAPIBasePath, host]];
    return components.URL;
}

- (NSString *)localFilePathForRelativeFilePath:(NSString *)relativeFilePath {
    return [self.hostedFolderPath stringByAppendingPathComponent:relativeFilePath];
}

#pragma - Article Section Data URLs

- (nullable NSURL *)articleSectionDataURLForArticleWithURL:(NSURL *)articleURL targetImageWidth:(NSInteger)targetImageWidth {
    NSString *secret = self.secret;
    NSURL *serverURL = self.webServer.serverURL;
    NSString *key = articleURL.wmf_articleDatabaseKey;
    if (secret == nil || serverURL == nil || key == nil) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, WMFProxyServerArticleSectionDataBasePath]];
    NSURLQueryItem *articleKeyQueryItem = [NSURLQueryItem queryItemWithName:WMFProxyServerArticleKeyQueryItem value:key];
    NSString *imageWidthString = [NSString stringWithFormat:@"%lli", (long long)targetImageWidth];
    NSURLQueryItem *imageWidthQueryItem = [NSURLQueryItem queryItemWithName:WMFProxyServerImageWidthQueryItem value:imageWidthString];
    if (!articleKeyQueryItem || !imageWidthString) {
        return nil;
    }

    components.queryItems = @[articleKeyQueryItem, imageWidthQueryItem];

    return components.URL;
}

#pragma - Image Proxy URLs

- (NSURL *)proxyURLForImageURLString:(NSString *)imageURLString {
    NSString *secret = self.secret;
    NSURL *serverURL = self.webServer.serverURL;
    if (secret == nil || serverURL == nil) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, WMFProxyImageBasePath]];
    NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:WMFProxyImageOriginalSrcKey value:imageURLString];
    if (queryItem) {
        components.queryItems = @[queryItem];
    }
    return components.URL;
}

- (NSString *)stringByReplacingImageURLsWithProxyURLsInHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth {

    //defensively copy
    HTMLString = [HTMLString copy];

    NSMutableString *newHTMLString = [NSMutableString stringWithString:@""];
    __block NSInteger location = 0;
    [HTMLString wmf_enumerateHTMLImageTagContentsWithHandler:^(NSString *imageTagContents, NSRange range) {
        //append the next chunk that we didn't match on to the new string
        NSString *nonMatchingStringToAppend = [HTMLString substringWithRange:NSMakeRange(location, range.location - location)];
        [newHTMLString appendString:nonMatchingStringToAppend];

        //update imageTagContents by changing the src, disabling the srcset, and adding other attributes used for scaling
        NSString *newImageTagContents = [self stringByUpdatingImageTagAttributesForProxyAndScalingInImageTagContents:imageTagContents withBaseURL:baseURL targetImageWidth:targetImageWidth];
        //append the updated image tag to the new string
        [newHTMLString appendString:[@[@"<img ", newImageTagContents, @">"] componentsJoinedByString:@""]];

        location = range.location + range.length;
    }];

    //append the final chunk of the original string
    if (HTMLString && location < HTMLString.length) {
        [newHTMLString appendString:[HTMLString substringWithRange:NSMakeRange(location, HTMLString.length - location)]];
    }

    return newHTMLString;
}

- (NSString *)stringByUpdatingImageTagAttributesForProxyAndScalingInImageTagContents:(NSString *)imageTagContents withBaseURL:(NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth {

    NSMutableString *newImageTagContents = [imageTagContents mutableCopy];

    NSString *resizedSrc = nil;

    WMFImageTag *imageTag = [[WMFImageTag alloc] initWithImageTagContents:imageTagContents baseURL:baseURL];

    if (imageTag != nil) {
        NSString *src = imageTag.src;

        if ([imageTag isSizeLargeEnoughForGalleryInclusion]) {
            resizedSrc = [[imageTag URLForTargetWidth:targetImageWidth] absoluteString];
            if (resizedSrc) {
                src = resizedSrc;
            }
        }

        if (src) {
            NSString *srcWithProxy = [self proxyURLForImageURLString:src].absoluteString;
            if (srcWithProxy) {
                NSString *newSrcAttribute = [@[@"src=\"", srcWithProxy, @"\""] componentsJoinedByString:@""];
                imageTag.src = newSrcAttribute;
                newImageTagContents = [imageTag.imageTagContents mutableCopy];
            }
        }
    }

    [newImageTagContents replaceOccurrencesOfString:@"srcset" withString:@"data-srcset-disabled" options:0 range:NSMakeRange(0, newImageTagContents.length)]; //disable the srcset since we put the correct resolution image in the src

    if (resizedSrc) {
        [newImageTagContents appendString:@" data-image-gallery=\"true\""]; //the javascript looks for this to know if it should attempt widening
    }

    return newImageTagContents;
}

#pragma mark - Cache

- (void)setResponseData:(NSData *)data withContentType:(NSString *)contentType forPath:(NSString *)path {
    if (path == nil) {
        return;
    }
    [self.responseCache setObject:[WMFProxyServerResponse responseWithData:data contentType:contentType] forKey:path];
}

- (WMFProxyServerResponse *)responseForPath:(NSString *)path {
    if (path == nil) {
        return nil;
    }
    return [self.responseCache objectForKey:path];
}

- (void)cacheSectionDataForArticle:(MWKArticle *)article {
    NSString *articleKey = article.url.wmf_articleDatabaseKey;
    if (articleKey == nil) {
        return;
    }
    [self.articleCache setObject:article forKey:articleKey];
}

- (MWKArticle *)articleForKey:(NSString *)path {
    if (path == nil) {
        return nil;
    }
    return [self.articleCache objectForKey:path];
}

#pragma mark - BaseURL (for testing only)

- (NSURL *)baseURL {
    return [self.webServer.serverURL URLByAppendingPathComponent:self.secret];
}

@end

@implementation WMFProxyServerResponse
+ (WMFProxyServerResponse *)responseWithData:(NSData *)data contentType:(NSString *)contentType {
    WMFProxyServerResponse *response = [[WMFProxyServerResponse alloc] init];
    response.data = data;
    response.contentType = contentType;
    return response;
}

- (GCDWebServerResponse *)GCDWebServerResponse {
    return [GCDWebServerDataResponse responseWithData:self.data contentType:self.contentType];
}

@end
