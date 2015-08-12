//
//  WMFArticleListCollectionViewController_Transitioning.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleListCollectionViewController.h"
#import "WMFArticleListTransition.h"
#import "WMFListTransitionProvider.h"

@interface WMFArticleListCollectionViewController ()
<WMFArticleListTransitioning, WMFArticleListTransitionProvider>

@property (nonatomic, strong, readonly) WMFArticleListTransition* listTransition;

@end
