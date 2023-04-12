#import <XCTest/XCTest.h>

@interface CodeFileLocationTests : XCTestCase

@end

@implementation CodeFileLocationTests

- (void)setUp {
    [super setUp];
}

- (void)test_code_files_are_not_in_root_folder {
    // There are project and testing "code" folders.
    // This test ensures we keep code files out of the project's root directory.
    NSArray *extensionsToKeepOutOfRoot =
        @[
            @"h",
            @"m",
            @"c",
            @"mm",
            @"cpp",
            @"swift",
            @"xib",
            @"json",
            @"storyboard",
            @"plist",
            @"xcdatamodeld"
        ];

    NSPredicate *extensionsPredicate =
        [NSPredicate predicateWithFormat:@"pathExtension IN %@", extensionsToKeepOutOfRoot];

    NSString *sourceRoot = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"SourceRoot"];
    NSArray *filesWhichShouldNotBeInRoot =
        [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourceRoot error:nil] filteredArrayUsingPredicate:extensionsPredicate];

    XCTAssertEqual(filesWhichShouldNotBeInRoot.count, 0);
}

- (void)tearDown {
    [super tearDown];
}

@end
