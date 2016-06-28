#import <XCTest/XCTest.h>
#import "MWKTestCase.h"
#import "WMFImageTagParser.h"
#import <OCHamcrest/OCHamcrest.h>
#import <BlocksKit/BlocksKit.h>

@interface WMFImageTagParserTests : MWKTestCase

@property(nonatomic, strong)WMFImageTagParser* parser;

@end

@implementation WMFImageTagParserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.parser = [[WMFImageTagParser alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.parser = nil;
    [super tearDown];
}

- (void)testObamaArticleGalleryImageListExtractionAtTargetWidth1024 {
    
    NSArray* parsedObamaGalleryURLS = [self.parser parseImageURLsFromHTMLString:[self allObamaHTML] targetWidth:1024];
    
    NSArray *expectedObamaGalleryURLs =
    [@[
       @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/1024px-President_Barack_Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/1024px-Barack_Obama_signature.svg.png",
       @"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/b/b6/Obamamiltondavis1.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/1024px-2004_Illinois_Senate_results.svg.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/1024px-BarackObamaportrait.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/7/79/Lugar-Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/1024px-Flickr_Obama_Springfield_01.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/1024px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/1024px-Obama_cabinet_meeting_2009-11.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/1024px-US_Employment_Statistics.svg.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/1024px-Obama-venice-la.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/f/f5/Obama_signs_health_care-20100323.jpg",
       @"//upload.wikimedia.org/wikipedia/en/7/79/PPACA_Premium_Chart.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/1024px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/4/42/Barack_Obama_at_Cairo_University_cropped.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/1024px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/1024px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/1024px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/1024px-Official_portrait_of_Barack_Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/9/97/Barack_Obama_hangout.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/1024px-G8_leaders_watching_football.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/1024px-Obama_family_portrait_in_the_Green_Room.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/1024px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/1024px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/1024px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/1024px-Seal_of_the_President_of_the_United_States.svg.png"
       ] bk_map:^NSURL*(NSString* stringURL){
           return [NSURL URLWithString:stringURL];
       }];

//    XCTAssertEqualObjects(parsedObamaGalleryURLS, expectedObamaGalleryURLs, @"ASDAFDS");
    
    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testObamaArticleGalleryImageListExtractionAtTargetWidth160 {
    
    NSArray* parsedObamaGalleryURLS = [self.parser parseImageURLsFromHTMLString:[self allObamaHTML] targetWidth:160];
    
    NSArray *expectedObamaGalleryURLs =
    [@[
       @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/160px-President_Barack_Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/160px-Barack_Obama_signature.svg.png",
       @"//upload.wikimedia.org/wikipedia/en/thumb/3/33/Ann_Dunham_with_father_and_children.jpg/160px-Ann_Dunham_with_father_and_children.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Obamamiltondavis1.jpg/160px-Obamamiltondavis1.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/160px-2004_Illinois_Senate_results.svg.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/160px-BarackObamaportrait.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/7/79/Lugar-Obama.jpg/160px-Lugar-Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/160px-Flickr_Obama_Springfield_01.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg/160px-President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg/160px-P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/160px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg/160px-Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/160px-Obama_cabinet_meeting_2009-11.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png/160px-U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/160px-US_Employment_Statistics.svg.png",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/160px-Obama-venice-la.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Obama_signs_health_care-20100323.jpg/160px-Obama_signs_health_care-20100323.jpg",
       @"//upload.wikimedia.org/wikipedia/en/thumb/7/79/PPACA_Premium_Chart.jpg/160px-PPACA_Premium_Chart.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/160px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/160px-Barack_Obama_at_Cairo_University_cropped.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/160px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/160px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/160px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/160px-Official_portrait_of_Barack_Obama.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/9/97/Barack_Obama_hangout.jpg/160px-Barack_Obama_hangout.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/160px-G8_leaders_watching_football.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/160px-Obama_family_portrait_in_the_Green_Room.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/160px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/160px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/160px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
       @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/160px-Seal_of_the_President_of_the_United_States.svg.png"
       ] bk_map:^NSURL*(NSString* stringURL){
           return [NSURL URLWithString:stringURL];
       }];
    
    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testParsingObamaHTMLPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
        NSArray* parsedObamaGalleryURLS = [self.parser parseImageURLsFromHTMLString:[self allObamaHTML] targetWidth:160];
        assertThat(parsedObamaGalleryURLS, hasCountOf(31));
    }];
}

- (void)testCanonicalImageURLWithSizePrefixInFileName {
    // Normally images only have "XXXpx-" size prefix when returned from the thumbnail scaler, but there's nothing stopping users from uploading images with "XXXpx-" size prefix in the canonical name.
    // (See last image on "enwiki > Geothermal gradient")
    NSString* tagsToParse = @""
    "<img alt=\"300px-Geothermgradients.png\" src=\"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png\" width=\"300\" height=\"411\" class=\"thumbimage\" data-file-width=\"300\" data-file-height=\"411\">";
    
    NSArray *expectedURLs =
    [@[
       @"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png",
       ] bk_map:^NSURL*(NSString* stringURL){
           return [NSURL URLWithString:stringURL];
       }];

    assertThat([self.parser parseImageURLsFromHTMLString:tagsToParse targetWidth:1024], is(equalTo(expectedURLs)));
}

- (void)testTargetWidthGreaterThanCanonicalImageWidthForNonSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:1024];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthEqualToCanonicalImageWidthForNonSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:380];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthLessThanCanonicalImageWidthForNonSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:379];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/379px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthGreaterThanCanonicalImageWidthForSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:1024];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/1024px-Barack_Obama_signature.svg.png"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthEqualToCanonicalImageWidthForSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:182];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/1/11/Barack_Obama_signature.svg"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthLessThanCanonicalImageWidthForSVGImageURL {
    NSString* tags = @""
    "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";
    
    NSArray* parsedURLS = [self.parser parseImageURLsFromHTMLString:tags targetWidth:181];
    NSArray* expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/181px-Barack_Obama_signature.svg.png"]];
    
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

/*
NSArray *a = [parsedObamaGalleryURLS bk_map:^NSString*(NSURL* url){
    return url.absoluteString;
}];
NSLog(@"\n\n%@\n\n", a);
*/

@end
