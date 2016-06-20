#import "WMFProxyServer.h"

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerFileResponse.h"
#import "NSURL+WMFExtras.h"
#import "NSString+WMFExtras.h"

@interface WMFProxyServer ()
@property (nonatomic, strong, nonnull) GCDWebServer* webServer;
@property (nonatomic, copy, nonnull) NSString* secret;
@property (nonatomic, copy, nonnull) NSString* hostedFolderPath;
@property (nonatomic) NSURLComponents* hostURLComponents;
@property (nonatomic, readonly) GCDWebServerAsyncProcessBlock defaultHandler;
@end

@implementation WMFProxyServer

+ (WMFProxyServer*)sharedProxyServer {
    static dispatch_once_t onceToken;
    static WMFProxyServer* sharedProxyServer;
    dispatch_once(&onceToken, ^{
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
    NSString* secret = [[NSUUID UUID] UUIDString];
    self.secret    = secret;
    self.webServer = [[GCDWebServer alloc] init];

    NSURL* documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* assetsURL    = [documentsURL URLByAppendingPathComponent:@"assets"];
    self.hostedFolderPath = assetsURL.path;

    [self.webServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] asyncProcessBlock:self.defaultHandler];

    NSDictionary* options = @{GCDWebServerOption_BindToLocalhost: @(YES), //only accept requests from localhost
                              GCDWebServerOption_Port: @(0)};// allow the OS to pick a random port

    NSError* serverStartError = nil;
    if (![self.webServer startWithOptions:options error:&serverStartError]) {
        DDLogError(@"Error starting proxy: %@", serverStartError);
    }
}

#pragma mark - Proxy Request Handler

- (GCDWebServerAsyncProcessBlock)defaultHandler {
    @weakify(self);
    return ^(GCDWebServerRequest* request, GCDWebServerCompletionBlock completionBlock) {
               dispatch_block_t notFound = ^{
                   completionBlock([GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"404"]);
               };

               @strongify(self);
               if (!self) {
                   notFound();
                   return;
               }

               NSString* path      = request.path;
               NSArray* components = [path pathComponents];

               if (components.count < 3) { //ensure components exist and there are at least three
                   notFound();
                   return;
               }

               if (![components[1] isEqualToString:self.secret]) { //ensure the second component is the secret
                   notFound();
                   return;
               }

               NSString* baseComponent = components[2];

               if ([baseComponent isEqualToString:@"fileProxy"]) {
                   NSArray* localPathComponents = [components subarrayWithRange:NSMakeRange(3, components.count - 3)];
                   NSString* relativePath       = [NSString pathWithComponents:localPathComponents];
                   [self handleFileRequestForRelativePath:relativePath completionBlock:completionBlock];
               } else if ([baseComponent isEqualToString:@"imageProxy"]) {
                   NSString* originalSrc = request.query[@"originalSrc"];
                   if (!originalSrc) {
                       notFound();
                       return;
                   }

                   if ([originalSrc hasPrefix:@"//"]) {
                       originalSrc = [@"https:" stringByAppendingString:originalSrc];
                   }

                   NSURL* imgURL = [NSURL URLWithString:originalSrc];
                   if (!imgURL) {
                       notFound();
                       return;
                   }

                   [self handleImageRequestForURL:imgURL completionBlock:completionBlock];
               } else {
                   notFound();
               }
    };
}

#pragma mark - Specific Handlers

- (void)handleFileRequestForRelativePath:(NSString*)relativePath completionBlock:(GCDWebServerCompletionBlock)completionBlock {
    NSString* fullPath      = [self.hostedFolderPath stringByAppendingPathComponent:relativePath];
    NSURL* localFileURL     = [NSURL fileURLWithPath:fullPath];
    NSNumber* isRegularFile = nil;
    NSError* fileReadError  = nil;
    if ([localFileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&fileReadError] && [isRegularFile boolValue]) {
        completionBlock([GCDWebServerFileResponse responseWithFile:localFileURL.path]);
    } else {
        completionBlock([GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"404"]);
    }
}

- (void)handleImageRequestForURL:(NSURL*)imgURL completionBlock:(GCDWebServerCompletionBlock)completionBlock {
    GCDWebServerErrorResponse* notFound = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"Image not found"];
    NSAssert(imgURL, @"imageProxy URL should not be nil");

    NSURLCache* URLCache                = [NSURLCache sharedURLCache];
    NSURLRequest* request               = [NSURLRequest requestWithURL:imgURL];
    NSCachedURLResponse* cachedResponse = [URLCache cachedResponseForRequest:request];

    if (cachedResponse.response && cachedResponse.data) {
        NSString* mimeType = cachedResponse.response.MIMEType;
        if (mimeType == nil) {
            mimeType = [imgURL wmf_mimeTypeForExtension];
        }
        NSAssert(mimeType != nil, @"MIME type not found for URL %@", imgURL);
        GCDWebServerDataResponse* gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:cachedResponse.data contentType:mimeType];
        completionBlock(gcdResponse);
    } else {
        NSURLSessionDataTask* downloadImgTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData* imgData, NSURLResponse* response, NSError* error) {
            if (response && imgData) {
                GCDWebServerDataResponse* gcdResponse = [[GCDWebServerDataResponse alloc] initWithData:imgData contentType:response.MIMEType];
                completionBlock(gcdResponse);
                NSCachedURLResponse* responseToCache = [[NSCachedURLResponse alloc] initWithResponse:response data:imgData];
                [URLCache storeCachedResponse:responseToCache forRequest:request];
            } else {
                completionBlock(notFound);
            }
        }];
        [downloadImgTask resume];
    }
}

#pragma - File Proxy Paths & URLs

