#import <XCTest/XCTest.h>
#import "MWKTestCase.h"
#import "WMFImageTagParser.h"
#import "WMFImageTagList.h"
#import "WMFImageTag.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "WMFImageTagList+ImageURLs.h"
#import <OCHamcrest/OCHamcrest.h>

@interface NSString (WMFImageTagParser)

- (NSString *)wmf_stringWithPercentEncodedTagAttributeValues;

@end

@interface WMFImageTagParser (Testing)

- (NSString *)imgTagsOnlyFromHTMLString:(NSString *)HTMLString;

@end

@interface WMFImageTagParserTests : MWKTestCase

@property (nonatomic, strong) WMFImageTagParser *parser;
@property (nonatomic, strong) WMFImageTagList *obamaImageTagList;
@property (nonatomic, strong) NSURL *baseURL;

@end

@implementation WMFImageTagParserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.parser = [[WMFImageTagParser alloc] init];
    self.obamaImageTagList = [self.parser imageTagListFromParsingHTMLString:self.allObamaHTML withBaseURL:self.obamaBaseURL];
    self.baseURL = self.obamaBaseURL;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.parser = nil;
    self.obamaImageTagList = nil;
    [super tearDown];
}

- (NSArray<NSURL *> *)urlsFromHMTL:(NSString *)html atTargetWidth:(NSUInteger)targetWidth {
    WMFImageTagList *tagList = [self.parser imageTagListFromParsingHTMLString:html withBaseURL:self.baseURL];
    NSArray<NSURL *> *imageTags = [tagList.imageTags wmf_map:^NSURL *(WMFImageTag *tag) {
        return [tag URLForTargetWidth:targetWidth];
    }];
    return imageTags;
}

