//
//  XCTestCase+MWKFixtures.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+MWKFixtures.h"
#import "XCTestCase+WMFBundleConvenience.h"
#import "MWKArticle.h"
#import "NSBundle+TestAssets.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "WMFRandomFileUtilities.h"

static MWKTitle* MWKTitleFromStringOrTitle(id titleOrString) {
    return [titleOrString isKindOfClass:[MWKTitle class]] ?
           (MWKTitle*)titleOrString
           : [MWKTitle titleWithString:titleOrString site:[MWKSite siteWithCurrentLocale]];
}

@implementation XCTestCase (MWKFixtures)

- (MWKArticle*)articleWithMobileViewJSONFixture:(NSString*)fixtureName
                                      withTitle:(id)titleOrString
                                      dataStore:(MWKDataStore*)dataStore {
    return [[MWKArticle alloc] initWithTitle:MWKTitleFromStringOrTitle(titleOrString)
                                   dataStore:dataStore
                                        dict:[[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName][@"mobileview"]];
}

- (MWKArticle*)completeArticleWithLegacyDataInFolder:(NSString*)folderName
                                           withTitle:(id)titleOrString
                                 insertIntoDataStore:(MWKDataStore*)dataStore {
    NSString* folderPath = [[[self wmf_bundle] resourcePath] stringByAppendingPathComponent:folderName];
    return [dataStore articleWithImportedDataFromFolderAtPath:folderPath
                                                        title:MWKTitleFromStringOrTitle(titleOrString)];
}

@end

@implementation MWKDataStore (Fixtures)

- (MWKArticle* __nonnull)articleWithImportedDataFromFolderAtPath:(NSString*)path title:(MWKTitle*)title {
    NSString* dest = [self pathForTitle:title];
    [[NSFileManager defaultManager] createDirectoryAtPath:[dest stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    NSError* error;
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:dest error:&error];
    NSAssert(!error, @"Failed to copy article from '%@'. %@", path, error);
    MWKArticle* article = [self existingArticleWithTitle:title];
    NSAssert(article, @"Failed to read article titled '%@' after importing data from '%@'", path, title);
    return article;
}

@end
