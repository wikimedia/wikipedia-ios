#import "MWKList.h"

@interface NSURL (MWKListObject)<MWKListObject>
@end

@interface WMFRelatedSectionBlackList : MWKList<NSURL*, NSURL*>

+ (instancetype)sharedBlackList;

/**
 *  Add a url to the black list
 *
 *  @param url The url to add
 */
- (void)addBlackListArticleURL:(NSURL*)url;

/**
 *  Remove a url to the black list
 *
 *  @param url The url to remove
 */
- (void)removeBlackListArticleURL:(NSURL*)url;

/**
 *  Check if a url is blacklisted
 *
 *  @param url The url to check
 */
- (BOOL)articleURLIsBlackListed:(NSURL*)url;


@end