- (void)testObamaArticleGalleryImageListExtraction {
    NSArray *parsedObamaGalleryURLS = [self.obamaImageTagList imageURLsForGallery];

    NSArray *expectedObamaGalleryURLs =
        [@[
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/640px-President_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/b/b6/Obamamiltondavis1.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/640px-2004_Illinois_Senate_results.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/640px-BarackObamaportrait.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/7/79/Lugar-Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/640px-Flickr_Obama_Springfield_01.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg/640px-P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/640px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/640px-Obama_cabinet_meeting_2009-11.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png/640px-U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/640px-US_Employment_Statistics.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/640px-Obama-venice-la.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Obama_signs_health_care-20100323.jpg/640px-Obama_signs_health_care-20100323.jpg",
            @"//upload.wikimedia.org/wikipedia/en/thumb/7/79/PPACA_Premium_Chart.jpg/640px-PPACA_Premium_Chart.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/640px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/640px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/640px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/640px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/640px-Official_portrait_of_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/9/97/Barack_Obama_hangout.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/640px-G8_leaders_watching_football.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/640px-Obama_family_portrait_in_the_Green_Room.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/640px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/640px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/640px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/640px-Seal_of_the_President_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Seal_of_the_United_States_Senate.svg/640px-Seal_of_the_United_States_Senate.svg.png"
        ] wmf_map:^NSURL *(NSString *stringURL) {
            return [NSURL URLWithString:stringURL];
        }];

    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testObamaArticleSavingImageListExtraction {
    NSArray *parsedObamaGalleryURLS = [self.obamaImageTagList imageURLsForSaving];

    NSArray *expectedObamaGalleryURLs =
        [@[
            @"//upload.wikimedia.org/wikipedia/en/thumb/e/e7/Cscr-featured.svg/15px-Cscr-featured.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Padlock-silver.svg/20px-Padlock-silver.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/640px-President_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Barack-Obama-portrait-PD.jpeg/30px-Barack-Obama-portrait-PD.jpeg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Speakerlink-new.svg/11px-Speakerlink-new.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/b/b6/Obamamiltondavis1.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/640px-2004_Illinois_Senate_results.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/640px-BarackObamaportrait.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/7/79/Lugar-Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/640px-Flickr_Obama_Springfield_01.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg/640px-P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/640px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/640px-Obama_cabinet_meeting_2009-11.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/a5/20090124_WeeklyAddress.ogv/220px-seek%3D63-20090124_WeeklyAddress.ogv.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png/640px-U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/640px-US_Employment_Statistics.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/640px-Obama-venice-la.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Obama_signs_health_care-20100323.jpg/640px-Obama_signs_health_care-20100323.jpg",
            @"//upload.wikimedia.org/wikipedia/en/thumb/7/79/PPACA_Premium_Chart.jpg/640px-PPACA_Premium_Chart.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/640px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/640px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/640px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/12/President_Obama_on_Death_of_Osama_bin_Laden.ogv/220px--President_Obama_on_Death_of_Osama_bin_Laden.ogv.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Wikisource-logo.svg/11px-Wikisource-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/640px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/640px-Official_portrait_of_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/9/97/Barack_Obama_hangout.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/640px-G8_leaders_watching_football.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/640px-Obama_family_portrait_in_the_Green_Room.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/640px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/640px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/47/Sound-icon.svg/45px-Sound-icon.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/47/Sound-icon.svg/15px-Sound-icon.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/640px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/89/Symbol_book_class2.svg/16px-Symbol_book_class2.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/4/48/Folder_Hexagonal_Icon.svg/16px-Folder_Hexagonal_Icon.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/12px-Commons-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikibooks-logo.svg/16px-Wikibooks-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikiquote-logo.svg/13px-Wikiquote-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Wikisource-logo.svg/15px-Wikisource-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/f/fd/Portal-puzzle.svg/16px-Portal-puzzle.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/640px-Seal_of_the_President_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Yellow_flag_waving.svg/15px-Yellow_flag_waving.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/c/cf/Flag_of_Canada.svg/23px-Flag_of_Canada.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/c/c3/Flag_of_France.svg/23px-Flag_of_France.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/b/ba/Flag_of_Germany.svg/23px-Flag_of_Germany.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/0/03/Flag_of_Italy.svg/23px-Flag_of_Italy.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/9/9e/Flag_of_Japan.svg/23px-Flag_of_Japan.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/f/f3/Flag_of_Russia.svg/23px-Flag_of_Russia.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/a/ae/Flag_of_the_United_Kingdom.svg/23px-Flag_of_the_United_Kingdom.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/23px-Flag_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Flag_of_Europe.svg/23px-Flag_of_Europe.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/23px-Flag_of_Argentina.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/b/b9/Flag_of_Australia.svg/23px-Flag_of_Australia.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/0/05/Flag_of_Brazil.svg/22px-Flag_of_Brazil.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/c/cf/Flag_of_Canada.svg/23px-Flag_of_Canada.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Flag_of_the_People%27s_Republic_of_China.svg/23px-Flag_of_the_People%27s_Republic_of_China.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Flag_of_Europe.svg/23px-Flag_of_Europe.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/c/c3/Flag_of_France.svg/23px-Flag_of_France.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/b/ba/Flag_of_Germany.svg/23px-Flag_of_Germany.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/4/41/Flag_of_India.svg/23px-Flag_of_India.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Flag_of_Indonesia.svg/23px-Flag_of_Indonesia.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/0/03/Flag_of_Italy.svg/23px-Flag_of_Italy.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/9/9e/Flag_of_Japan.svg/23px-Flag_of_Japan.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Flag_of_Mexico.svg/23px-Flag_of_Mexico.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/f/f3/Flag_of_Russia.svg/23px-Flag_of_Russia.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Flag_of_Saudi_Arabia.svg/23px-Flag_of_Saudi_Arabia.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/af/Flag_of_South_Africa.svg/23px-Flag_of_South_Africa.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/0/09/Flag_of_South_Korea.svg/23px-Flag_of_South_Korea.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Flag_of_Turkey.svg/23px-Flag_of_Turkey.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/a/ae/Flag_of_the_United_Kingdom.svg/23px-Flag_of_the_United_Kingdom.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/23px-Flag_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/b/b9/Flag_of_Australia.svg/23px-Flag_of_Australia.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Flag_of_Brunei.svg/23px-Flag_of_Brunei.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/c/cf/Flag_of_Canada.svg/23px-Flag_of_Canada.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/7/78/Flag_of_Chile.svg/23px-Flag_of_Chile.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Flag_of_the_People%27s_Republic_of_China.svg/23px-Flag_of_the_People%27s_Republic_of_China.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/14/Flag_of_Chinese_Taipei_for_Olympic_games.svg/23px-Flag_of_Chinese_Taipei_for_Olympic_games.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Flag_of_Hong_Kong.svg/23px-Flag_of_Hong_Kong.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Flag_of_Indonesia.svg/23px-Flag_of_Indonesia.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/9/9e/Flag_of_Japan.svg/23px-Flag_of_Japan.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/0/09/Flag_of_South_Korea.svg/23px-Flag_of_South_Korea.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/66/Flag_of_Malaysia.svg/23px-Flag_of_Malaysia.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Flag_of_Mexico.svg/23px-Flag_of_Mexico.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Flag_of_New_Zealand.svg/23px-Flag_of_New_Zealand.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Flag_of_Papua_New_Guinea.svg/20px-Flag_of_Papua_New_Guinea.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Flag_of_Peru.svg/23px-Flag_of_Peru.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flag_of_the_Philippines.svg/23px-Flag_of_the_Philippines.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/f/f3/Flag_of_Russia.svg/23px-Flag_of_Russia.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/48/Flag_of_Singapore.svg/23px-Flag_of_Singapore.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Flag_of_Thailand.svg/23px-Flag_of_Thailand.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/23px-Flag_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/21/Flag_of_Vietnam.svg/23px-Flag_of_Vietnam.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Seal_of_the_United_States_Senate.svg/640px-Seal_of_the_United_States_Senate.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Office-book.svg/30px-Office-book.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Obama.svg/22px-Obama.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Great_Seal_of_the_United_States_%28obverse%29.svg/30px-Great_Seal_of_the_United_States_%28obverse%29.svg.png",
            @"//upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/22px-Commons-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/24/Wikinews-logo.svg/30px-Wikinews-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikiquote-logo.svg/25px-Wikiquote-logo.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Wikisource-logo.svg/29px-Wikisource-logo.svg.png"
        ] wmf_map:^NSURL *(NSString *stringURL) {
            return [NSURL URLWithString:stringURL];
        }];

    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testParsingObamaHTMLPerformance {
    [self measureBlock:^{
        NSArray *parsedObamaGalleryURLS = [[self.parser imageTagListFromParsingHTMLString:self.allObamaHTML withBaseURL:self.obamaBaseURL] imageURLsForGallery];
        assertThat(parsedObamaGalleryURLS, hasCountOf(31));
    }];
}

- (void)testCanonicalImageURLWithSizePrefixInFileName {
    // Normally images only have "XXXpx-" size prefix when returned from the thumbnail scaler, but there's nothing stopping users from uploading images with "XXXpx-" size prefix in the canonical name.
    // (See last image on "enwiki > Geothermal gradient")
    NSString *tagsToParse = @""
                             "<img alt=\"300px-Geothermgradients.png\" src=\"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png\" width=\"300\" height=\"411\" class=\"thumbimage\" data-file-width=\"300\" data-file-height=\"411\">";

    NSArray *expectedURLs =
        [@[
            @"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png",
        ] wmf_map:^NSURL *(NSString *stringURL) {
            return [NSURL URLWithString:stringURL];
        }];

    assertThat([self urlsFromHMTL:tagsToParse atTargetWidth:1024], is(equalTo(expectedURLs)));
}

- (void)testTargetWidthGreaterThanCanonicalImageWidthForNonSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:1024];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthEqualToCanonicalImageWidthForNonSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:380];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthLessThanCanonicalImageWidthForNonSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/220px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg\" width=\"220\" height=\"212\" class=\"thumbimage\" data-file-width=\"380\" data-file-height=\"366\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:379];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/f/f8/The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg/379px-The_Ant_and_the_Grasshopper_-_Project_Gutenberg_etext_19994.jpg"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthGreaterThanCanonicalImageWidthForSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:1024];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/1024px-Barack_Obama_signature.svg.png"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthEqualToCanonicalImageWidthForSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:182];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/1/11/Barack_Obama_signature.svg"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testTargetWidthLessThanCanonicalImageWidthForSVGImageURL {
    NSString *tags = @""
                      "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" width=\"128\" height=\"31\" data-file-width=\"182\" data-file-height=\"44\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:181];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/181px-Barack_Obama_signature.svg.png"]];

    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

