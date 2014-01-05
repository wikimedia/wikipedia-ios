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
@property (nonatomic, retain) NSNumber *tocLevel;

@property (strong, nonatomic) NSMutableArray *imageViewsConstraints;
@property (strong, nonatomic) NSMutableArray *titleLabelConstraints;

@end

@implementation TOCSectionCellView

- (id)init
{
    self = [super init];
    if (self) {
        self.tocLevel = @(0);
        self.sectionId = nil;
        self.sectionImageIds = @[];
        
        self.imageViewsConstraints = [@[]mutableCopy];
        self.titleLabelConstraints = [@[]mutableCopy];
        
        self.titleLabel = [[UILabel alloc] init];
        //self.titleLabel.layer.borderWidth = 1.0f;
        self.sectionImageViews = [@[] mutableCopy];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.numberOfLines = 10;
        [self addSubview:self.titleLabel];
        
        self.indentMargin = 0.0f;
        self.indentMarginMin = 6.0f;

        self.imageIndentMargin = 0.0f;
        self.imageIndentMarginMin = 6.0f;

        self.imageMargin = 6.0f;
        self.imageSize = CGSizeMake(60.0f, 40.0f);

        self.isHighlighted = NO;
        
        self.clipsToBounds = YES;

        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];

        //self.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.3f].CGColor;
        //self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

-(void)setIsHighlighted:(BOOL)isHighlighted
{
    if (isHighlighted) {
        self.titleLabel.textColor = [UIColor colorWithRed:0.03 green:0.48 blue:0.92 alpha:1.0];
    }else{
        self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }
    
    if (isHighlighted) self.alpha = 1.0f;
    
    _isHighlighted = isHighlighted;
}

-(void)setSectionId:(NSManagedObjectID *)sectionId
{
    if (sectionId) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        Section *section = (Section *)[articleDataContext_.mainContext objectWithID:sectionId];
        
        self.tag = section.index.integerValue;

        self.titleLabel.text = (section.index.integerValue == 0) ? section.article.title : section.title;
        
        // Add tocLevel for debugging.
        //self.titleLabel.text = [NSString stringWithFormat:@"%@-%@ : %@", section.index, section.tocLevel, self.titleLabel.text];
        
        if (section.index.integerValue == 0) {
            self.titleLabel.font = [UIFont fontWithName:@"Georgia" size:24];
        }else{
            self.titleLabel.font = [UIFont fontWithName:@"Georgia" size:18];
        }
        
        // Remove previous images.
        [self.sectionImageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.sectionImageViews removeAllObjects];

        if (self.sectionImageIds.count > 0) {
            [self addSectionImageViews];
            [self resetSectionImageViewsBorderStyle];
        }
//TODO: if section index is 0 tack a toggle view on top of it (on right side) then hook up to animate changes to
// label and image constraints to provide for switching between current layout and a larger vertically stacked
// image layout and another layout with just a single tiny thumbnail (from 1st img) to left of section title w/
// section title tabbed over at tocLevel.
        self.tocLevel = section.tocLevel;

    }else{
        self.titleLabel.text = @"";
    }

    _sectionId = sectionId;
}

-(void)resetSectionImageViewsBorderStyle
{
//TODO: create object for section images so things like their highlighted state can be more easily managed/encapsulated.
    for (UIView *i in self.sectionImageViews) {
        i.layer.borderColor = [UIColor whiteColor].CGColor;
        //i.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        //i.layer.cornerRadius = 80.0f;
    }
}

-(void)addSectionImageViews
{
    ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
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
        imageView.userInteractionEnabled = YES;

        imageView.layer.borderWidth = 4.0 / [UIScreen mainScreen].scale;

        // Needed because sometimes these images have transparency.
        imageView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
        
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = [UIImage imageWithData:sectionImage.image.data];
        [self.sectionImageViews addObject:imageView];
        [self addSubview:imageView];
    }
}

-(void)updateConstraints
{
    [self removeConstraints:self.constraints];
    [self constrainTitleLabel:self.tocLevel];
    [self constrainSectionImages:self.tocLevel];
    
    [super updateConstraints];
}

