//
//  OldDataSchemaMigratorTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#import "OldDataSchemaMigrator_Private.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "SchemaConverter.h"
#import "MWKProtectionStatus.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "NSManagedObjectContext+WMFTempContext.h"
#import "Article+ConvenienceAccessors.h"
#import "WikipediaAppUtils.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "NSManagedObject+WMFModelFactory.h"

@interface OldDataSchemaMigratorTests : XCTestCase
@property OldDataSchemaMigrator* migrator;
@property SchemaConverter* converter;
@property MWKDataStore* dataStore;
@property NSManagedObjectContext* tmpContext;
@end

@implementation OldDataSchemaMigratorTests

- (void)setUp {
    [super setUp];
    self.migrator          = [[OldDataSchemaMigrator alloc] init];
    self.dataStore         = [MWKDataStore temporaryDataStore];
    self.converter         = [[SchemaConverter alloc] initWithDataStore:self.dataStore];
    self.migrator.delegate = self.converter;

    // objects must be inserted into a MOC in order for (inverse) relationships to be maintained automatically
    self.tmpContext = [NSManagedObjectContext wmf_tempContext];
}

- (void)tearDown {
    [super tearDown];
    NSError* tmpDataStoreRemovalErr = [self.dataStore removeFolderAtBasePath];
    NSParameterAssert(!tmpDataStoreRemovalErr);
}

- (void)testArticleWithThumbnail {
    [self verifyMigrationOfArticle:[self createOldArticleWithSections:5 imagesPerSection:5]];
}

- (void)testArticleWithoutThumbnail {
    Article* oldArticle = [self createOldArticleWithSections:5 imagesPerSection:5];
    oldArticle.thumbnailImage = nil;
    [self verifyMigrationOfArticle:oldArticle];
}

- (void)testArticleWithoutSections {
    Article* oldArticle = [self createOldArticleWithSections:0 imagesPerSection:0];
    NSParameterAssert(oldArticle.section == nil || oldArticle.section.count == 0);
    [self verifyMigrationOfArticle:oldArticle];
}

- (void)testArticleWithoutImages {
    Article* oldArticle = [self createOldArticleWithSections:0 imagesPerSection:0];
    oldArticle.thumbnailImage = nil;
    [self verifyMigrationOfArticle:oldArticle];
}

#pragma mark - Test Utils

- (void)verifyMigrationOfArticle:(Article*)oldArticle {
    [self.migrator migrateArticle:oldArticle];

    MWKTitle* migratedArticleTitle = [self.migrator migrateArticleTitle:oldArticle];

    [self verifySiteAndTitleForOldArticle:oldArticle];

    MWKArticle* migratedArticle = [self.dataStore articleWithTitle:migratedArticleTitle];

    [self verifyArticleProperties:migratedArticle correspondsToOldArticle:oldArticle];

    [self verifyArticleSections:migratedArticle correspondToOldArticle:oldArticle];

    [self verifyArticleThumbnail:migratedArticle matchesOldArticle:oldArticle];

    [self verifyArticleSectionAndLeadImages:migratedArticle correspondsToOldArticle:oldArticle];
}

- (void)verifySiteAndTitleForOldArticle:(Article*)oldArticle {
    MWKSite* migratedSite          = [self.migrator migrateArticleSite:oldArticle];
    MWKTitle* migratedArticleTitle = [self.migrator migrateArticleTitle:oldArticle];

    assertThat(migratedSite, is(notNilValue()));
    assertThat(migratedSite.domain, is(@"wikipedia.org"));
    assertThat(migratedSite.language, is(oldArticle.domain));

    assertThat(migratedArticleTitle, is(notNilValue()));
    assertThat(migratedArticleTitle.text, is(oldArticle.title));
    assertThat(migratedArticleTitle.site, is(migratedSite));
}

