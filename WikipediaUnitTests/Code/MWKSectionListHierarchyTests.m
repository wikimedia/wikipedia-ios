#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKArticle.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSectionListHierarchyTests : XCTestCase
@property (nonatomic, strong) MWKArticle *dummyArticle;
@property (nonatomic) NSUInteger sectionIdCounter;
@end

@implementation MWKSectionListHierarchyTests

- (void)setUp {
    [super setUp];
    NSURL *dummyURL = [[NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"] wmf_URLWithTitle:@"Foo"];
    self.dummyArticle = [[MWKArticle alloc] initWithURL:dummyURL dataStore:nil];
    self.sectionIdCounter = 0;
}

- (void)testShouldHaveAllChildlessSectionsAtTopLevelForFlatHierarchy {
    MWKSectionList *flatList = [self sectionListWithLevels:@[@2, @2]];
    assertThat(flatList.entries, everyItem(hasProperty(WMF_SAFE_KEYPATH(MWKSection.new, children), isEmpty())));
    assertThat(flatList.topLevelSections, is(equalTo(flatList.entries)));
}

- (void)testShouldHaveParentlessSectionsAsTopLevelSections {
    MWKSectionList *list = [self sectionListWithLevels:@[@3, @2, @4, @2]];
    assertThat(list.topLevelSections, is(equalTo(@[list.entries[0], list.entries[1], list.entries[3]])));
}

- (void)testShouldHaveAllSubSectionsAsChildOfSharedParent {
    MWKSectionList *list = [self sectionListWithLevels:@[@2, @3, @3]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(@[list.entries.firstObject])));
    MWKSection *topLevelSection = topLevelSections.firstObject;
    assertThat(topLevelSection.children, is(equalTo(@[list.entries[1], list.entries[2]])));
}

- (void)testShouldHaveNestedSectionsAsChildrenOfTheirImmediateParent {
    MWKSectionList *list = [self sectionListWithLevels:@[@2, @3, @4]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(@[list.entries.firstObject])));
    MWKSection *topLevelSection = topLevelSections.firstObject;
    assertThat(topLevelSection.children, is(equalTo(@[list.entries[1]])));
    assertThat([topLevelSection.children.firstObject children], is(equalTo(@[list.entries[2]])));
}

- (void)testShouldHaveIndirectDescendantsAsChildren {
    MWKSectionList *list = [self sectionListWithLevels:@[@2, @5, @7]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(@[list.entries.firstObject])));
    MWKSection *topLevelSection = topLevelSections.firstObject;
    assertThat(topLevelSection.children, is(equalTo(@[list.entries[1]])));
    assertThat([topLevelSection.children.firstObject children], is(equalTo(@[list.entries[2]])));
}

- (void)testShouldNotHavePrecedingSubsectionsAsChildren {
    MWKSectionList *list = [self sectionListWithLevels:@[@3, @2, @7]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(@[list.entries[0], list.entries[1]])));
    assertThat([list.entries[0] children], isEmpty());
    assertThat([topLevelSections[1] children], is(equalTo(@[list.entries[2]])));
}

- (void)testShouldConsiderSectionsWithoutALevelAsChildlessOrphans {
    MWKSectionList *list = [self sectionListWithLevels:@[@2, [NSNull null], @4]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(list.entries)));
    assertThat(topLevelSections, everyItem(hasProperty(WMF_SAFE_KEYPATH(MWKSection.new, children), isEmpty())));
}

- (void)testShouldParseSectionsNormallyIfFirstSectionDoesNotHaveLevel {
    MWKSectionList *list = [self sectionListWithLevels:@[[NSNull null], @3, @2]];
    NSArray *topLevelSections = list.topLevelSections;
    assertThat(topLevelSections, is(equalTo(list.entries)));
    assertThat(topLevelSections, everyItem(hasProperty(WMF_SAFE_KEYPATH(MWKSection.new, children), isEmpty())));
}

#pragma mark - Utils

- (MWKSectionList *)sectionListWithLevels:(NSArray *)levels {
    MWKSectionList *list = [[MWKSectionList alloc] initWithArticle:self.dummyArticle
                                                          sections:[levels wmf_map:^MWKSection *(id levelOrNull) {
                                                              NSMutableDictionary *dict = [@{ @"id": @(self.sectionIdCounter++) } mutableCopy];
                                                              if (![[NSNull null] isEqual:levelOrNull]) {
                                                                  dict[@"level"] = levelOrNull;
                                                              }
                                                              return [[MWKSection alloc] initWithArticle:self.dummyArticle dict:dict];
                                                          }]];
    return list;
}

@end
