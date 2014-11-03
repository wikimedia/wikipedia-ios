//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SectionEditorViewController.h"
#import "FetcherBase.h"

#import "MediaWikiKit.h"

@interface CenterNavController : UINavigationController <UINavigationControllerDelegate, FetchFinishedDelegate>

@property (nonatomic, readonly) BOOL isEditorOnNavstack;
@property (nonatomic, readonly) SectionEditorViewController *editor;

-(void)loadArticleWithTitle: (MWKTitle *)title
                   animated: (BOOL)animated
            discoveryMethod: (MWKHistoryDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache
                 popToWebVC: (BOOL)popToWebVC;

-(void)loadTodaysArticle;
-(void)loadTodaysArticleIfNoCoreDataForCurrentArticle;
-(void)loadRandomArticle;

-(void) promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString *) title;
-(void) promptZeroOff;

//-(ArticleDiscoveryMethod)getDiscoveryMethodForString:(NSString *)string;
//-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method;

-(void)switchPreferredLanguageToId:(NSString *)languageId name:(NSString *)name;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end