- (void)testObamaArticleGalleryImageListExtractionWithLeadImage {
    NSArray *parsedObamaGalleryURLS = [[self.parser imageTagListFromParsingHTMLString:self.allObamaHTML withBaseURL:self.obamaBaseURL leadImageURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/640px-BarackObamaportrait.jpg"]] imageURLsForGallery];

    NSArray *expectedObamaGalleryURLs =
        [@[
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/640px-BarackObamaportrait.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/640px-President_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/b/b6/Obamamiltondavis1.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/640px-2004_Illinois_Senate_results.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/7/79/Lugar-Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/640px-Flickr_Obama_Springfield_01.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg/640px-P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/640px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/640px-Obama_cabinet_meeting_2009-11.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png/640px-U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/640px-US_Employment_Statistics.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/640px-Obama-venice-la.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Obama_signs_health_care-20100323.jpg/640px-Obama_signs_health_care-20100323.jpg",
            @"//upload.wikimedia.org/wikipedia/en/thumb/7/79/PPACA_Premium_Chart.jpg/640px-PPACA_Premium_Chart.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/640px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/640px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/640px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/640px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/640px-Official_portrait_of_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/9/97/Barack_Obama_hangout.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/640px-G8_leaders_watching_football.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/640px-Obama_family_portrait_in_the_Green_Room.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/640px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/640px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/640px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/640px-Seal_of_the_President_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Seal_of_the_United_States_Senate.svg/640px-Seal_of_the_United_States_Senate.svg.png"
        ] wmf_map:^NSURL *(NSString *stringURL) {
            return [NSURL URLWithString:stringURL];
        }];

    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testObamaArticleGalleryImageListExtractionWithMistmatchedSizeLeadImage {
    NSArray *parsedObamaGalleryURLS = [[self.parser imageTagListFromParsingHTMLString:self.allObamaHTML withBaseURL:self.obamaBaseURL leadImageURL:self.obamaLeadImageURL] imageURLsForGallery];

    NSArray *expectedObamaGalleryURLs =
        [@[
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f1/BarackObamaportrait.jpg/640px-BarackObamaportrait.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/640px-President_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/b/b6/Obamamiltondavis1.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/50/2004_Illinois_Senate_results.svg/640px-2004_Illinois_Senate_results.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/7/79/Lugar-Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/9/99/Flickr_Obama_Springfield_01.jpg/640px-Flickr_Obama_Springfield_01.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/a/a2/President_George_W._Bush_and_Barack_Obama_meet_in_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/33/P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg/640px-P112912PS-0444_-_President_Barack_Obama_and_Mitt_Romney_in_the_Oval_Office_-_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d7/US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg/640px-US_President_Barack_Obama_taking_his_Oath_of_Office_-_2009Jan20.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/3/32/Barack_Obama_addresses_joint_session_of_Congress_2009-02-24.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama_cabinet_meeting_2009-11.jpg/640px-Obama_cabinet_meeting_2009-11.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/fc/U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png/640px-U.S._Total_Deficits_vs._National_Debt_Increases_2001-2010.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/640px-US_Employment_Statistics.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/6/63/Obama-venice-la.jpg/640px-Obama-venice-la.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Obama_signs_health_care-20100323.jpg/640px-Obama_signs_health_care-20100323.jpg",
            @"//upload.wikimedia.org/wikipedia/en/thumb/7/79/PPACA_Premium_Chart.jpg/640px-PPACA_Premium_Chart.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg/640px-Barack_Obama_visiting_victims_of_2012_Aurora_shooting.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/b/be/David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg/640px-David_Cameron_and_Barack_Obama_at_the_G20_Summit_in_Toronto.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg/640px-Barack_Obama_welcomes_Shimon_Peres_in_the_Oval_Office.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Obama_and_Biden_await_updates_on_bin_Laden.jpg/640px-Obama_and_Biden_await_updates_on_bin_Laden.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Official_portrait_of_Barack_Obama.jpg/640px-Official_portrait_of_Barack_Obama.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/9/97/Barack_Obama_hangout.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3f/G8_leaders_watching_football.jpg/640px-G8_leaders_watching_football.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/2/26/Obama_family_portrait_in_the_Green_Room.jpg/640px-Obama_family_portrait_in_the_Green_Room.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/640px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Obamas_at_church_on_Inauguration_Day_2013.jpg/640px-Obamas_at_church_on_Inauguration_Day_2013.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/5/55/President_Barack_Obama%2C_2012_portrait_crop.jpg/640px-President_Barack_Obama%2C_2012_portrait_crop.jpg",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/3/36/Seal_of_the_President_of_the_United_States.svg/640px-Seal_of_the_President_of_the_United_States.svg.png",
            @"//upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Seal_of_the_United_States_Senate.svg/640px-Seal_of_the_United_States_Senate.svg.png"
        ] wmf_map:^NSURL *(NSString *stringURL) {
            return [NSURL URLWithString:stringURL];
        }];

    assertThat(parsedObamaGalleryURLS, is(equalTo(expectedObamaGalleryURLs)));
}

- (void)testAltTagWithFunkyCharactersDoesNotChokeParser {
    // The second image below is from "enwiki > Logarithm > Applications". The first image is the last mathematical symbol image in the previous section.
    NSString *tags = @""
                      "<img src=\"https://wikimedia.org/api/rest_v1/media/math/render/svg/f4f0044fb2bdba6bee5dcc5b57ac9fc62a5edbb9\" class=\"mwe-math-fallback-image-inline\" aria-hidden=\"true\" style=\"vertical-align: -3.005ex; width:35.142ex; height:5.843ex;\" alt=\"\\ln(x)\approx {\frac {\\pi }{2M(1,2^{2-m}/x)}}-m\\ln(2).\">"
                      "<img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/0/08/NautilusCutawayLogarithmicSpiral.jpg/220px-NautilusCutawayLogarithmicSpiral.jpg\" width=\"220\" height=\"166\" class=\"thumbimage\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/0/08/NautilusCutawayLogarithmicSpiral.jpg/330px-NautilusCutawayLogarithmicSpiral.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/0/08/NautilusCutawayLogarithmicSpiral.jpg/440px-NautilusCutawayLogarithmicSpiral.jpg 2x\" data-file-width=\"2240\" data-file-height=\"1693\">";

    NSArray *parsedURLS = [self urlsFromHMTL:tags atTargetWidth:1024];
    NSArray *expectedULRS = @[[NSURL URLWithString:@"//wikimedia.org/api/rest_v1/media/math/render/svg/f4f0044fb2bdba6bee5dcc5b57ac9fc62a5edbb9"],
                              [NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/0/08/NautilusCutawayLogarithmicSpiral.jpg/1024px-NautilusCutawayLogarithmicSpiral.jpg"]];
    assertThat(parsedURLS, is(equalTo(expectedULRS)));
}

/*
NSArray *a = [parsedObamaGalleryURLS wmf_map:^NSString*(NSURL* url){
    return [NSString stringWithFormat:@"%@", url.absoluteString];
}];
NSLog(@"\n============\n\n%@\n\n=============\n", a);
*/

- (void)testBaseURL {
    NSString *tags = @""
                      "<img src=\"/w/extensions/wikihiero/img/hiero_V4.png?e648c\">"
                      "<img src=\"w/extensions/wikihiero/img/hiero_V4.png?e648c\">"
                      "<img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg\">";
    NSArray *parsedURLs = [self urlsFromHMTL:tags atTargetWidth:1024];
    NSArray *expectedULRs = @[[NSURL URLWithString:@"//en.m.wikipedia.org/w/extensions/wikihiero/img/hiero_V4.png?e648c"],
                              [NSURL URLWithString:@"//en.m.wikipedia.org/wiki/Barack_Obama/w/extensions/wikihiero/img/hiero_V4.png%3Fe648c?e648c"],
                              [NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/4/42/Barack_Obama_at_Cairo_University_cropped.jpg/640px-Barack_Obama_at_Cairo_University_cropped.jpg"]];
    assertThat(parsedURLs, is(equalTo(expectedULRs)));
}

@end
