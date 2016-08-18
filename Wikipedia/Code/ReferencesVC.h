#import <UIKit/UIKit.h>

@class ReferencesVC;

@protocol ReferencesVCDelegate <NSObject>

- (void)referenceViewController:(ReferencesVC *)referenceViewController didShowReferenceWithLinkID:(NSString *)linkID;
- (void)referenceViewController:(ReferencesVC *)referenceViewController didFinishShowingReferenceWithLinkID:(NSString *)linkID;

- (void)referenceViewController:(ReferencesVC *)referenceViewController didSelectInternalReferenceWithFragment:(NSString *)fragment;
- (void)referenceViewController:(ReferencesVC *)referenceViewController didSelectReferenceWithURL:(NSURL *)url;
- (void)referenceViewController:(ReferencesVC *)referenceViewController didSelectExternalReferenceWithURL:(NSURL *)url;

- (void)referenceViewControllerCloseReferences:(ReferencesVC *)referenceViewController;

@end

@interface ReferencesVC : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property(strong, nonatomic) UIPageViewController *pageController;

@property(strong, nonatomic) NSDictionary *payload;

@property(weak, nonatomic) id<ReferencesVCDelegate> delegate;

@property(assign) CGFloat panelHeight;

- (void)reset;

@end
