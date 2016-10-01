#import <UIKit/UIKit.h>

@class WMFSearchLanguagesBarViewController, MWKLanguageLink;

@protocol WMFSearchLanguagesBarViewControllerDelegate <NSObject>

- (void)searchLanguagesBarController:(WMFSearchLanguagesBarViewController *)controller didChangeCurrentlySelectedSearchLanguage:(MWKLanguageLink*)language;

@end

@interface WMFSearchLanguagesBarViewController : UIViewController

@property (nonatomic, weak) id<WMFSearchLanguagesBarViewControllerDelegate> delegate;

@property (nonatomic, strong, readonly) MWKLanguageLink* currentlySelectedSearchLanguage;

@end
