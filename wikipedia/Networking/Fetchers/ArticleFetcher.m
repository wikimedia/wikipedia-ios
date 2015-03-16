//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ArticleFetcher.h"
#import "WMFNetworkUtilities.h"
#import "Defines.h"
#import "QueuesSingleton.h"
#import "NSString+Extras.h"
#import "AFHTTPRequestOperationManager.h"
#import "SessionSingleton.h"
#import "ReadingActionFunnel.h"
#import "NSString+Extras.h"
#import "NSObject+Extras.h"
#import "MWNetworkActivityIndicatorManager.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <TFHpple.h>

@interface ArticleFetcher ()

// The Article object to be updated with the downloaded data.
@property (nonatomic, strong) MWKArticle* article;

@end

@implementation ArticleFetcher

- (instancetype)initAndFetchSectionsForArticle:(MWKArticle*)article
                                   withManager:(AFHTTPRequestOperationManager*)manager
                            thenNotifyDelegate:(id <FetchFinishedDelegate> )delegate {
    self = [super init];
    assert(article != nil);
    assert(manager != nil);
    assert(delegate != nil);
    if (self) {
        self.article               = article;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager:(AFHTTPRequestOperationManager*)manager {
    NSString* title     = self.article.title.prefixedText;
    NSString* subdomain = self.article.title.site.language;

    if (!self.article) {
        NSLog(@"NO ARTICLE OBJECT");
        return;
    }
    if (!self.fetchFinishedDelegate) {
        NSLog(@"NO DOWNLOAD DELEGATE");
        return;
    }
    if (!subdomain) {
        NSLog(@"NO DOMAIN");
        return;
    }
    if (!title) {
        NSLog(@"NO TITLE");
        return;
    }

    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:subdomain];

    // First retrieve lead section data, then get the remaining sections data.

    NSDictionary* params = [self getParamsForTitle:title];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    // Conditionally add an MCCMNC header.
    [self addMCCMNCHeaderToRequestSerializer:manager.requestSerializer ifAppropriateForURL:url];

    [manager GET:url.absoluteString parameters:params success:^(AFHTTPRequestOperation* operation, id responseObject) {
        __block NSData* localResponseObject = responseObject;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            //NSLog(@"JSON: %@", responseObject);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            // Convert the raw NSData response to a dictionary.
            NSDictionary* responseDictionary = [self dictionaryFromDataResponse:localResponseObject];

            // Clear any MCCMNC header - needed because manager is a singleton.
            [self removeMCCMNCHeaderFromRequestSerializer:manager.requestSerializer];

            //NSDictionary *leadSectionResults = [self prepareResultsFromResponse:responseObject forTitle:title];
            @try {
                [self.article importMobileViewJSON:responseDictionary[@"mobileview"]];
                [self.article save];
            }@catch (NSException* e) {
                NSLog(@"%@", e);
                NSError* err = [NSError errorWithDomain:@"ArticleFetcher" code:666 userInfo:@{ @"exception": e }];
                [self finishWithError:err
                          fetchedData:nil];
                return;
            }

            //[self applyResultsForLeadSection:leadSectionResults];
            for (int n = 0; n < [self.article.sections count]; n++) {
                (void)self.article.sections[n].images;             // hack
                [self createImageRecordsForSection:n];
            }

            [self associateThumbFromTempDirWithArticle];

            // Reminder: must reset "needsRefresh" to NO here! Otherwise saved articles
            // (which had been refreshed at least once) won't work if you're offline
            // because the system thinks a fresh is *still* needed and will try to load
            // from network rather than from cache.
            self.article.needsRefresh = NO;

            [self.article save];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishWithError:nil
                          fetchedData:nil];
            });
        });
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        NSLog(@"Error: %@", error);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Clear any MCCMNC header - needed because manager is a singleton.
        [self removeMCCMNCHeaderFromRequestSerializer:manager.requestSerializer];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSDictionary*)getParamsForTitle:(NSString*)title {
    NSMutableDictionary* params = @{
        @"format": @"json",
        @"action": @"mobileview",
        @"sectionprop": WMFJoinedPropertyParameters(@[
                                                        @"toclevel",
                                                        @"line",
                                                        @"anchor",
                                                        @"level",
                                                        @"number",
                                                        @"fromtitle",
                                                        @"index"]),
        @"noheadings": @"true",
        @"sections": @"all",
        @"page": title,
        @"thumbwidth": @(LEAD_IMAGE_WIDTH),
        @"prop": WMFJoinedPropertyParameters(@[
                                                 @"sections",
                                                 @"text",
                                                 @"lastmodified",
                                                 @"lastmodifiedby",
                                                 @"languagecount",
                                                 @"id",
                                                 @"protection",
                                                 @"editable",
                                                 @"displaytitle",
                                                 @"thumb",
                                                 @"description",
                                                 @"image"])
    }.mutableCopy;

    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        // !!!: (bgerstle Feb 4 2015) we're getting an "unrecognized parameter" warning for appInstallID
        ReadingActionFunnel* funnel = [[ReadingActionFunnel alloc] init];
        params[@"appInstallID"] = funnel.appInstallID;
    }

    return params;
}

