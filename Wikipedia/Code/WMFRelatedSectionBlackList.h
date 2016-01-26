
#import "MWKList.h"
#import "MWKTitle.h"

@interface MWKTitle (MWKListObject)<MWKListObject>
@end

@interface WMFRelatedSectionBlackList : MWKList<MWKTitle*, MWKTitle*>

+ (instancetype)sharedBlackList;

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


@end
