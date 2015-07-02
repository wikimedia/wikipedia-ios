//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleExtractCell.h"

@interface WMFArticleExtractCell ()

@property (strong, nonatomic) IBOutlet UILabel* label;

@end

@implementation WMFArticleExtractCell

- (void)setExtractText:(NSString*)text {
    self.label.text = text;
}

@end
