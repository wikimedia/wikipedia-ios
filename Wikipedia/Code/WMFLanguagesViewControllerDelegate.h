@class WMFLanguagesViewController;

/*
 * Protocol for notifying languageSelectionDelegate that selection was made.
 * It is the receiver's responsibility to perform the appropriate action and dismiss the sender.
 */
@protocol WMFLanguagesViewControllerDelegate <NSObject>

@optional
- (void)languagesController:(WMFLanguagesViewController * _Nonnull)controller didSelectLanguage:(MWKLanguageLink * _Nonnull)language;

@end
