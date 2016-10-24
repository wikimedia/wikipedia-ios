#import "WMFContentGroup.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *date;

@end

@implementation WMFContentGroup

+ (NSString *)kind {
    return NSStringFromClass([self class]);
}

- (instancetype)init {
    return [self initWithDate:[NSDate date]];
}

- (instancetype)initWithDate:(NSDate *)date {
    NSParameterAssert(date);
    self = [super init];
    if (self) {
        self.date = date;
    }
    return self;
}

- (WMFContentType)contentType {
    return WMFContentTypeURL;
}


@end

@interface WMFSiteContentGroup ()

@property (nonatomic, strong, readwrite) NSURL *siteURL;

@end

@implementation WMFSiteContentGroup

- (instancetype)initWithSiteURL:(NSURL *)url {
    return [self initWithDate:[NSDate date] siteURL:url];
}

- (instancetype)initWithDate:(NSDate *)date siteURL:(NSURL *)url {
    NSParameterAssert(date);
    self = [super initWithDate:date];
    if (self) {
        self.siteURL = url;
    }
    return self;
}
@end

@implementation WMFContinueReadingContentGroup


@end

@implementation WMFMainPageContentGroup

@end

@interface WMFRelatedPagesContentGroup ()

@property (nonatomic, strong, readwrite) NSURL *articleURL;

@end

@implementation WMFRelatedPagesContentGroup

- (instancetype)initWithArticleURL:(NSURL *)url date:(NSDate *)date {
    self = [super initWithDate:date siteURL:url.wmf_siteURL];
    if (self) {
        self.articleURL = url;
    }
    return self;
}

@end

@interface WMFLocationContentGroup ()

@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) CLPlacemark *placemark;
@end

@implementation WMFLocationContentGroup

- (instancetype)initWithLocation:(CLLocation *)location placemark:(nullable CLPlacemark *)placemark siteURL:(NSURL *)url {
    self = [super initWithSiteURL:url];
    if (self) {
        self.location = location;
        self.placemark = placemark;
    }
    return self;
}

@end

@implementation WMFPictureOfTheDayContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeImage;
}

@end

@implementation WMFRandomContentGroup


@end

@implementation WMFFeaturedArticleContentGroup

@end

@interface WMFTopReadContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *mostReadDate;

@end
@implementation WMFTopReadContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeTopReadPreview;
}

- (instancetype)initWithDate:(NSDate *)date mostReadDate:(NSDate *)mostReadDate siteURL:(NSURL *)url {
    NSParameterAssert(mostReadDate);
    self = [super initWithDate:date siteURL:url];
    if (self) {
        self.mostReadDate = mostReadDate;
    }
    return self;
}

@end

@implementation WMFNewsContentGroup

- (WMFContentType)contentType {
    return WMFContentTypeStory;
}

@end

NS_ASSUME_NONNULL_END