- (void)verifyArticleProperties:(MWKArticle*)migratedArticle correspondsToOldArticle:(Article*)oldArticle {
    MWKSite* migratedSite          = [self.migrator migrateArticleSite:oldArticle];
    MWKTitle* migratedArticleTitle = [self.migrator migrateArticleTitle:oldArticle];

    assertThat(migratedArticle, is(notNilValue()));

    // article identification
    assertThat(migratedArticle.title, is(migratedArticleTitle));
    assertThat(migratedArticle.site, is(migratedSite));
    assertThat(@(migratedArticle.articleId), is(oldArticle.articleId));
    assertThat(migratedArticle.displaytitle, is(oldArticle.displayTitle));

    // article modification
    assertThat(migratedArticle.lastmodified, is(oldArticle.lastmodified));
    assertThat(migratedArticle.lastmodifiedby, is(notNilValue()));
    assertThat(migratedArticle.lastmodifiedby.name, is(oldArticle.lastmodifiedby));
    assertThat(migratedArticle.lastmodifiedby.gender, is(@"unknown"));

    // article misc
    assertThat(migratedArticle.redirected, is([migratedSite titleWithString:oldArticle.redirected]));
    assertThat(@(migratedArticle.languagecount), is(oldArticle.languagecount));
    assertThat([migratedArticle.protection protectedActions], is(equalTo(@[@"edit"])));
    // !!!: is this correct?
    assertThat(@(migratedArticle.editable), isFalse());
}

- (void)verifyArticleSections:(MWKArticle*)migratedArticle correspondToOldArticle:(Article*)oldArticle {
    MWKSite* migratedSite       = [self.migrator migrateArticleSite:oldArticle];
    NSArray* oldArticleSections = [oldArticle sectionsBySectionId];

    assertThat(@(migratedArticle.sections.count), is(equalToInt(oldArticleSections.count)));
    [oldArticleSections enumerateObjectsUsingBlock:^(Section* oldSection, NSUInteger idx, BOOL* stop) {
        MWKSection* migratedSection = migratedArticle.sections[idx];
        assertThat(@(migratedSection.sectionId), is(oldSection.sectionId));
        assertThat(migratedSection.toclevel, is(oldSection.tocLevel));
        assertThat(migratedSection.level, is(equalToInt(oldSection.level.intValue)));
        assertThat(migratedSection.anchor, is(oldSection.anchor));
        assertThat(migratedSection.fromtitle,
                   is([MWKTitle titleWithString:oldSection.fromTitle site:migratedSite]));
        assertThat(migratedSection.line, is(oldSection.title));
        assertThat(migratedSection.text, is(oldSection.html));

        assertThat(@(migratedSection.images.count), is(equalToUnsignedInt(oldSection.sectionImage.count)));
        for (SectionImage* sectionImage in oldSection.sectionImage) {
            MWKImage* migratedSectionImage = [migratedSection.images imageWithURL:sectionImage.image.sourceUrl];
            assertThat(migratedSectionImage, is(notNilValue()));
            assertThat([migratedSectionImage asNSData], is(sectionImage.image.imageData.data));
        }
    }];
}

- (void)verifyArticleThumbnail:(MWKArticle*)migratedArticle matchesOldArticle:(Article*)oldArticle {
    if (oldArticle.thumbnailImage) {
        NSString* firstImageURL = [migratedArticle.images imageURLAtIndex:0];
        assertThat(migratedArticle.thumbnailURL, is(oldArticle.thumbnailImage.sourceUrl));
        assertThat(firstImageURL, is(oldArticle.thumbnailImage.sourceUrl));
        assertThat([[migratedArticle imageWithURL:firstImageURL] asNSData],
                   is(oldArticle.thumbnailImage.imageData.data));
    } else {
        assertThat(migratedArticle.thumbnailURL, is(nilValue()));
    }
}

