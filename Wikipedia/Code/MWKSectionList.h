#import <WMF/MWKDataObject.h>
#import <WMF/WMFBlockDefinitions.h>
NS_ASSUME_NONNULL_BEGIN
@class MWKArticle;
@class MWKSection;

@interface MWKSectionList : MWKDataObject <NSFastEnumeration>

/**
 *  Creates a section list and sets the sections to the provided array.
 *
 *  @param article  The article to load sections for
 *  @param sections The sections to load
 *
 *  @return The Section List
 */
- (instancetype)initWithArticle:(MWKArticle *)article sections:(NSArray *)sections;

/**
 *  Creates a section list and loads sections from disks
 *
 *  @param article The article to load sections for
 *
 *  @return The Section List
 */
- (instancetype)initWithArticle:(MWKArticle *)article;

@property (readonly, weak, nonatomic) MWKArticle *article;

@property (readonly, strong, nonatomic) NSArray *entries;

- (NSUInteger)count;
- (MWKSection *)objectAtIndexedSubscript:(NSUInteger)idx;

/// @return The first section whose `text` is not empty, or `nil` if all sections (or the receiver) are empty.
- (MWKSection *)firstNonEmptySection;

- (MWKSection *)sectionWithFragment:(NSString *)fragment;

- (BOOL)save:(NSError **)outError;

- (BOOL)isEqualToSectionList:(MWKSectionList *)sectionList;

///
/// @name Hierarchical Sections
///

/**
 *  Retrieve all child-less sections in the receiver.
 *
 *  Can be used to retrieve root sections from which the hierarchy can be traversed as a tree.
 *
 *  @return An array of `MWKSection` objects.
 */
- (NSArray *)topLevelSections;

@end
NS_ASSUME_NONNULL_END
