//  Created by Monte Hurd on 12/28/13.

#import "TOCSectionCellView.h"
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"

@interface TOCSectionCellView(){

}

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *sectionImageViews;

@property (nonatomic) CGFloat indentMargin;
@property (nonatomic) CGFloat indentMarginMin;

@property (nonatomic) CGFloat imageIndentMargin;
@property (nonatomic) CGFloat imageIndentMarginMin;
@property (nonatomic) CGFloat imageMargin;
@property (nonatomic) CGSize imageSize;

@end

@implementation TOCSectionCellView

- (id)init
{
    self = [super init];
    if (self) {
        self.sectionId = nil;
        self.sectionImageIds = @[];
        self.titleLabel = [[UILabel alloc] init];
        self.sectionImageViews = [@[] mutableCopy];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.numberOfLines = 10;
        [self addSubview:self.titleLabel];
        [self constrainTitleLabel];

        //self.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        //self.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.3f].CGColor;
        
        self.indentMargin = 0.0f;
        self.indentMarginMin = 6.0f;

        self.imageIndentMargin = 0.0f;
        self.imageIndentMarginMin = 6.0f;

        self.imageMargin = 6.0f;
        self.imageSize = CGSizeMake(60.0f, 40.0f);

        self.isHighlighted = NO;
        self.isSelected = NO;
        
        self.clipsToBounds = YES;
        
        //self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

-(void)setIsHighlighted:(BOOL)isHighlighted
{
    //self.alpha = (isHighlighted) ? 0.0f : 1.0f;
    //self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];

    if (isHighlighted) {
        self.backgroundColor = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:0.8];
        //self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        //self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
        //self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }else{
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        //self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        //self.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:1.0].CGColor;
        //self.layer.borderWidth = 0.0;
    }
    if (!isHighlighted) self.isSelected = NO;
    if (isHighlighted) self.alpha = 1.0f;
    
    _isHighlighted = isHighlighted;
}

-(void)setIsSelected:(BOOL)isSelected
{
    if (isSelected) {
        //self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
        self.titleLabel.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    }else{
        //self.layer.borderColor = [UIColor clearColor].CGColor;
        self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }
    if (isSelected) self.alpha = 1.0f;

    _isSelected = isSelected;
}

-(void)setSectionId:(NSManagedObjectID *)sectionId
{
    if (sectionId) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        Section *section = (Section *)[articleDataContext_.mainContext objectWithID:sectionId];
        
        self.tag = section.index.integerValue;
        
        [self indentTitleLabel: section.tocLevel];

        self.titleLabel.text = (section.index.integerValue == 0) ? section.article.title : section.title;
        
        if (section.index.integerValue == 0) {
            self.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:22];
        }else{
            self.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:17];
        }
        
        // Remove previous images.
        [self.sectionImageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.sectionImageViews removeAllObjects];

        if (self.sectionImageIds.count > 0) {
            [self addSectionImageViews];
            // Constrain section images
            [self constrainSectionImages:section.tocLevel];
        }
    }else{
        self.titleLabel.text = @"";
    }

    _sectionId = sectionId;
}

-(void)addSectionImageViews
{
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
    UIColor *borderColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    // Add section images
    NSUInteger i = 0;
    for (NSManagedObjectID *sectionImageId in self.sectionImageIds) {
        SectionImage *sectionImage = (SectionImage *)[articleDataContext_.mainContext objectWithID:sectionImageId];
        UIImageView *imageView = [[UIImageView alloc] init];
        // Tag will make it easy to take the tapped image and find its sectionImageId from sectionImageIds.
        imageView.tag = i; // Don't use this--> sectionImage.index.integerValue; (not all images are shown)
        i++;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.borderColor = borderColor.CGColor;
        imageView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        imageView.layer.cornerRadius = 0.0f;
        imageView.userInteractionEnabled = YES;
        // Needed because sometimes these images have transparency.
        imageView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
        
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = [UIImage imageWithData:sectionImage.image.data];
        [self.sectionImageViews addObject:imageView];
        [self addSubview:imageView];
    }
}

-(void)indentTitleLabel:(NSNumber *)tocLevel
{
    for (NSLayoutConstraint *c in self.constraints) {
        if ((c.firstItem == self.titleLabel) && (c.firstAttribute == NSLayoutAttributeLeft)) {
            c.constant = (tocLevel.floatValue * self.indentMargin) + self.indentMarginMin;
            break;
        }
    }
}

-(void)constrainSectionImages:(NSNumber *)tocLevel
{
    NSLayoutConstraint *titleLabelBottomConstraint = nil;
    for (NSLayoutConstraint *c in self.constraints) {
        if ((c.firstItem == self.titleLabel) && (c.firstAttribute == NSLayoutAttributeBottom)) {
            titleLabelBottomConstraint = c;
            break;
        }
    }
    
    [self removeConstraint:titleLabelBottomConstraint];
    

    void (^constrain)(UIView *, NSLayoutAttribute, UIView *, NSLayoutAttribute, CGFloat) = ^void(UIView *view1, NSLayoutAttribute a1, UIView *view2, NSLayoutAttribute a2, CGFloat constant) {
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: view2
                                      attribute: a2
                                     multiplier: 1.0
                                       constant: constant]];
    };

    UIImageView *prevImage = nil;
    for (UIImageView *imageView in self.sectionImageViews) {
        constrain(imageView, NSLayoutAttributeBottom, self, NSLayoutAttributeBottom, -self.imageMargin);
        constrain(imageView, NSLayoutAttributeWidth, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.width);
        constrain(imageView, NSLayoutAttributeHeight, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.height);
        if (self.sectionImageViews.firstObject == imageView) {
            constrain(imageView, NSLayoutAttributeTop, self.titleLabel, NSLayoutAttributeBottom, 0);
            constrain(imageView, NSLayoutAttributeLeft, self, NSLayoutAttributeLeft, (tocLevel.floatValue * self.imageIndentMargin) + self.imageIndentMarginMin);
        }
        if (prevImage) {
            constrain(imageView, NSLayoutAttributeLeft, prevImage, NSLayoutAttributeRight, self.imageMargin);
        }
        prevImage = imageView;
    }
}

-(void)constrainTitleLabel
{
    void (^constrainTitleLabel)(NSLayoutAttribute, CGFloat) = ^void(NSLayoutAttribute a, CGFloat constant) {
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem: self.titleLabel
                                      attribute: a
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: self
                                      attribute: a
                                     multiplier: 1.0
                                       constant: constant]];
    };
    
    constrainTitleLabel(NSLayoutAttributeLeft, 0);
    constrainTitleLabel(NSLayoutAttributeRight, -5);
    constrainTitleLabel(NSLayoutAttributeTop, 0);
    constrainTitleLabel(NSLayoutAttributeBottom, 0);
    
    [self addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"V:[titleLabel(>=50)]"
                                             options: 0
                                             metrics: 0
                                               views: @{@"titleLabel": self.titleLabel}]];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
