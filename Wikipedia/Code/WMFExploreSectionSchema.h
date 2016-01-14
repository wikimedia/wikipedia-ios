
#import <Mantle/Mantle.h>

@class MWKSite, MWKSavedPageList, MWKHistoryList, WMFExploreSection;

@protocol WMFExploreSectionSchemaDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionSchema : MTLModel

/**
 *  Creates a schema by loading a persisted one from disk or
 *  if none is available, will create one
 *
 *  @param site site for populating sections
 *  @param savedPages Saved pages for populating sections
 *  @param history    History for populating sections
 *
 *  @return The schema
 */
+ (instancetype)schemaWithSite:(MWKSite*)site savedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history;

@property (nonatomic, strong, readonly) MWKSite* site;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* historyPages;

@property (nonatomic, weak, readwrite) id<WMFExploreSectionSchemaDelegate> delegate;

/**
 *  An array of the sections to be displayed on the home screen
 */
@property (nonatomic, strong, readonly) NSArray<WMFExploreSection*>* sections;

/**
 *  Update the schema based on the internal business rules
 *  When the update is complete the delegate will be notified
 *  Note that some sections (like Nearby) can take while to update.
 */
- (void)update;

/**
 *  The same as above, but always performs an update even if
 *  the business rules would dicatate otherwise.
 *  This is most useful for user inititiated updates
 *
 *  @param force If YES force an update
 */
- (void)update:(BOOL)force;

/**
 *  Reset the schema - removes all items and restores back to the "startingSchema"
 *  Call this when you clear out the feed.
 */
- (void)reset;

@end

@protocol WMFExploreSectionSchemaDelegate <NSObject>

- (void)sectionSchemaDidUpdateSections:(WMFExploreSectionSchema*)schema;

@end

NS_ASSUME_NONNULL_END