#import <XCTest/XCTest.h>
#import "FBSnapshotTestCase+WMFConvenience.h"
#import "UIView+VisualTestSizingUtils.h"
#import "Wikipedia-Swift.h"
#import <Nocilla/Nocilla.h>
#import "XCTestCase+PromiseKit.h"
#import "NSUserDefaults+WMFBatchRecordMode.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFSaveButtonController.h"

@interface WMFArticlePreviewCellVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) WMFArticlePreviewTableViewCell *cell;
@property (nonatomic, strong) MWKDataStore *dataStore;

@end

@implementation WMFArticlePreviewCellVisualTests

- (void)setUp {
    [super setUp];

    self.deviceAgnostic = YES;
    self.recordMode = [[NSUserDefaults wmf_userDefaults] wmf_visualTestBatchRecordMode];

    self.cell = [WMFArticlePreviewTableViewCell wmf_viewFromClassNib];

    // Add border around save button to ensure adequate hit area
    UIControl *saveButton = self.cell.saveButtonController.control;
    saveButton.borderColor = [UIColor redColor];
    saveButton.borderWidth = 2.f;

    self.dataStore = [MWKDataStore temporaryDataStore];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [super tearDown];
    [self.dataStore removeFolderAtBasePath];
    [[LSNocilla sharedInstance] stop];
    [[WMFImageController sharedInstance] clearMemoryCache];
    [[WMFImageController sharedInstance] deleteAllImages];
}

- (void)testLayoutWithShortExtractAndImage {
    [self configureCellWithTitleText:self.shortTitleText
                         description:self.shortDescription
                             extract:self.shortExtract
                            imageURL:self.imageURL];
    WMFSnapshotVerifyViewForOSAndWritingDirection(self.cell);
}

- (void)testLayoutWithShortExtractWithoutImage {
    [self configureCellWithTitleText:self.shortTitleText
                         description:self.shortDescription
                             extract:self.shortExtract
                            imageURL:nil];
    FBSnapshotVerifyViewWithOptions(self.cell,
                                    [[UIApplication sharedApplication] wmf_systemVersionAndWritingDirection],
                                    FBSnapshotTestCaseDefaultSuffixes(),
                                    0.1);
}

- (void)testLayoutWithLongExtractAndImage {
    [self configureCellWithTitleText:self.shortTitleText
                         description:self.shortDescription
                             extract:self.longExtract
                            imageURL:self.imageURL];
    WMFSnapshotVerifyViewForOSAndWritingDirection(self.cell);
}

- (void)testLayoutWithLongExtractWithoutImage {
    [self configureCellWithTitleText:self.shortTitleText
                         description:self.shortDescription
                             extract:self.longExtract
                            imageURL:nil];
    FBSnapshotVerifyViewWithOptions(self.cell,
                                    [[UIApplication sharedApplication] wmf_systemVersionAndWritingDirection],
                                    FBSnapshotTestCaseDefaultSuffixes(),
                                    0.1);
}

#pragma mark - Utils

- (void)configureCellWithTitleText:(NSString *)titleText
                       description:(NSString *)description
                           extract:(NSString *)extract
                          imageURL:(NSURL *)imageURL {
    NSURL *url = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:titleText];

    [self.cell setSaveableURL:url savedPageList:self.dataStore.savedPageList];

    [self.cell setDescriptionText:description];

    [self.cell setSnippetText:extract];

    if (imageURL) {
        stubRequest(@"GET", imageURL.absoluteString)
            .andReturn(200)
            .withBody([[self wmf_bundle] wmf_dataFromContentsOfFile:@"golden-gate" ofType:@".jpg"]);

        XCTestExpectation *expectation = [self expectationWithDescription:@"waiting for image set"];
        @weakify(self)
            [self.cell setImageURL:imageURL
                failure:^(NSError *error) {
                    @strongify(self)
                        XCTFail(@"failed to set image: %@", error.description);
                    [expectation fulfill];
                }
                success:^{
                    @strongify(self)
                        XCTAssert(true);
                    [expectation fulfill];
                }];

        WaitForExpectationsWithTimeout(10);
    } else {
        [self.cell setImageURL:nil];
    }

    [self.cell wmf_sizeToFitWindowWidth];
}

- (NSString *)shortTitleText {
    return @"Short title";
}

- (NSString *)shortDescription {
    return @"Short description.";
}

- (NSString *)shortExtract {
    return @"Short extract.";
}

- (NSString *)longExtract {
    NSMutableString *longExtract = [NSMutableString stringWithString:@"This extract is "];
    for (int i = 0; i < 20; i++) {
        [longExtract appendString:@"really "];
    }
    [longExtract appendString:@"long"];
    return longExtract;
}

- (NSURL *)imageURL {
    return [NSURL URLWithString:@"https://upload.wikimedia.org/Foo.jpg"];
}

@end
