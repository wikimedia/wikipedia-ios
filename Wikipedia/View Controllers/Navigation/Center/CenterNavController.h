//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SectionEditorViewController.h"

#import "MediaWikiKit.h"

@interface CenterNavController : UINavigationController <UINavigationControllerDelegate>

@property (nonatomic, readonly) BOOL isEditorOnNavstack;
@property (nonatomic, readonly) SectionEditorViewController* editor;

- (void)loadArticleWithTitle:(MWKTitle*)title
                    animated:(BOOL)animated
             discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                  popToWebVC:(BOOL)popToWebVC;

- (void)promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString*)title;
- (void)promptZeroOff;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end
