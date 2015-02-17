//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageContainer.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "MWKSection+DisplayHtml.h"
#import "CommunicationBridge.h"
#import "NSObject+ConstraintsScale.h"
#import "LeadImageTitleLabel.h"
#import "UIScreen+Extras.h"
#import "QueuesSingleton.h"
#import "FocalImage.h"
#import "MWKArticle+isMain.h"
#import "UIView+Debugging.h"

#define PLACEHOLDER_IMAGE_ALPHA 0.3f

/*
When YES this causes lead image faces to be highlighted in green and
simulator "Command-Shift-M" taps to cycle through the faces, shifting 
the image to best center the currently hightlighted face.
Do *not* leave this set to YES for release.
*/
#if DEBUG
#define HIGHLIGHT_FOCAL_FACE 0
#else
// disable in release builds
#define HIGHLIGHT_FOCAL_FACE 0
#endif

@interface LeadImageContainer()

@property (weak, nonatomic) IBOutlet UIView *titleDescriptionContainer;
@property (weak, nonatomic) IBOutlet LeadImageTitleLabel *titleLabel;
@property (strong, nonatomic) FocalImage *image;
@property (nonatomic) CGRect focalFaceBounds;
@property(strong, nonatomic) MWKArticle *article;
@property (nonatomic) BOOL isPlaceholder;
@property(strong, nonatomic)id rotationObserver;
@property (nonatomic) CGFloat height;

@end

@implementation LeadImageContainer

-(void)awakeFromNib
{
    self.height = LEAD_IMAGE_CONTAINER_HEIGHT;
    self.isPlaceholder = NO;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    [self adjustConstraintsScaleForViews:@[self.titleLabel]];

    self.rotationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName: UIDeviceOrientationDidChangeNotification
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *notification) {
                                                      
                                                      [self updateNonImageElements];
                                                      
                                                  }];
    #if HIGHLIGHT_FOCAL_FACE
    // Testing code so we can hit "Command-Shift-M" to toggle through focal images.
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationDidReceiveMemoryWarningNotification
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *note) {

                                                      // Repeated calls to getFaceBounds returns next face bounds each time.
                                                      self.focalFaceBounds = [self.image getFaceBounds];
                                                      [self setNeedsDisplay];

                                                  }];
    #endif

    // Important! "clipsToBounds" must be "NO" so super long titles lay out properly!
    self.clipsToBounds = NO;

    //[self randomlyColorSubviews];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.rotationObserver];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if([self shouldHideImage]) return;
    if((self.image.size.width == 0) || (self.image.size.height == 0))return;

    // Draw gradient first so when image is drawn with kCGBlendModeMultiply
    // the gradient will look smooth.
    [self drawGradientBackground];

    CGFloat alpha = self.isPlaceholder ? PLACEHOLDER_IMAGE_ALPHA : 1.0;

    // Draw lead image, aspect fill, align top, vertically centering
    // focalFaceBounds face if necessary.
    [self.image drawInRect: rect
               focalBounds: self.focalFaceBounds
            focalHighlight: HIGHLIGHT_FOCAL_FACE
                 blendMode: kCGBlendModeMultiply
                     alpha: alpha];
}

-(void)drawGradientBackground
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    void (^drawGradient)(CGFloat, CGFloat, CGRect) = ^void(CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
        CGFloat locations[] = {
            0.0,  // Upper color stop.
            1.0   // Bottom color stop.
        };
        CGFloat colorComponents[8] = {
            0.0, 0.0, 0.0, upperAlpha,  // Upper color.
            0.0, 0.0, 0.0, bottomAlpha  // Bottom color.
        };
        CGGradientRef gradient =
        CGGradientCreateWithColorComponents(colorSpace, colorComponents, locations, 2);
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGPoint endPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGGradientRelease(gradient);
    };
    
    // Note: the gradient is purposely drawn in 2 parts. One part for the label, and one
    // for the part above the label. This is done instead of adding multiple locations
    // to a single gradient because it allows the part above the label to fade to
    // transparent at the top in a way that doesn't darken the part above the label as
    // much as a single multiple location gradient. If you tweak anything about this, be
    // sure to test before/after w/ light background images to make sure things aren't
    // darkened too much.

    CGFloat alphaTop = 0.0;
    CGFloat alphaMid = 0.1;
    CGFloat alphaBottom = 0.5;

    CGFloat aboveLabelY = self.frame.size.height - self.titleDescriptionContainer.frame.size.height;

    // Shift the meeting point of the 2 gradients up a bit.
    CGFloat centerlineDrift = -aboveLabelY / 3.0;
    
    CGFloat meetingY = aboveLabelY + centerlineDrift;

    // Draw gradient fading black of alpha 0.0 at top of image to black at alpha 0.4 at top of label.
    CGRect topGradientRect =
        (CGRect){
            {0, 0},
            {self.titleDescriptionContainer.frame.size.width, meetingY}
        };
    drawGradient(alphaTop, alphaMid, topGradientRect);
    
    // Draw gradient fading black of alpha 0.4 at top of label to black at alpha 1.0 at bottom of label.
    CGRect bottomGradientRect =
        (CGRect){
            {self.titleDescriptionContainer.frame.origin.x, meetingY},
            {self.titleDescriptionContainer.frame.size.width, self.titleDescriptionContainer.frame.size.height - centerlineDrift}
        };
    drawGradient(alphaMid, alphaBottom, bottomGradientRect);
    
    CGColorSpaceRelease(colorSpace);
}

