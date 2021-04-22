@import Foundation;

@interface NSAttributedString (WMFSavedPagesAttributedStrings)

+ (NSAttributedString *)wmf_attributedStringWithTitle:(NSString *)title
                                          description:(NSString *)description
                                         languageCode:(NSString *)languageCode;

@end
