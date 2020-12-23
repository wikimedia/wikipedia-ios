@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface MWKLanguageLink : NSObject

/// Language code for the site where @c pageTitleText is located.
@property (readonly, copy, nonatomic, nonnull) NSString *languageCode;

/// Title text for the page linked to by the receiver.
@property (readonly, copy, nonatomic, nonnull) NSString *pageTitleText;

/// User-readable name for @c languageCode in the language specified in the current device language.
@property (readonly, copy, nonatomic, nonnull) NSString *localizedName;

/// User-readable name for @c languageCode in the language specified by @c languageCode.
@property (readonly, copy, nonatomic, nonnull) NSString *name;


- (instancetype)initWithLanguageCode:(nonnull NSString * )languageCode
                       pageTitleText:(nonnull NSString *)pageTitleText
                                name:(nonnull NSString *)name
                       localizedName:(nonnull NSString *)localizedName NS_DESIGNATED_INITIALIZER;

///
/// @name Comparison
///

- (BOOL)isEqualToLanguageLink:(MWKLanguageLink *)rhs;

- (NSComparisonResult)compare:(MWKLanguageLink *)other;

///
/// @name Computed Properties
///

/// @return A url with the default Wikipedia domain and the receiver's @c languageCode.
- (NSURL *)siteURL;

/// @return A url whose domain & path are derived from the receiver's @c languageCode and @c pageTitleText.
- (NSURL *)articleURL;

@end

NS_ASSUME_NONNULL_END
