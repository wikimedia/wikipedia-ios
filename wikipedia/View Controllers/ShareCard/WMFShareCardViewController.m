//
//  ShareCardViewController.m
//  Wikipedia
//
//  Created by Adam Baso on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareCardViewController.h"
#import "FocalImage.h"
#import "NSString+Extras.h"
#import "WMFShareCardImageContainer.h"

@interface WMFShareCardViewController ()

@property (weak, nonatomic) IBOutlet WMFShareCardImageContainer *shareCardImageContainer;
@property (weak, nonatomic) IBOutlet UILabel *shareSelectedText;
@property (weak, nonatomic) IBOutlet UILabel *shareArticleTitle;
@property (weak, nonatomic) IBOutlet UILabel *shareArticleDescription;
@end


@implementation WMFShareCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_0) {
        // quick hack for font scaling on iOS 6
        self.shareArticleTitle.numberOfLines = 1;
        self.shareArticleDescription.numberOfLines = 1;
        self.shareSelectedText.numberOfLines = 5;
        self.shareSelectedText.font = [UIFont systemFontOfSize:30.0f];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)fillCardWithMWKArticle:(MWKArticle *) article snippet:(NSString *) snippet
{

    self.shareArticleTitle.text = [article.displaytitle getStringWithoutHTML];
    self.shareArticleDescription.text = [[article.entityDescription getStringWithoutHTML] capitalizeFirstLetter];
    self.shareSelectedText.text = snippet;
    UIImage *leadImage = [article.image asUIImage];
    if (leadImage) {
        self.shareCardImageContainer.image = [[FocalImage alloc] initWithCGImage:leadImage.CGImage];
    }
}

@end
