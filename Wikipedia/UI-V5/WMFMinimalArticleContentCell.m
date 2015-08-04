//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFMinimalArticleContentCell.h"
#import "WMFLinkButtonFactory.h"
#import <Masonry/Masonry.h>

@interface WMFMinimalArticleContentCell ()
<DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) WMFLinkButtonFactory* buttonFactory;

@end

@implementation WMFMinimalArticleContentCell

- (WMFLinkButtonFactory*)buttonFactory {
    if (!_buttonFactory) {
        _buttonFactory = [WMFLinkButtonFactory new];
    }
    return _buttonFactory;
}

- (void)setArticleNavigationDelegate:(id<WMFArticleNavigationDelegate> __nullable)articleNavigationDelegate {
    self.buttonFactory.articleNavigationDelegate = articleNavigationDelegate;
}

- (id<WMFArticleNavigationDelegate>)articleNavigationDelegate {
    return self.buttonFactory.articleNavigationDelegate;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.attributedTextContextView.shouldDrawImages = NO;
        self.attributedTextContextView.shouldDrawLinks  = YES;
        self.hasFixedRowHeight                          = NO;
        self.textDelegate                               = self.buttonFactory;
        self.attributedTextContextView.edgeInsets       = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
    }
    return self;
}

@end
