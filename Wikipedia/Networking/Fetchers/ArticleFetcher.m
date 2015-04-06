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
#import "WMFArticleParsing.h"

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

            @try {
                [self.article importMobileViewJSON:responseDictionary[@"mobileview"]];
                [self.article save];
            }@catch (NSException* e) {
                NSLog(@"%@", e);
                NSError* err = [NSError errorWithDomain:@"ArticleFetcher" code:666 userInfo:@{ @"exception": e }];
                [self finishWithError:err fetchedData:nil];
                return;
            }

            for (int section = 0; section < [self.article.sections count]; section++) {
                (void)self.article.sections[section].images;             // hack
                WMFInjectArticleWithImagesFromSection(self.article, self.article.sections[section].text, section);
            }

            [self associateThumbFromTempDirWithArticle];

            // Reminder: must reset "needsRefresh" to NO here! Otherwise saved articles
            // (which had been refreshed at least once) won't work if you're offline
            // because the system thinks a fresh is *still* needed and will try to load
            // from network rather than from cache.
            self.article.needsRefresh = NO;

            // Update article and section image data.
            // Reminder: don't recall article save here as it expensively re-writes all section html.
            [self.article saveWithoutSavingSectionText];

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