-(void)updateNonImageElements
{
    // Updates title/description text color.
    [self updateTitleColors];
    
    // Updates height of this view and of the webView's placeholer div.
    [self updateHeights];

    [self setNeedsDisplay];
}

-(void)updateHeights
{
    // First update title/description and container layout so correct
    // dimensions are available for current title and description text.
    [self.titleLabel layoutIfNeeded];
    [self.titleDescriptionContainer layoutIfNeeded];

    self.height = ([self shouldHideImage]) ? self.titleDescriptionContainer.frame.size.height : LEAD_IMAGE_CONTAINER_HEIGHT;

    // Notify the layout system that the height has changed.
    [self invalidateIntrinsicContentSize];

    // Now notify the web view of the height change.
    [self.delegate leadImageHeightChangedTo:@(self.height)];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

-(void)updateTitleColors
{
    UIColor *textColor = [UIColor whiteColor];
    UIColor *shadowColor = [UIColor colorWithWhite:0.0f alpha:0.08];
    //shadowColor = [UIColor redColor]; // Use for testing shadow

    if ([self shouldHideImage]) {
        textColor = [UIColor blackColor];
        shadowColor = [UIColor clearColor];
    }

    self.titleLabel.textColor = textColor;
    self.titleLabel.shadowColor = shadowColor;
}

-(BOOL)shouldHideImage
{
    return
        UIInterfaceOrientationIsLandscape([[UIScreen mainScreen] interfaceOrientation])
        ||
        ![self imageExists];
}

-(BOOL)imageExists
{
    return (!self.article.isMain && self.article.imageURL && ![self isGifUrl:self.article.imageURL]) ? YES : NO;
}

-(BOOL)isGifUrl:(NSString *)url
{
    return (url.pathExtension && [url.pathExtension isEqualToString:@"gif"]) ? YES : NO;
}

-(void)showForArticle:(MWKArticle *)article
{
    self.article = article;
    self.focalFaceBounds = CGRectZero;

    self.titleLabel.imageExists = [self imageExists];
    
    if (self.article.isMain) {
        [self.titleLabel setTitle:@"" description:@""];
    }else{
        NSString *title = [self.article.displaytitle getStringWithoutHTML];
        [self.titleLabel setTitle:title description:[self getCurrentArticleDescription]];
    }

    if (!self.article.image.asUIImage && [self imageExists]) {
        
        [self loadPlaceholderImage];
        
        (void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL: [@"http:" stringByAppendingString: self.article.imageURL]
                                                         withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                                  thenNotifyDelegate: self];
    }else{
        [self showImage];
    }
}

-(void)loadPlaceholderImage
{
    FocalImage *placeholderImage =
        [[FocalImage alloc] initWithCGImage:[UIImage imageNamed:@"lead-default"].CGImage];
    self.isPlaceholder = YES;
    self.image = placeholderImage;
    [self updateNonImageElements];
}

-(void)showImage
{
    UIImage *img = self.article.image.asUIImage;

    FocalImage *image = [[FocalImage alloc] initWithCGImage:img.CGImage];

    // Biggest face.
    self.focalFaceBounds = [image getFaceBounds];

    //NSLog(@"Requested lead image width = %d", LEAD_IMAGE_WIDTH);
    //NSLog(@"Returned lead image width = %d", self.article.image.width.integerValue);
    //NSLog(@"percent = %f", self.article.image.width.floatValue / LEAD_IMAGE_WIDTH);

    /*
     Note: this doesn't work as-is. Would need to listen for "SectionImageRetrieved"
     notifications because article images are late-arriving.
    
     Use first article image if no image at this point.
     
     Should probably only do this if the image above is going to be greatly
     cropped *and* no faces were detected. Then, instead of loading first image
     of minimum size, as noted below, use first image of sufficient area which
     would not need to be aggresively cropped.
     
     Note: commented this out because I'm not sure it ever gets called.
     Would also probably want to only use the first article image if it's
     bigger than some minimum size.

    if(!img){
        MWKImage *firstArticleImage = self.article.sections[0].images[0];
        UIImage *firstUIImage = firstArticleImage.asUIImage;
        if(firstUIImage){
            img = firstUIImage;
        }
    }
    */

    self.isPlaceholder = NO;
    self.image = image;
    
    [self updateNonImageElements];
}

- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[ThumbnailFetcher class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                // Associate the image retrieved with article.image.
                ThumbnailFetcher *fetcher = (ThumbnailFetcher *)sender;
                NSString *thumbnailURL = [fetcher.url getUrlWithoutScheme];
                
                MWKImage *articleImage = [[MWKImage alloc] initWithArticle:self.article sourceURL:thumbnailURL];
                [articleImage importImageData:fetchedData];
                
                [self showImage];
            }
                break;
            case FETCH_FINAL_STATUS_FAILED:
            {
                
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
                
            }
                break;
        }
    }
}

-(NSString *)getCurrentArticleDescription
{
    NSString *description = self.article.entityDescription;
    if (description) {
        description = [self.article.entityDescription getStringWithoutHTML];
        description = [description capitalizeFirstLetter];
    }
    return description;
}

@end
