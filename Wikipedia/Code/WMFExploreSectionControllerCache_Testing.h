#import "WMFExploreSectionControllerCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSectionControllerCache ()

@property(nonatomic, strong, readwrite) MWKDataStore *dataStore;

/**
 *  Cache of section controllers keyed by the section they were created for.
 *
 *  Controllers can be evicted at any time when the cache is asked to release memory by the operating system.
 */
@property(nonatomic, strong) NSMutableDictionary *sectionControllersBySection;

/**
 *  Reverse map of @c sectionControllersBySection which is used to retrieve sections by their associated controller.
 *
 */
@property(nonatomic, strong) NSMutableDictionary *reverseLookup;

@end

NS_ASSUME_NONNULL_END
