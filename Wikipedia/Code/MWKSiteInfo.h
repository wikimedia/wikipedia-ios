#import <WMF/MWKDataObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Type for siteinfo API responses.
/// @see https://www.mediawiki.org/wiki/API:Siteinfo
@interface MWKSiteInfo : NSObject

/// Site described by the receiver.
@property (readonly, copy, nonatomic) NSURL *siteURL;

/// Raw title for the receiver's main page.
@property (readonly, copy, nonatomic) NSString *mainPageTitleText;

@property (readonly, copy, nonatomic) NSNumber *readingListsConfigMaxEntriesPerList;
@property (readonly, copy, nonatomic) NSNumber *readingListsConfigMaxListsPerUser;

- (instancetype)initWithSiteURL:(NSURL *)siteURL
                      mainPageTitleText:(NSString *)mainPage
    readingListsConfigMaxEntriesPerList:(NSNumber *)readingListsConfigMaxEntriesPerList
      readingListsConfigMaxListsPerUser:(NSNumber *)readingListsConfigMaxListsPerUser NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToSiteInfo:(MWKSiteInfo *)siteInfo;

///
/// @name Computed Properties
///

/// @return Parsed @c NSURL from @c mainPage.
- (NSURL *)mainPageURL;

@end

NS_ASSUME_NONNULL_END
