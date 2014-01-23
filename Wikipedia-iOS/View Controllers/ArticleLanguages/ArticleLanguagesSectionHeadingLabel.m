//  Created by Monte Hurd on 12/5/13.

#import "ArticleLanguagesSectionHeadingLabel.h"

@implementation ArticleLanguagesSectionHeadingLabel

- (id)init
{
    self = [super init];
    if (self) {
        //self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
        self.numberOfLines = 2;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
        self.backgroundColor = [UIColor clearColor];
        self.textColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    }
    return self;
}

@end
