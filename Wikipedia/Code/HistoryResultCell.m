//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "HistoryResultCell.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"

@implementation HistoryResultCell

@synthesize imageView;
@synthesize textLabel;
@synthesize useField;

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.useField       = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setUseField:(BOOL)use {
    if (use) {
        // This "field" - ie a slight background color, slightly rounded corners,
        // and a light border - helps images which may have large amounts of white,
        // or which may have transparent parts, look much nicer and more visually
        // consistent. The thumbnails for search terms "Monaco" and "Poland", for
        // example, look much better atop this field.
        UIColor* borderColor = [UIColor colorWithWhite:0.0 alpha:0.1];

        self.imageView.layer.borderColor = borderColor.CGColor;
        self.imageView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;

        self.imageView.layer.cornerRadius = 0.0f;
        self.imageView.backgroundColor    = [UIColor colorWithWhite:0.0 alpha:0.025];
    } else {
        // The field can be turned off, when displaying the search term placeholder
        // image, for example.
        self.imageView.layer.borderWidth = 0.0f;
        self.imageView.backgroundColor   = [UIColor clearColor];
    }
    useField = use;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    //self.textLabel.layer.borderWidth = 1;
    //self.textLabel.layer.borderColor = [UIColor redColor].CGColor;
    //self.backgroundColor = [UIColor greenColor];

    [self adjustConstraintsScaleForViews:@[self.methodLabel, self.imageView, self.textLabel]];
}

- (void)prepareForReuse {
    //NSLog(@"imageView frame = %@", NSStringFromCGRect(self.imageView.frame));
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }

    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
