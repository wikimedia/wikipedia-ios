#import <XCTest/XCTest.h>
#import "WMFMTLModel.h"
#import "WMFLegacySerializer.h"
#import "WMFFeedDayResponse.h"
#import "WMFFeedOnThisDayEvent.h"

@interface WMFMTLModelSerializationTests : XCTestCase

@end

@implementation WMFMTLModelSerializationTests

#pragma mark - Language Variant Propagation Testing

// Note, this also implicitly tests the subelement types WMFFeedArticlePreview, WMFFeedTopReadResponse, WMFFeedTopReadArticlePreview, WMFFeedImage, WMFFeedNewsStory
- (void)testFeedDayResponseLanguageVariantPropagation {
    NSString *fixtureName = @"FeedDayResponse-en";
    NSDictionary *resultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName];
    NSString *languageVariantCode = @"zh-hans";
    
    NSError *mantleError = nil;
    WMFFeedDayResponse *responseObject = [MTLJSONAdapter modelOfClass:[WMFFeedDayResponse class] fromJSONDictionary:resultJSON languageVariantCode: languageVariantCode error:&mantleError];
    XCTAssertNil(mantleError);
    
    NSArray<NSString *> *keyPaths = @[
        @"featuredArticle.thumbnailURL",
        @"featuredArticle.articleURL",
        @"topRead.articlePreviews.thumbnailURL",
        @"topRead.articlePreviews.articleURL",
        @"pictureOfTheDay.imageThumbURL",
        @"pictureOfTheDay.imageURL",
        @"newsStories.featuredArticlePreview.thumbnailURL",
        @"newsStories.featuredArticlePreview.articleURL",
        @"newsStories.articlePreviews.thumbnailURL",
        @"newsStories.articlePreviews.articleURL"
    ];
    
    [self assertKeyPaths:keyPaths ofObject:responseObject resolvesToURLWithLanguageVariantCode:languageVariantCode];
    
    // Test propagation and comparison of nil value
    NSString *nilLanguageVariantCode = nil;
    [responseObject propagateLanguageVariantCode:nilLanguageVariantCode];
    [self assertKeyPaths:keyPaths ofObject:responseObject resolvesToURLWithLanguageVariantCode:nilLanguageVariantCode];
    
}

// Note, this also implicitly tests the subelement type WMFFeedArticlePreview
- (void)testFeedOnThisDayEventLanguageVariantPropagation {
    NSString *fixtureName = @"FeedOnThisDay-en";
    NSDictionary *resultJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureName];
    NSString *languageVariantCode = @"zh-hans";
    
    NSError *mantleError = nil;
    NSArray<WMFFeedOnThisDayEvent *> *events = [WMFLegacySerializer modelsOfClass:[WMFFeedOnThisDayEvent class] fromArrayForKeyPath:@"events" inJSONDictionary:resultJSON languageVariantCode: languageVariantCode error:&mantleError];
    XCTAssertNil(mantleError);
    
    NSArray<NSString *> *keyPaths = @[
        @"articlePreviews.thumbnailURL",
        @"articlePreviews.articleURL"
    ];
    
    for (WMFFeedOnThisDayEvent *responseObject in events) {
        [self assertKeyPaths:keyPaths ofObject:responseObject resolvesToURLWithLanguageVariantCode:languageVariantCode];
    }
    
    // Test propagation and comparison of nil value
    NSString *nilLanguageVariantCode = nil;
    for (WMFFeedOnThisDayEvent *responseObject in events) {
        [responseObject propagateLanguageVariantCode:nilLanguageVariantCode];
        [self assertKeyPaths:keyPaths ofObject:responseObject resolvesToURLWithLanguageVariantCode:nilLanguageVariantCode];
    }
}

#pragma mark - Language Variant Propagation Testing Support Methods

- (void)assertKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object resolvesToURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    for (NSString *keyPath in keyPaths) {
        NSArray *keyPathElements = [keyPath componentsSeparatedByString:@"."];
        XCTAssertTrue(keyPathElements.count > 0, @"Keypath must not be empty");
        [self assertKeyPathElements:keyPathElements ofObject:object fromOriginalKeyPath:keyPath resolvesToURLWithLanguageVariantCode:languageVariantCode];
    }
}

- (void)assertKeyPathElements:(NSArray<NSString *> *)keyPathElements ofObject:(id)object fromOriginalKeyPath:(NSString *)originalKeyPath resolvesToURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    XCTAssert((keyPathElements.count > 0));
    
    id value = [object valueForKey:keyPathElements[0]];
    if (!value) { return; } // if value is nil, propagation not applicable

    // Last path element means we should have a URL, assert that is true
    if (keyPathElements.count == 1) {
        [self assertValueIsURL:value atKeypath:originalKeyPath withLanguageVariantCode:languageVariantCode];
    } else {
        // Drop first element, since count > 0 and we've already checked if count == 1, count must be 2 or more
        NSArray<NSString *> *reducedKeyPathElements = [keyPathElements subarrayWithRange:NSMakeRange(1, keyPathElements.count - 1)];
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *elements = (NSArray *)value;
            for (id element in elements) {
                [self assertKeyPathElements:reducedKeyPathElements ofObject:element fromOriginalKeyPath:originalKeyPath resolvesToURLWithLanguageVariantCode:languageVariantCode];
            }
        } else {
            [self assertKeyPathElements:reducedKeyPathElements ofObject:value fromOriginalKeyPath:originalKeyPath resolvesToURLWithLanguageVariantCode:languageVariantCode];
        }
    }
}

- (void)assertValueIsURL:(id)value atKeypath:(NSString *)keypath withLanguageVariantCode:(NSString *)languageVariantCode {
    if (!value) { return; } // if value is nil, propagation not applicable
    BOOL isURL = [value isKindOfClass:[NSURL class]];
    XCTAssertTrue(isURL, @"Object for keypath '%@' of type %@ is not of type NSURL", keypath, NSStringFromClass([value class]));
    if (isURL) {
        NSURL *url = (NSURL *)value;
        XCTAssertEqualObjects(url.wmf_languageVariantCode, languageVariantCode);
    }
}

@end
