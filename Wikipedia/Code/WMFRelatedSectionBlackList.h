
#import <Mantle/Mantle.h>

@class MWKTitle;

@interface WMFRelatedSectionBlackList : MTLModel

+ (instancetype)sharedBlackList;

/**
 *  Observable - observe to get KVO notifications
 */
@property (nonatomic, strong, readonly) NSArray<MWKTitle*>* blackListTitles;

/**
 *  Add a title to the black list
 *
 *  @param title The title to add
 */
- (void)addBlackListTitle:(MWKTitle*)title;

/**
 *  Remove a title to the black list
 *
 *  @param title The title to remove
 */
- (void)removeBlackListTitle:(MWKTitle*)title;

/**
 *  Check if a title is blacklisted
 *
 *  @param title The title to check
 */
- (BOOL)titleIsBlackListed:(MWKTitle*)title;


- (void)removeAllTitles;

@end
