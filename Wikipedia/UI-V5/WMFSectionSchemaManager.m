
#import "WMFSectionSchemaManager.h"
#import "MWKSite.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "WMFSectionSchemaItem.h"
#import "Wikipedia-Swift.h"


static NSUInteger const numberOfRecentSections = 3;
static NSUInteger const numberOfSavedSections  = 3;

@interface WMFSectionSchemaManager ()

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readwrite) MWKHistoryList* recentPages;

@property (nonatomic, strong, readwrite) NSArray* sectionSchema;

@end


@implementation WMFSectionSchemaManager

- (instancetype)initWithSavedPages:(MWKSavedPageList*)savedPages recentPages:(MWKHistoryList*)recentPages {
    self = [super init];
    if (self) {
        self.savedPages  = savedPages;
        self.recentPages = recentPages;
        [self updateSchema];
    }
    return self;
}

- (void)updateSchema {
    //get enough recents to reject any duplicates from saved
    NSArray* recents = [self titlesForMostRecentPages:numberOfRecentSections + numberOfSavedSections];
    NSArray* saved   = [self titlesForMostRecentSavedPages:numberOfSavedSections];

    //reject duplicates
    recents = [recents bk_reject:^BOOL (MWKTitle* obj) {
        if ([saved containsObject:obj]) {
            return YES;
        }
        return NO;
    }];

    //Trim recents to length after removing duplicates
    recents = [recents wmf_arrayByTrimmingToLength:numberOfRecentSections];

    //Create Schema Items
    recents = [self recentSchemaItemsForTitles:recents];
    saved   = [self savedSchemaItemsForTitles:saved];

    //Alternate recents and saved
    NSMutableArray* schema = [[recents wmf_arrayByInterleavingElementsFromArray:saved] mutableCopy];

    //Insert the nearby section as the second section
    if ([schema count] > 0) {
        [schema insertObject:[WMFSectionSchemaItem nearbyItem] atIndex:1];
    } else {
        [schema addObject:[WMFSectionSchemaItem nearbyItem]];
    }

    self.sectionSchema = schema;
}

- (NSArray*)titlesForMostRecentPages:(NSUInteger)maxNumberOfPages {
    NSArray* items = [self.recentPages.entries wmf_arrayByTrimmingToLengthFromEnd:maxNumberOfPages];
    return [[items bk_map:^id (MWKHistoryEntry* obj) {
        return obj.title;
    }] wmf_reverseArray];
}

- (NSArray*)titlesForMostRecentSavedPages:(NSUInteger)maxNumberOfPages {
    NSArray* items = [self.savedPages.entries wmf_arrayByTrimmingToLengthFromEnd:maxNumberOfPages];
    return [[items bk_map:^id (MWKSavedPageEntry* obj) {
        return obj.title;
    }] wmf_reverseArray];
}

- (NSArray*)recentSchemaItemsForTitles:(NSArray*)titles {
    return [titles bk_map:^id (MWKTitle* obj) {
        return [WMFSectionSchemaItem recentItemWithTitle:obj];
    }];
}

- (NSArray*)savedSchemaItemsForTitles:(NSArray*)titles {
    return [titles bk_map:^id (MWKTitle* obj) {
        return [WMFSectionSchemaItem savedItemWithTitle:obj];
    }];
}

@end