// Add the MCC-MNC code asn HTTP (protocol) header once per session when user using cellular data connection.
// Logging will be done in its own file with specific fields. See the following URL for details.
// http://lists.wikimedia.org/pipermail/wikimedia-l/2014-April/071131.html

- (void)addMCCMNCHeaderToRequestSerializer:(AFHTTPRequestSerializer*)requestSerializer
                       ifAppropriateForURL:(NSURL*)url {
    /* MCC-MNC logging is only turned with an API hook */
    if (
        ![SessionSingleton sharedInstance].shouldSendUsageReports
        ||
        [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC
        ||
        ([url.host rangeOfString:@".m.wikipedia.org"].location == NSNotFound)
        ||
        ([url.relativePath rangeOfString:@"/w/api.php"].location == NSNotFound)
        ) {
        return;
    } else {
        CTCarrier* mno = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
        if (mno) {
            SCNetworkReachabilityRef reachabilityRef =
                SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
            SCNetworkReachabilityFlags reachabilityFlags;
            SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);

            // The following is a good functioning mask in practice for the case where
            // cellular is being used, with wifi not on / there are no known wifi APs.
            // When wifi is on with a known wifi AP connection, kSCNetworkReachabilityFlagsReachable
            // is present, but kSCNetworkReachabilityFlagsIsWWAN is not present.
            if (reachabilityFlags == (
                    kSCNetworkReachabilityFlagsIsWWAN
                    |
                    kSCNetworkReachabilityFlagsReachable
                    |
                    kSCNetworkReachabilityFlagsTransientConnection
                    )
                ) {
                // In iOS disentangling network MCC-MNC from SIM MCC-MNC not in API yet.
                // So let's use the same value for both parts of the field.
                NSString* mcc    = mno.mobileCountryCode ? mno.mobileCountryCode : @"000";
                NSString* mnc    = mno.mobileNetworkCode ? mno.mobileNetworkCode : @"000";
                NSString* mccMnc = [[NSString alloc] initWithFormat:@"%@-%@,%@-%@", mcc, mnc, mcc, mnc];

                [SessionSingleton sharedInstance].zeroConfigState.sentMCCMNC = true;

                [requestSerializer setValue:mccMnc forHTTPHeaderField:@"X-MCCMNC"];

                // NSLog(@"%@", mccMnc);
            }
        }
    }
}

- (void)removeMCCMNCHeaderFromRequestSerializer:(AFHTTPRequestSerializer*)requestSerializer {
    [requestSerializer setValue:nil forHTTPHeaderField:@"X-MCCMNC"];
}