- (void)verifyArticleSectionAndLeadImages:(MWKArticle*)migratedArticle correspondsToOldArticle:(Article*)oldArticle {
    NSArray* oldArticleImages = [oldArticle allImages];
    NSUInteger const thumbnailModifier = oldArticle.thumbnailImage ? 1 : 0;
    assertThat(@(migratedArticle.images.count), is(equalToInt(oldArticleImages.count + thumbnailModifier)));
    for (NSUInteger i = thumbnailModifier; i < oldArticleImages.count; i++) {
        Image* oldImage         = oldArticleImages[i];
        MWKImage* migratedImage = migratedArticle.images[i + thumbnailModifier];
        assertThat(migratedImage.sourceURL, is(oldImage.sourceUrl));
        assertThat([migratedImage asNSData], is(oldImage.imageData.data));
    }

    // article lead image
    if (oldArticleImages.count) {
        assertThat(migratedArticle.imageURL, is([oldArticleImages[0] sourceUrl]));
    } else if (oldArticle.thumbnailImage) {
        assertThat(migratedArticle.imageURL, is(oldArticle.thumbnailImage.sourceUrl));
    } else {
        assertThat(migratedArticle.imageURL, is(nilValue()));
    }
}

- (Article*)createOldArticleWithSections:(NSUInteger)numSections imagesPerSection:(NSUInteger)numImages {
    Article* oldArticle = [Article wmf_newWithContext:self.tmpContext];
    oldArticle.redirected = @"redirected title";
    oldArticle.domain     = @"en";
    // need to use date formatter when creating test dates, otherwise comparison will fail (!= miliseconds)
    oldArticle.lastmodified     = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:@"2015-01-01T12:00:00Z"];
    oldArticle.lastmodifiedby   = @"lastmodifiedby.name";
    oldArticle.articleId        = @1;
    oldArticle.languagecount    = @2;
    oldArticle.displayTitle     = @"Display title";
    oldArticle.title            = @"Title";
    oldArticle.protectionStatus = @"protected";
    oldArticle.editable         = @NO;
    oldArticle.thumbnailImage   = ^Image* {
        Image* image = [Image wmf_newWithContext:self.tmpContext];
        image.sourceUrl = MWKCreateImageURLWithPath(@"Article_thumb.jpg");
        image.imageData = ^ImageData* {
            ImageData* imageData = [ImageData wmf_newWithContext:self.tmpContext];
            imageData.imageData = image;
            imageData.data      = [image.sourceUrl dataUsingEncoding:NSUTF8StringEncoding];
            return imageData;
        } ();
        [image addArticleObject:oldArticle];
        return image;
    } ();
    oldArticle.section = ^NSSet* {
        NSMutableSet* sections = [NSMutableSet new];
        __block int s          = 0;
        NSString*(^ formatWithSectionNum)(NSString*) = ^(NSString* frmt) {
            return [NSString stringWithFormat:frmt, s];
        };
        for (; s < numSections; s++) {
            [sections addObject:^{
                Section* section = [Section wmf_newWithContext:self.tmpContext];
                section.tocLevel = @0;
                section.level = @"0";
                section.title = formatWithSectionNum(@"Section %d");
                section.fromTitle = formatWithSectionNum(@"Section %d fromTitle");
                section.anchor = formatWithSectionNum(@"anchor %d");
                section.sectionId = @(s);
                section.html = formatWithSectionNum(@"<p>Section %d source</p>");
                section.sectionImage = ^NSSet* {
                    NSMutableSet* images = [NSMutableSet new];
                    __block int i = 0;
                    NSString*(^ formatWithSectionAndImageNum)(NSString*) = ^NSString* (NSString* frmt) {
                        return [NSString stringWithFormat:frmt, s, i];
                    };
                    for (; i < numImages; i++) {
                        [images addObject:^SectionImage* {
                            SectionImage* sectionImage = [SectionImage wmf_newWithContext:self.tmpContext];
                            sectionImage.index = @(i);
                            sectionImage.image = ^Image* {
                                Image* image = [Image wmf_newWithContext:self.tmpContext];
                                image.sourceUrl =
                                    MWKCreateImageURLWithPath(formatWithSectionAndImageNum(@"Section_%d_%d.jpg"));
                                image.imageData = ^ImageData* {
                                    ImageData* imageData = [ImageData wmf_newWithContext:self.tmpContext];
                                    imageData.data = [image.sourceUrl dataUsingEncoding:NSUTF8StringEncoding];
                                    return imageData;
                                } ();
                                return image;
                            } ();
                            return sectionImage;
                        } ()];
                    }
                    return images;
                } ();
                return section;
            } ()];
        }
        return sections;
    } ();
    return oldArticle;
}

@end
