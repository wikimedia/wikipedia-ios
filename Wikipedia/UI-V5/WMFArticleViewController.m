//
//  WMFArticleViewController.m
//  Wikipedia
//
//  Created by Corey Floyd on 6/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleViewController.h"

@interface WMFArticleViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;

@end

@implementation WMFArticleViewController

#pragma mark - Accessors

- (void)setArticle:(MWKArticle*)article {
    if ([_article isEqual:article]) {
        return;
    }

    _article = article;

    [self updateUIAnimated:NO];
}

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark UI Updates

- (void)updateUIAnimated:(BOOL)animated {
    self.titleLabel.text = self.article.title.text;
}

@end
