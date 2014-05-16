//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

typedef enum {
    DISCOVERY_METHOD_SEARCH = 0,
    DISCOVERY_METHOD_RANDOM = 1,
    DISCOVERY_METHOD_LINK = 2
} ArticleDiscoveryMethod;

@interface CenterNavController : UINavigationController <UINavigationControllerDelegate>

@property (nonatomic, readonly) BOOL isEditorOnNavstack;

-(void)loadArticleWithTitle: (NSString *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache;

-(void) promptFirstTimeZeroOnWithMessageIfAppropriate:(NSString *) message;
-(void) promptFirstTimeZeroOffIfAppropriate;

-(ArticleDiscoveryMethod)getDiscoveryMethodForString:(NSString *)string;
-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end

//TODO: maybe use currentNavBarTextFieldText instead of currentSearchString?
