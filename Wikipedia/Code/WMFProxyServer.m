#import "WMFProxyServer.h"

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerFunctions.h"
#import "NSURL+WMFExtras.h"
#import "NSString+WMFExtras.h"
#import "NSURL+WMFProxyServer.h"
#import "Wikipedia-swift.h"
#import "WMFImageTag.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "NSString+WMFHTMLParsing.h"

@interface WMFProxyServerResponse : NSObject
@property (nonatomic, copy) NSData* data;
@property (nonatomic, copy) NSString* contentType;
@property (nonatomic, readonly) GCDWebServerResponse* GCDWebServerResponse;
+ (WMFProxyServerResponse*)responseWithData:(NSData*)data contentType:(NSString*)contentType;
@end

@interface WMFProxyServer () <GCDWebServerDelegate>
@property (nonatomic, strong) NSMutableDictionary* responsesByPath;
@property (nonatomic, strong) GCDWebServer* webServer;
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
    self.responsesByPath = [NSMutableDictionary dictionaryWithCapacity:10];

    NSString* secret = [[NSUUID UUID] UUIDString];
    self.secret    = secret;
    
    NSURL* documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* assetsURL    = [documentsURL URLByAppendingPathComponent:@"assets"];
    self.hostedFolderPath = assetsURL.path;
    
    self.webServer = [[GCDWebServer alloc] init];
    
    self.webServer.delegate = self;
    
    [self.webServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] asyncProcessBlock:self.defaultHandler];
    
    [self start];
}

- (void)start {
    if (self.isRunning) {
        return;
    }
    
    NSDictionary* options = @{GCDWebServerOption_BindToLocalhost: @(YES), //only accept requests from localhost
                              GCDWebServerOption_Port: @(0)};// allow the OS to pick a random port
    
    NSError* serverStartError = nil;
    NSUInteger attempts = 0;
    NSUInteger attemptLimit = 5;
    BOOL didStartServer = false;
    
    while (!didStartServer && attempts < attemptLimit) {
        didStartServer = [self.webServer startWithOptions:options error:&serverStartError];
        if (!didStartServer) {
            DDLogError(@"Error starting proxy: %@", serverStartError);
            attempts++;
            if (attempts == attemptLimit) {
                DDLogError(@"Unable to start the proxy.");
#if DEBUG
                [[WMFAlertManager sharedInstance] showEmailFeedbackAlertViewWithError:serverStartError];
#else
                NSString *errorMessage = localizedStringForKeyFallingBackOnEnglish(@"article-unable-to-load-article");
                [[WMFAlertManager sharedInstance] showErrorAlertWithMessage:errorMessage sticky:YES dismissPreviousAlerts:YES tapCallBack:^{
                    [self start];
                }];
#endif
                
            }
        }
    }
}

#pragma mark - GCDWebServer

- (void)webServerDidStop:(GCDWebServer *)server {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) { //restart the server if it fails for some reason other than being in the background
        [self start];
    }
}

- (BOOL)isRunning {
    return self.webServer.isRunning;
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

               if ([baseComponent isEqualToString:WMFProxyFileBasePath]) {
                   NSArray* localPathComponents = [components subarrayWithRange:NSMakeRange(3, components.count - 3)];
                   NSString* relativePath       = [NSString pathWithComponents:localPathComponents];
                   [self handleFileRequestForRelativePath:relativePath completionBlock:completionBlock];
               } else if ([baseComponent isEqualToString:WMFProxyImageBasePath]) {
                   NSString* originalSrc = request.query[WMFProxyImageOriginalSrcKey];
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
    WMFProxyServerResponse* response = [self responseForPath:relativePath];
    if (response == nil) {
        NSString* fullPath      = [self.hostedFolderPath stringByAppendingPathComponent:relativePath];
        NSURL* localFileURL     = [NSURL fileURLWithPath:fullPath];
        NSNumber* isRegularFile = nil;
        NSError* fileReadError  = nil;
        if ([localFileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&fileReadError] && [isRegularFile boolValue]) {
            NSData* data          = [NSData dataWithContentsOfURL:localFileURL];
            NSString* contentType = GCDWebServerGetMimeTypeForExtension([localFileURL pathExtension]);
            response                           = [WMFProxyServerResponse responseWithData:data contentType:contentType];
            self.responsesByPath[relativePath] = response;
            completionBlock(response.GCDWebServerResponse);
        } else {
            completionBlock([GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"404"]);
        }
    } else {
        completionBlock(response.GCDWebServerResponse);
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
    NSURL *serverURL = self.webServer.serverURL;
    if (relativeFilePath == nil || secret == nil || serverURL == nil) {
        return nil;
    }

    NSURLComponents* components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path     = [NSString pathWithComponents:@[@"/", secret, WMFProxyFileBasePath, relativeFilePath]];
    components.fragment = fragment;
    return components.URL;
}

- (NSString*)localFilePathForRelativeFilePath:(NSString*)relativeFilePath {
    return [self.hostedFolderPath stringByAppendingPathComponent:relativeFilePath];
}

#pragma - Image Proxy URLs

- (NSURL*)proxyURLForImageURLString:(NSString*)imageURLString {
    NSString* secret = self.secret;
    NSURL *serverURL = self.webServer.serverURL;
    if (secret == nil || serverURL == nil) {
        return nil;
    }
    
    NSURLComponents* components = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    components.path = [NSString pathWithComponents:@[@"/", secret, WMFProxyImageBasePath]];
    NSURLQueryItem* queryItem = [NSURLQueryItem queryItemWithName:@"originalSrc" value:imageURLString];
    if (queryItem) {
        components.queryItems = @[queryItem];
    }
    return components.URL;
}

- (NSString*)stringByReplacingImageURLsWithProxyURLsInHTMLString:(NSString*)HTMLString withBaseURL:(NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth {

    
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
    [newHTMLString appendString:[HTMLString substringWithRange:NSMakeRange(location, HTMLString.length - location)]];

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
    self.responsesByPath[path] = [WMFProxyServerResponse responseWithData:data contentType:contentType];
}

- (WMFProxyServerResponse *)responseForPath:(NSString *)path {
    if (path == nil) {
        return nil;
    }
    return self.responsesByPath[path];
}

#pragma mark - BaseURL (for testing only)

- (NSURL*)baseURL {
    return [self.webServer.serverURL URLByAppendingPathComponent:self.secret];
}

@end

@implementation WMFProxyServerResponse
+ (WMFProxyServerResponse*)responseWithData:(NSData*)data contentType:(NSString*)contentType {
    WMFProxyServerResponse* response = [[WMFProxyServerResponse alloc] init];
    response.data        = data;
    response.contentType = contentType;
    return response;
}

- (GCDWebServerResponse*)GCDWebServerResponse {
    return [GCDWebServerDataResponse responseWithData:self.data contentType:self.contentType];
}

@end
