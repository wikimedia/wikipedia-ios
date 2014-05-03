//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TOCSectionCellView.h"
#import "ArticleCoreDataObjects.h"
#import "ArticleDataContextSingleton.h"
#import "NSString+Extras.h"
#import "TOCImageView.h"
#import "WMF_Colors.h"
#import "UIView+RemoveConstraints.h"
#import "Section+LeadSection.h"

@interface TOCSectionCellView(){

}

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic) CGFloat indentMargin;
@property (nonatomic) CGFloat indentMarginMin;

@property (nonatomic) CGFloat imageIndentMargin;
@property (nonatomic) CGFloat imageIndentMarginMin;
@property (nonatomic) CGFloat imageMargin;
@property (nonatomic) CGSize imageSize;

@property (nonatomic, strong) NSNumber *tocLevel;

@end

@implementation TOCSectionCellView

- (id)init
{
    self = [super init];
    if (self) {
        self.tocLevel = @(0);
        self.sectionId = nil;
        
        self.sectionImageIds = @[];
        self.sectionImageViews = [@[] mutableCopy];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.numberOfLines = 10;
        self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        //self.titleLabel.layer.borderWidth = 1.0f;
        
        [self addSubview:self.titleLabel];
        
        self.indentMargin = 0.0f;
        self.indentMarginMin = 6.0f;

        self.imageIndentMargin = 0.0f;
        self.imageIndentMarginMin = 6.0f;

        self.imageMargin = 6.0f;
        self.imageSize = CGSizeMake(60.0f, 40.0f);

        self.isHighlighted = NO;
        
        self.clipsToBounds = YES;
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;

        //self.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.3f].CGColor;
        //self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

-(void)setIsHighlighted:(BOOL)isHighlighted
{
    if (isHighlighted) {
        self.backgroundColor = WMF_COLOR_BLUE;
    }else{
        self.backgroundColor = [UIColor darkGrayColor];
    }
    
    if (isHighlighted) self.alpha = 1.0f;
    
    _isHighlighted = isHighlighted;
}

-(NSAttributedString *)getAttributedStringForString:(NSString *)str isLeadSection:(BOOL)isLeadSection
{
    NSUInteger fontSize = (isLeadSection) ? 22 : 15;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    return [[NSMutableAttributedString alloc]
            initWithString:str attributes: @{
                                             NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                             NSParagraphStyleAttributeName : paragraphStyle,
                                             NSStrokeWidthAttributeName : @0.0f, //@-1.0f,
                                             NSStrokeColorAttributeName : [UIColor blackColor],
                                             NSForegroundColorAttributeName : [UIColor whiteColor],
                                             }];
}

-(NSAttributedString *)getAttributedTitleForSection:(Section *)section
{
    NSString *string = [section isLeadSection] ? section.article.title : section.title;
    
    string = [string getStringWithoutHTML];
    
    return [self getAttributedStringForString:string isLeadSection:[section isLeadSection]];
}

-(void)setSectionId:(NSManagedObjectID *)sectionId
{
    if (sectionId) {
        ArticleDataContextSingleton *articleDataContext_ = [ArticleDataContextSingleton sharedInstance];
        Section *section = (Section *)[articleDataContext_.mainContext objectWithID:sectionId];
        
        self.tag = section.sectionId.integerValue;

        self.titleLabel.attributedText = [self getAttributedTitleForSection:section];

        // Add tocLevel for debugging.
        //self.titleLabel.text = [NSString stringWithFormat:@"%@-%@ : %@", section.index, section.tocLevel, self.titleLabel.text];
        
        // Remove previous images.
        [self.sectionImageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.sectionImageViews removeAllObjects];

        if (self.sectionImageIds.count > 0) {
            [self addSectionImageViews];
            [self resetSectionImageViewsBorderStyle];
        }
//TODO: (maybe) if section index is 0 tack a toggle view on top of it (on right side) then hook up to animate changes to
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
        TOCImageView *imageView = [[TOCImageView alloc] init];
        // Tag will make it easy to take the tapped image and find its sectionImageId from sectionImageIds.
        imageView.tag = i; // Don't use this--> sectionImage.index.integerValue; (not all images are shown)
        i++;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;

        // Needed because sometimes these images have transparency.
        imageView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
        
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = [UIImage imageWithData:sectionImage.image.imageData.data];

        imageView.fileName = sectionImage.image.fileName;

        [self.sectionImageViews addObject:imageView];
        [self insertSubview:imageView belowSubview:self.titleLabel];
    }
}

-(void)updateConstraints
{
    [self removeConstraints:self.constraints];

    [self constrainTitleLabel:self.tocLevel];
    [self constrainSectionImagesBelowTitleLabel:self.tocLevel];

    // Experimental constraints:
    //[self constrainTitleLabelToLeftOfCell];
    //[self constrainSectionImagesFillingCell];
    //[self constrainSectionImagesFillingCellSideBySide];
    
    [super updateConstraints];
}

-(void)constrainSectionImagesBelowTitleLabel:(NSNumber *)tocLevel
{
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
        NSLayoutConstraint *constraint =
        [NSLayoutConstraint constraintWithItem: view1
                                     attribute: a1
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: view2
                                     attribute: a2
                                    multiplier: 1.0
                                      constant: constant];
        [self addConstraint:constraint];
    };

    TOCImageView *prevImage = nil;
    for (TOCImageView *imageView in self.sectionImageViews) {
        [imageView removeConstraintsOfViewFromView:self];

        imageView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

        // Default layout with horizontal row of images beneath title label.
        constrain(imageView, NSLayoutAttributeBottom, self, NSLayoutAttributeBottom, -self.imageMargin);
        constrain(imageView, NSLayoutAttributeWidth, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.width);
        constrain(imageView, NSLayoutAttributeHeight, nil, NSLayoutAttributeNotAnAttribute, self.imageSize.height);
        if (self.sectionImageViews.firstObject == imageView) {
            constrain(imageView, NSLayoutAttributeTop, self.titleLabel, NSLayoutAttributeBottom, self.imageMargin);
            constrain(imageView, NSLayoutAttributeLeft, self, NSLayoutAttributeLeft, (tocLevel.floatValue * self.imageIndentMargin) + self.imageIndentMarginMin);
        }
        if (prevImage) {
            constrain(imageView, NSLayoutAttributeLeft, prevImage, NSLayoutAttributeRight, self.imageMargin);
        }
        prevImage = imageView;

//TODO: hook up swapping out the constraints above to the constraits below to a toggle. Animate the transistion.
        continue;
        
        // Layout with vertically stacked image beneath title layout.
        self.imageSize = CGSizeMake(150.0f, 150.0f);
        constrain(imageView, NSLayoutAttributeCenterX, self, NSLayoutAttributeCenterX, 0);
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
    [self.titleLabel removeConstraintsOfViewFromView:self];

    void (^constrainTitleLabel)(NSLayoutAttribute, CGFloat) = ^void(NSLayoutAttribute a, CGFloat constant) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: self.titleLabel
                                      attribute: a
                                      relatedBy: NSLayoutRelationEqual
                                         toItem: self
                                      attribute: a
                                     multiplier: 1.0
                                       constant: constant];

        [self addConstraint:constraint];
    };
    
    NSInteger tocLevelToUse = ((self.tocLevel.intValue - 1) < 0) ? 0 : self.tocLevel.intValue - 1;
    constrainTitleLabel(NSLayoutAttributeLeft, (tocLevelToUse * self.indentMargin) + self.indentMarginMin);
    constrainTitleLabel(NSLayoutAttributeRight, -5);
    constrainTitleLabel(NSLayoutAttributeTop, 5);
    constrainTitleLabel(NSLayoutAttributeBottom, -5);

    // The label's instrinsic content size will keep it above "1" height. This allows labels above
    // images to be narrower vertically than a label for a section which has no images.
    CGFloat minTitleLabelHeight = (self.sectionImageViews.count > 0) ? 1 : 40;

    NSArray *constraints =
    [NSLayoutConstraint constraintsWithVisualFormat: @"V:[titleLabel(>=height)]"
                                            options: 0
                                            metrics: @{@"height": @(minTitleLabelHeight)}
                                              views: @{@"titleLabel": self.titleLabel}];
    [self addConstraints:constraints];
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

#pragma mark Experimental constraints

//Places images side by side - for example, 3 images would be 33.3% of cell width each.
-(void)constrainSectionImagesFillingCellSideBySide
{
    if(self.sectionImageViews.count == 0)return;

    void (^constrain)(UIView *, NSLayoutAttribute, NSLayoutRelation, UIView *, NSLayoutAttribute, CGFloat, CGFloat) = ^void(UIView *view1, NSLayoutAttribute a1, NSLayoutRelation relation, UIView *view2, NSLayoutAttribute a2, CGFloat multiplier, CGFloat constant) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: relation
                                         toItem: view2
                                      attribute: a2
                                     multiplier: multiplier
                                       constant: constant];
        [self addConstraint:constraint];
    };
    TOCImageView *prevImage = nil;
    for (TOCImageView *imageView in self.sectionImageViews) {
        [imageView removeConstraintsOfViewFromView:self];

        imageView.alpha = 0.5;

        constrain(imageView, NSLayoutAttributeWidth, NSLayoutRelationEqual, self, NSLayoutAttributeWidth, 1.0f / self.sectionImageViews.count, 0.0f);
        constrain(imageView, NSLayoutAttributeCenterY, NSLayoutRelationEqual, self, NSLayoutAttributeCenterY, 1.0f, 0.0f);
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(5)-[imageView]-(5)-|" options:0 metrics:nil views:@{@"imageView": imageView}];
        [self addConstraints:constraints];

        if (self.sectionImageViews.firstObject == imageView) {
            constrain(imageView, NSLayoutAttributeLeft, NSLayoutRelationEqual, self, NSLayoutAttributeLeft, 1.0f, 0.0f);
        }
        if (prevImage) {
            constrain(imageView, NSLayoutAttributeLeft, NSLayoutRelationEqual, prevImage, NSLayoutAttributeRight, 1.0f, 0.0f);
        }
        prevImage = imageView;
    }
}

