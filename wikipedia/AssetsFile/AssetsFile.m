//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AssetsFile.h"

@interface AssetsFile()

@property (nonatomic) AssetsFileEnum file;

@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSString *path;

@property (nonatomic, retain) NSArray *array;

@property (nonatomic, retain) NSDictionary *dictionary;

@property (nonatomic, retain) NSURL *url;

@property (nonatomic, retain) NSData *data;

@property (nonatomic, retain) NSString *documentsAssetsPath;

@end

@implementation AssetsFile

-(NSString *)name
{
    switch (self.file) {
        case ASSETS_FILE_CONFIG:
            return @"ios.json";
            break;
        case ASSETS_FILE_LANGUAGES:
            return @"languages.json";
            break;
        case ASSETS_FILE_MAINPAGES:
            return @"mainpages.json";
            break;
        case ASSETS_FILE_CSS:
            return @"styles.css";
            break;
        case ASSETS_FILE_CSS_ABUSE_FILTER:
            return @"abusefilter.css";
            break;
        case ASSETS_FILE_CSS_PREVIEW:
            return @"preview.css";
            break;
        default:
            return ASSETS_FILE_UNDEFINED;
            break;
    }
}

- (NSURL *)url
{
    NSString *urlString = @"";
    switch (self.file) {
        case ASSETS_FILE_CONFIG:
            urlString = @"https://bits.wikimedia.org/static-current/extensions/MobileApp/config/ios.json";
            break;
        case ASSETS_FILE_CSS:
            urlString = @"https://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&lang=en&modules=mobile.app.pagestyles.ios&only=styles&skin=vector";
            break;
        case ASSETS_FILE_CSS_ABUSE_FILTER:
            urlString = @"https://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&lang=en&modules=mobile.app.pagestyles.ios&only=styles&skin=vector";
            break;
        case ASSETS_FILE_CSS_PREVIEW:
            urlString = @"https://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&lang=en&modules=mobile.app.preview&only=styles&skin=vector";
            break;
        default:
            break;
    }
    
    return [NSURL URLWithString:urlString];
}

- (id)initWithFile:(AssetsFileEnum)file
{
    self = [super init];
    if (self) {
        NSArray *documentsPath = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsAssetsPath = [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
        self.file = file;
        NSError *error = nil;
        self.data = [NSData dataWithContentsOfFile:self.path options:0 error:&error];
        if (error) {
            self.data = nil;
        }
    }
    return self;
}

- (NSDictionary *)dictionary
{
    if (!self.data) return @{};
    NSError *error = nil;
    NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
    return (error) ? @{}: result;
}

- (NSArray *)array
{
    if (!self.data) return @[];
    NSError *error = nil;
    NSArray *result = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
    return (error) ? @[]: result;
}

// Returns YES if the local version of the config file doesn't exist or is older than maxAge.
- (BOOL)isOlderThan:(CGFloat)maxAge
{
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];
    if (!fileExists){
        NSLog(@"REFRESH NEEDED");
        return YES;
    }
    
    NSDate *lastModified = nil;
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:self.path];
    [url getResourceValue: &lastModified
                   forKey: NSURLContentModificationDateKey
                    error: &error];
    if (!error){
        NSTimeInterval currentAge = [[NSDate date] timeIntervalSinceDate:lastModified];
        NSLog(@"currentAge = %f maxAge = %f", currentAge, maxAge);
        if (currentAge > maxAge){
            NSLog(@"REFRESH NEEDED");
            return YES;
        }
    }
    NSLog(@"NO REFRESH NEEDED");
    return NO;
}

- (NSString *)path
{
    return [self.documentsAssetsPath stringByAppendingPathComponent:self.name];
}

@end