- (NSURL*)proxyURLForRelativeFilePath:(NSString*)relativeFilePath fragment:(NSString*)fragment {
    NSString* secret = self.secret;
    if (!relativeFilePath || !secret) {
        return nil;
    }
    NSURLComponents* components = [NSURLComponents componentsWithURL:self.webServer.serverURL resolvingAgainstBaseURL:NO];
    components.path     = [NSString pathWithComponents:@[@"/", secret, @"fileProxy", relativeFilePath]];
    components.fragment = fragment;
    return components.URL;
}

- (NSString*)localFilePathForRelativeFilePath:(NSString*)relativeFilePath {
    return [self.hostedFolderPath stringByAppendingPathComponent:relativeFilePath];
}

#pragma - Image Proxy URLs

- (NSURL*)proxyURLForImageURLString:(NSString*)imageURLString {
    NSString* secret = self.secret;
    if (!secret) {
        return nil;
    }
    NSURLComponents* components = [NSURLComponents componentsWithURL:self.webServer.serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, @"imageProxy"]];
    NSURLQueryItem* queryItem = [NSURLQueryItem queryItemWithName:@"originalSrc" value:imageURLString];
    if (queryItem) {
        components.queryItems = @[queryItem];
    }
    return components.URL;
}

- (NSString*)stringByReplacingImageURLsWithProxyURLsInHTMLString:(NSString*)string {
    static NSRegularExpression* regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(<img\\s+[^>]*src\\=)(?:\")(.*?)(?:\")(.*?[^>]*)(>)";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });

    NSMutableString* mutableString = [string mutableCopy];

    NSArray* matches = [regex matchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length])];

    NSInteger offset = 0;
    for (NSTextCheckingResult* result in matches) {
        NSRange resultRange = [result range];
        resultRange.location += offset;

        NSString* opener = [regex replacementStringForResult:result
                                                    inString:mutableString
                                                      offset:offset
                                                    template:@"$1"];

        NSString* srcURL = [regex replacementStringForResult:result
                                                    inString:mutableString
                                                      offset:offset
                                                    template:@"$2"];

        NSString* nonSrcPartsOfImgTag = [regex replacementStringForResult:result
                                                                 inString:mutableString
                                                                   offset:offset
                                                                 template:@"$3"];

        NSString* closer = [regex replacementStringForResult:result
                                                    inString:mutableString
                                                      offset:offset
                                                    template:@"$4"];

        if ([srcURL wmf_trim].length > 0) {
            srcURL = [self proxyURLForImageURLString:srcURL].absoluteString;
        }

        NSString* replacement = [NSString stringWithFormat:@"%@\"%@\"%@%@",
                                 opener,
                                 srcURL,
                                 [self stringByReplacingSrcsetURLsWithProxyURLsInString:nonSrcPartsOfImgTag],
                                 closer
                                ];

        [mutableString replaceCharactersInRange:resultRange withString:replacement];

        offset += [replacement length] - resultRange.length;
    }

    return mutableString;
}

- (NSString*)stringByReplacingSrcsetURLsWithProxyURLsInString:(NSString*)string {
    NSAssert(![string containsString:@"<"] && ![string containsString:@">"], @"This method should only operate on an html img tag's 'srcset' key/value substring - not entire image tags.");

    static NSRegularExpression* regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(.+?)(srcset\\=)(?:\")(.+?)(?:\")(.*?)";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });

    NSMutableString* mutableString = [string mutableCopy];

    NSArray* matches = [regex matchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length])];

    NSInteger offset = 0;
    for (NSTextCheckingResult* result in matches) {
        NSRange resultRange = [result range];
        resultRange.location += offset;

        NSString* before = [regex replacementStringForResult:result
                                                    inString:mutableString
                                                      offset:offset
                                                    template:@"$1"];

        NSString* srcsetKey = [regex replacementStringForResult:result
                                                       inString:mutableString
                                                         offset:offset
                                                       template:@"$2"];

        NSString* srcsetValue = [regex replacementStringForResult:result
                                                         inString:mutableString
                                                           offset:offset
                                                         template:@"$3"];

        NSString* after = [regex replacementStringForResult:result
                                                   inString:mutableString
                                                     offset:offset
                                                   template:@"$4"];

        NSString* replacement = [NSString stringWithFormat:@"%@%@\"%@\"%@",
                                 before,
                                 srcsetKey,
                                 [self stringByReplacingURLsWithProxyURLsInSrcsetValue:srcsetValue],
                                 after
                                ];

        [mutableString replaceCharactersInRange:resultRange withString:replacement];

        offset += [replacement length] - resultRange.length;
    }
    return mutableString;
}

- (NSString*)stringByReplacingURLsWithProxyURLsInSrcsetValue:(NSString*)srcsetValue {
    NSAssert(![srcsetValue containsString:@"<"] && ![srcsetValue containsString:@">"], @"This method should only operate on an html img tag's 'srcset' value substring - not entire image tags.");

    NSArray* pairs         = [srcsetValue componentsSeparatedByString:@","];
    NSMutableArray* output = [[NSMutableArray alloc] init];
    for (NSString* pair in pairs) {
        NSString* trimmedPair = [pair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray* parts        = [trimmedPair componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (parts.count == 2) {
            NSString* url     = parts[0];
            NSString* density = parts[1];
            [output addObject:[NSString stringWithFormat:@"%@ %@", [self proxyURLForImageURLString:url].absoluteString, density]];
        } else {
            [output addObject:pair];
        }
    }
    return [output componentsJoinedByString:@", "];
}

#pragma mark - BaseURL (for testing only)

- (NSURL*)baseURL {
    return [self.webServer.serverURL URLByAppendingPathComponent:self.secret];
}

@end