-(void)constrainSectionImagesFillingCell
{
    if(self.sectionImageViews.count == 0)return;
    for (TOCImageView *imageView in self.sectionImageViews) {
        [imageView removeConstraintsOfViewFromView:self];

        imageView.alpha = (self.sectionImageViews.firstObject == imageView) ? 0.5f : 0.0f;
        NSArray *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(5)-[imageView]-(5)-|"
                                                options: 0
                                                metrics: nil
                                                  views: @{@"imageView": imageView}];
        [self addConstraints:constraints];

        constraints =
        [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-(5)-[imageView]-(5)-|"
                                                options: 0
                                                metrics: nil
                                                  views: @{@"imageView": imageView}];
        [self addConstraints:constraints];
    }
}

-(void)constrainTitleLabelToLeftOfCell
{
    void (^constrain)(UIView *, NSLayoutAttribute, NSLayoutRelation, UIView *, NSLayoutAttribute, CGFloat) = ^void(UIView *view1, NSLayoutAttribute a1, NSLayoutRelation relation, UIView *view2, NSLayoutAttribute a2, CGFloat constant) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: view1
                                      attribute: a1
                                      relatedBy: relation
                                         toItem: view2
                                      attribute: a2
                                     multiplier: 1.0
                                       constant: constant];
        [self addConstraint:constraint];
    };
    
    UIView *firstImage = nil;
    if(self.sectionImageViews.count > 0) firstImage = self.sectionImageViews[0];

    [self.titleLabel removeConstraintsOfViewFromView:self];
    
    NSInteger tocLevelToUse = ((self.tocLevel.intValue - 1) < 0) ? 0 : self.tocLevel.intValue - 1;
    constrain(self.titleLabel, NSLayoutAttributeLeft, NSLayoutRelationEqual, self, NSLayoutAttributeLeft, (tocLevelToUse * self.indentMargin) + self.indentMarginMin);
    constrain(self.titleLabel, NSLayoutAttributeRight, NSLayoutRelationEqual, self, NSLayoutAttributeRight, -5);
    constrain(self.titleLabel, NSLayoutAttributeTop, NSLayoutRelationEqual, self, NSLayoutAttributeTop, 5);
    constrain(self.titleLabel, NSLayoutAttributeBottom, NSLayoutRelationEqual, self, NSLayoutAttributeBottom, -5);
    
    NSArray *constraints =
    [NSLayoutConstraint constraintsWithVisualFormat: @"V:[titleLabel(>=height)]"
                                            options: 0
                                            metrics: @{@"height": @(40)}
                                              views: @{@"titleLabel": self.titleLabel}];
    [self addConstraints:constraints];
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
