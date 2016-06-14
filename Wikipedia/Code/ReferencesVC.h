//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class ReferencesVC, MWKTitle;

@protocol ReferencesVCDelegate <NSObject>

- (void)referenceViewController:(ReferencesVC*)referenceViewController didShowReferenceWithLinkID:(NSString*)linkID;
- (void)referenceViewController:(ReferencesVC*)referenceViewController didFinishShowingReferenceWithLinkID:(NSString*)linkID;

- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectInternalReferenceWithFragment:(NSString*)fragment;
- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectReferenceWithTitle:(MWKTitle*)title;
- (void)referenceViewController:(ReferencesVC*)referenceViewController didSelectExternalReferenceWithURL:(NSURL*)url;

- (void)referenceViewControllerCloseReferences:(ReferencesVC*)referenceViewController;

@end

@interface ReferencesVC : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController* pageController;

@property (strong, nonatomic) NSDictionary* payload;

@property (weak, nonatomic) id<ReferencesVCDelegate> delegate;

@property (assign) CGFloat panelHeight;

- (void)reset;

@end