- (void)createImageRecordsForSection:(int)sectionId {
    NSString* html = self.article.sections[sectionId].text;

    // Parse the section html extracting the image urls (in order)
    // See: http://www.raywenderlich.com/14172/how-to-parse-html-on-ios
    // for TFHpple details.

    // Call *after* article record created but before section html sent across bridge.

    // Reminder: don't do "context performBlockAndWait" here - createImageRecordsForHtmlOnContext gets
    // called in a loop which is encompassed by such a block already!

    if (html.length == 0) {
        return;
    }

    NSData* sectionHtmlData               = [html dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple* sectionParser                = [TFHpple hppleWithHTMLData:sectionHtmlData];
    NSString* imageLinkElementsXpathQuery = @"//a[@class='image']";
    // ^ the navbox exclusion prevents images from the hidden navbox table from appearing
    // in the last section's TOC cell.

    NSArray* imageLinks            = [sectionParser searchWithXPathQuery:imageLinkElementsXpathQuery];
    NSUInteger imageIndexInSection = 0;

    for (TFHppleElement* linkNode in imageLinks) {
        NSInteger imageNodeIndex = [linkNode.children indexOfObjectPassingTest:^BOOL (TFHppleElement* child, NSUInteger idx, BOOL* stop) {
            if ([child.tagName isEqualToString:@"img"]) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];
        NSParameterAssert(imageNodeIndex != NSNotFound);
        if (imageNodeIndex == NSNotFound) {
            // TODO: handle this error somehow, for now, go to the next linkNode
            continue;
        }
        TFHppleElement* imageNode = linkNode.children[imageNodeIndex];
        NSString* height          = imageNode.attributes[@"height"];
        NSString* width           = imageNode.attributes[@"width"];

        if (
            height.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.width
            ||
            width.integerValue < THUMBNAIL_MINIMUM_SIZE_TO_CACHE.height
            ) {
            //NSLog(@"SKIPPING - IMAGE TOO SMALL");
            continue;
        }

        NSString* src = imageNode.attributes[@"src"];
        int density   = 1;

        // This is a horrible hack to compensate for iOS 8 WebKit's srcset
        // handling and the way we currently handle image caching which
        // doesn't quite handle that right.
        //
        // WebKit on iOS 8 and later understands the new img 'srcset' attribute
        // which can provide alternate-resolution versions for different device
        // pixel ratios (and in theory some other size-based alternates, but we
        // don't use that stuff). MediaWiki/Wikipedia uses this to specify image
        // versions at 1.5x and 2x density levels, which the browser should use
        // as appropriate in preference to the 'src' URL which is assumed to be
        // at 1x density.
        //
        // On iOS 7 and earlier, or on non-Retina devices on iOS 8, the 1x image
        // URL from the 'src' attribute is still used as-is.
        //
        // By making sure we pick the same version that WebKit will pick up later,
        // here we ensure that the correct entries will be cached.
        //
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            if ([UIScreen mainScreen].scale > 1.0f) {
                NSString* srcSet = imageNode.attributes[@"srcset"];
                for (NSString* subSrc in[srcSet componentsSeparatedByString:@","]) {
                    NSString* trimmed = [subSrc stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
                    NSArray* parts    = [trimmed componentsSeparatedByString:@" "];
                    if (parts.count == 2 && [parts[1] isEqualToString:@"2x"]) {
                        // Quick hack to shortcut relevant syntax :P
                        src     = parts[0];
                        density = 2;
                        break;
                    }
                }
            }
        }

        MWKImage* image = [self.article importImageURL:src sectionId:sectionId];
        [image save];

        imageIndexInSection++;
    }

    // Reminder: don't do "context save" here - createImageRecordsForHtmlOnContext gets
    // called in a loop after which save is called. This method *only* creates - the caller
    // is responsible for saving.
}

- (void)associateThumbFromTempDirWithArticle {
    BOOL foundThumbInTempDir = NO;

    // Map which search and nearby populates with title/thumb url mappings.
    NSDictionary* map = [SessionSingleton sharedInstance].titleToTempDirThumbURLMap;
    NSString* title   = self.article.title.prefixedText;
    if (title) {
        NSString* thumbURL = map[title];
        if (thumbURL) {
            // Associate Search/Nearby thumb url with article.thumbnailURL.
            if (thumbURL) {
                self.article.thumbnailURL = thumbURL;
            }


            NSString* cacheFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
                                        firstObject]
                                       stringByAppendingPathComponent:thumbURL.lastPathComponent];
            BOOL isDirectory      = NO;
            BOOL cachedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath
                                                                         isDirectory:&isDirectory];
            if (cachedFileExists) {
                NSError* error = nil;
                NSData* data   = [NSData dataWithContentsOfFile:cacheFilePath options:0 error:&error];
                if (!error) {
                    // Copy Search/Nearby thumb binary to core data store so it doesn't have to be re-downloaded.
                    MWKImage* image = [self.article importImageURL:thumbURL sectionId:kMWKArticleSectionNone];
                    [self.article importImageData:data image:image];
                    foundThumbInTempDir = YES;
                }
            }
        }
    }
    if (!foundThumbInTempDir) {
        MWKImageList* images = self.article.images;
        // If no image found in temp dir, use first article image.
        if (images.count > 0) {
            MWKImage* image = images[0];
            self.article.thumbnailURL = image.sourceURL;
        } else {
            // If still no image, use article image if there is one.
            if (self.article.imageURL) {
                self.article.thumbnailURL = self.article.imageURL;
            }
        }
    }
}

@end