-(void)constrainSectionImages:(NSNumber *)tocLevel
{
    [self removeConstraints:self.imageViewsConstraints];
    
    if(self.sectionImageViews.count > 0){
        NSLayoutConstraint *titleLabelBottomConstraint = nil;
        for (NSLayoutConstraint *c in self.constraints) {
            if ((c.firstItem == self.titleLabel) && (c.firstAttribute == NSLayoutAttributeBottom)) {
                titleLabelBottomConstraint = c;
                break;
            }
        }
        [self removeConstraint:titleLabelBottomConstraint];
    }

    void (^constrain)(UIView *, NSLayoutAttribute, UIView *, NSLayoutAttribute, CGFloat) = ^void(UIView *view1, NSLayoutAttribute a1, UIView *view2, NSLayoutAttribute a2, CGFloat constant) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: view2
                                      attribute: a2
                                     multiplier: 1.0
                                       constant: constant];
        [self addConstraint:constraint];
        [self.imageViewsConstraints addObject:constraint];
    };

    UIImageView *prevImage = nil;
    for (UIImageView *imageView in self.sectionImageViews) {

        // Default layout with horizontal row of images beneath title label.
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

//TODO: hook up swapping out the constraints above to the constraits below to a toggle. Animate the transistion.
        continue;
        
        // Layout with vertically stacked image beneath title layout.
        self.imageSize = CGSizeMake(160.0f, 160.0f);
        constrain(imageView, NSLayoutAttributeRight, self, NSLayoutAttributeRight, -self.imageMargin);
        constrain(imageView, NSLayoutAttributeWidth, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.width);
        constrain(imageView, NSLayoutAttributeHeight, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.height);
        if (self.sectionImageViews.firstObject == imageView) {
            constrain(imageView, NSLayoutAttributeTop, self.titleLabel, NSLayoutAttributeBottom, 0);
        }
        if (self.sectionImageViews.lastObject == imageView) {
            constrain(imageView, NSLayoutAttributeBottom, self, NSLayoutAttributeBottom, -self.imageMargin);
        }
        if (prevImage) {
            constrain(imageView, NSLayoutAttributeTop, prevImage, NSLayoutAttributeBottom, self.imageMargin);
        }
        prevImage = imageView;
    }
}

-(void)constrainTitleLabel:(NSNumber *)tocLevel
{
    [self removeConstraints:self.titleLabelConstraints];
    void (^constrainTitleLabel)(NSLayoutAttribute, CGFloat) = ^void(NSLayoutAttribute a, CGFloat constant) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: self.titleLabel
                                      attribute: a
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: self
                                      attribute: a
                                     multiplier: 1.0
                                       constant: constant];

        [self addConstraint:constraint];
        [self.titleLabelConstraints addObject:constraint];
    };
    
    NSInteger tocLevelToUse = ((self.tocLevel.intValue - 1) < 0) ? 0 : self.tocLevel.intValue - 1;
    constrainTitleLabel(NSLayoutAttributeLeft, (tocLevelToUse * self.indentMargin) + self.indentMarginMin);
    constrainTitleLabel(NSLayoutAttributeRight, -5);
    constrainTitleLabel(NSLayoutAttributeTop, 0);
    constrainTitleLabel(NSLayoutAttributeBottom, 0);
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:[titleLabel(>=50)]"
                                             options: 0
                                             metrics: 0
                                               views: @{@"titleLabel": self.titleLabel}];
    [self addConstraints:constraints];
    [self.titleLabelConstraints addObjectsFromArray:constraints];
}

-(NSArray *)imagesIntersectingYOffset:(CGFloat)yOffset inView:(UIView *)view;
{
    NSMutableArray *imagesIntersectingYOffset = [@[] mutableCopy];
    for (UIView *v in self.sectionImageViews) {
        CGPoint p = [v convertPoint:CGPointZero toView:view];
        if ((p.y < yOffset) && ((p.y + v.frame.size.height) > yOffset)) {
            [imagesIntersectingYOffset addObject:v];
        }
    }
    return imagesIntersectingYOffset;
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
