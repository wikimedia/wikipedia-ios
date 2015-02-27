//
//  MWKImage.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "WikipediaAppUtils.h"
#import "MediaWikiKit.h"
#import "WMFImageURLParsing.h"

@implementation MWKImage
@synthesize fileNameNoSizePrefix = _fileNameNoSizePrefix;

- (instancetype)initWithArticle:(MWKArticle*)article sourceURL:(NSString*)url {
    self = [super initWithSite:article.site];
    if (self) {
        _article = article;

        // fileNameNoSizePrefix is lazily derived from this property, so be careful if _sourceURL needs to be re-set
        _sourceURL = [url copy];

        _dateLastAccessed = nil;
        _dateRetrieved    = nil;
        _mimeType         = nil;
        _width            = nil;
        _height           = nil;
    }
    return self;
}

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict {
    NSString* sourceURL = [self requiredString:@"sourceURL" dict:dict];
    self = [self initWithArticle:article sourceURL:sourceURL];
    if (self) {
        _dateLastAccessed = [self optionalDate:@"dateLastAccessed" dict:dict];
        _dateRetrieved    = [self optionalDate:@"dateRetrieved" dict:dict];
        _mimeType         = [self optionalString:@"mimeType" dict:dict];
        _width            = [self optionalNumber:@"width" dict:dict];
        _height           = [self optionalNumber:@"height" dict:dict];
    }
    return self;
}

- (NSString*)extension {
    return [self.sourceURL pathExtension];
}

- (NSString*)fileName {
    return [self.sourceURL lastPathComponent];
}

- (NSString*)basename {
    NSArray* sourceURLComponents = [self.sourceURL componentsSeparatedByString:@"/"];
    NSParameterAssert(sourceURLComponents.count >= 2);
    return sourceURLComponents[sourceURLComponents.count - 2];
}

- (NSString*)canonicalFilename {
    return WMFNormalizedPageTitle([self canonicalFilenameFromSourceURL]);
}

- (NSString*)canonicalFilenameFromSourceURL {
    return [MWKImage canonicalFilenameFromSourceURL:self.sourceURL];
}

+ (NSString*)fileNameNoSizePrefix:(NSString*)sourceURL {
    return WMFParseImageNameFromSourceURL(sourceURL);
}

+ (NSString*)canonicalFilenameFromSourceURL:(NSString*)sourceURL {
    return [[self fileNameNoSizePrefix:sourceURL] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSInteger)fileSizePrefix:(NSString*)sourceURL {
    NSString* fileName = [sourceURL lastPathComponent];
    if (!fileName) {
        return -1;
    }
    NSError* error          = nil;
    NSRegularExpression* re = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+)px-" options:0 error:&error];
    NSArray* matches        = [re matchesInString:fileName options:0 range:NSMakeRange(0, [fileName length])];
    if (!error && [matches count]) {
        return [[fileName substringWithRange:[matches[0] rangeAtIndex:0]] intValue];
    } else {
        return -1;
    }
}

- (NSString*)fileNameNoSizePrefix {
    if (!_fileNameNoSizePrefix) {
        _fileNameNoSizePrefix = [MWKImage fileNameNoSizePrefix:self.sourceURL];
    }
    return _fileNameNoSizePrefix;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict[@"sourceURL"] = self.sourceURL;
    if (self.dateLastAccessed) {
        dict[@"dateLastAccessed"] = [self iso8601DateString:self.dateLastAccessed];
    }
    if (self.dateRetrieved) {
        dict[@"dateRetrieved"] = [self iso8601DateString:self.dateRetrieved];
    }
    if (self.mimeType) {
        dict[@"mimeType"] = self.mimeType;
    }
    if (self.width) {
        dict[@"width"] = self.width;
    }
    if (self.height) {
        dict[@"height"] = self.height;
    }

    return [dict copy];
}

- (void)importImageData:(NSData*)data {
    [self.article.dataStore saveImageData:data image:self];
}

- (void)updateWithData:(NSData*)data {
    _dateRetrieved    = [[NSDate alloc] init];
    _dateLastAccessed = [[NSDate alloc] init];
    _mimeType         = [self getImageMimeTypeForExtension:self.extension];

#warning TODO(bgerstle): get width & height info w/o expensively inflating the image data and then throwing it away
    UIImage* img = [UIImage imageWithData:data scale:1.0];
    _width  = [NSNumber numberWithInt:img.size.width];
    _height = [NSNumber numberWithInt:img.size.height];
}

- (NSString*)getImageMimeTypeForExtension:(NSString*)extension {
    NSString* lowerCaseSelf = [extension lowercaseString];
    if ([lowerCaseSelf isEqualToString:@"jpg"]) {
        return @"image/jpeg";
    }
    if ([lowerCaseSelf isEqualToString:@"jpeg"]) {
        return @"image/jpeg";
    }
    if ([lowerCaseSelf isEqualToString:@"png"]) {
        return @"image/png";
    }
    if ([lowerCaseSelf isEqualToString:@"gif"]) {
        return @"image/gif";
    }
    return @"";
}

- (void)updateLastAccessed {
    _dateLastAccessed = [[NSDate alloc] init];
}

- (void)save {
    [self.article.dataStore saveImage:self];
}

- (UIImage*)asUIImage {
    NSData* imageData = [self.article.dataStore imageDataWithImage:self];
    return [UIImage imageWithData:imageData scale:1.0];
}

- (NSData*)asNSData {
    return [self.article.dataStore imageDataWithImage:self];
}

- (MWKImage*)largestVariant {
    NSString* largestURL = [self.article.images largestImageVariant:self.sourceURL];
    return [self.article imageWithURL:largestURL];
}

- (MWKImage*)largestCachedVariant {
    return [self.article.images largestImageVariantForURL:self.sourceURL cachedOnly:YES];
}

- (BOOL)isCached {
    NSString* fullPath = [self fullImageBinaryPath];
    BOOL fileExists    = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
    return fileExists;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKImage class]]) {
        return [self isEqualToImage:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToImage:(MWKImage*)image {
    return self == image || [self.fileName isEqualToString:image.fileName];
}

- (NSUInteger)hash {
    return [self.fileName hash];
}

- (BOOL)isVariantOfImage:(MWKImage*)otherImage {
    // !!!: this might not be reliable due to underscore, percent encodings, and other unknowns w/ image filenames
    return [self.fileNameNoSizePrefix isEqualToString:otherImage.fileNameNoSizePrefix]
           && ![self isEqualToImage:otherImage];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ article: %@ sourceURL: %@",
            [super description], self.article.title, self.sourceURL];
}

- (NSString*)fullImageBinaryPath {
    NSString* path     = [self.article.dataStore pathForImage:self];
    NSString* fileName = [@"Image" stringByAppendingPathExtension:self.extension];
    NSString* filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
