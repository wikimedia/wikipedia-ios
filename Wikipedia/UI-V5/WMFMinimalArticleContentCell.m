//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFMinimalArticleContentCell.h"
#import "WMFLinkButtonFactory.h"

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

- (void)awakeFromNib {
    [super awakeFromNib];
    self.attributedTextContextView.shouldDrawImages = NO;
    self.attributedTextContextView.shouldDrawLinks  = YES;
    self.hasFixedRowHeight                          = NO;
    self.textDelegate                               = self.buttonFactory;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.attributedString = nil;
}

@end
