//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SectionEditorViewController.h"
#import "MWPageTitle.h"
#import "FetcherBase.h"

typedef enum {
    DISCOVERY_METHOD_SEARCH,
    DISCOVERY_METHOD_RANDOM,
    DISCOVERY_METHOD_LINK,
    DISCOVERY_METHOD_BACKFORWARD
} ArticleDiscoveryMethod;

@interface CenterNavController : UINavigationController <UINavigationControllerDelegate, FetchFinishedDelegate>

@property (nonatomic, readonly) BOOL isEditorOnNavstack;
@property (nonatomic, readonly) SectionEditorViewController *editor;

-(void)loadArticleWithTitle: (MWPageTitle *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache
                 popToWebVC: (BOOL)popToWebVC;

-(void)loadTodaysArticle;
-(void)loadTodaysArticleIfNoCoreDataForCurrentArticle;
-(void)loadRandomArticle;

-(void) promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString *) title;
-(void) promptZeroOff;

-(ArticleDiscoveryMethod)getDiscoveryMethodForString:(NSString *)string;
-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end
