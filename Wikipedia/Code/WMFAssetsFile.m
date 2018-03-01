#import <WMF/WMFAssetsFile.h>
#import <WMF/WikipediaAppUtils.h>

@interface WMFAssetsFile ()

@property (nonatomic) WMFAssetsFileType fileType;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, strong, readwrite) NSDictionary *dictionary;

@property (nonatomic, strong, readwrite) NSArray *array;

@end

@implementation WMFAssetsFile

- (id)initWithFileType:(WMFAssetsFileType)file {
    self = [super init];
    if (self) {
        self.fileType = file;
    }
    return self;
}

- (NSString *)documentsAssetsPath {
    return [WikipediaAppUtils assetsPath];
}

- (NSString *)path {
    return [[self documentsAssetsPath] stringByAppendingPathComponent:self.name];
}

- (NSData *)data {
    if (!_data) {
        _data = [NSData dataWithContentsOfFile:self.path options:0 error:nil];
    }
    return _data;
}

- (NSDictionary *)dictionary {
    if (!_dictionary && self.data) {
        NSError *error = nil;
        _dictionary = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
        if (![_dictionary isKindOfClass:[NSDictionary class]]) {
            _dictionary = nil;
        }
    }
    return _dictionary;
}

- (NSArray *)array {
    if (!_array && self.data) {
        NSError *error = nil;
        _array = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
        NSAssert([_array isKindOfClass:[NSArray class]], @"Expected array, got %@", _array);
        NSAssert(!error, @"Unexpected JSON error: %@", error);
        if (![_array isKindOfClass:[NSArray class]]) {
            _array = nil;
        }
    }
    return _array;
}

- (NSString *)name {
    switch (self.fileType) {
        case WMFAssetsFileTypeLanguages:
            return @"languages.json";
        case WMFAssetsFileTypeMainPages:
            return @"mainpages.json";
        default:
            return nil;
    }
}

- (BOOL)isOlderThan:(NSTimeInterval)maxAge {
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:NULL];

    if (!fileExists) {
        return YES;
    }

    NSDate *lastModified = nil;
    NSError *error = nil;
    NSURL *url = [NSURL fileURLWithPath:self.path];

    [url getResourceValue:&lastModified
                   forKey:NSURLContentModificationDateKey
                    error:&error];
    if (!error) {
        NSTimeInterval currentAge = [[NSDate date] timeIntervalSinceDate:lastModified];
        if (currentAge > maxAge) {
            return YES;
        }
    }
    return NO;
}

@end
