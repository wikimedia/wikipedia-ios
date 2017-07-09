
#import "WMFMedia.h"
@import WMF;

NSString *const API_URL = @"https://en.wikipedia.org/w/api.php?action=query&titles=%@&prop=videoinfo&viprop=derivatives&format=json";

@interface WMFMedia ()
@property (nonatomic) NSURLSessionTask *apiTask;
@property (nonatomic, readwrite) NSArray<WMFMediaObject *> *sortedMediaObjects;
@property (nonatomic, weak) id<WMFMediaDelegate> delegate;
@end

@interface WMFMediaObject ()
@property (nonatomic, readwrite) NSURL *url;
@property (nonatomic, readwrite) NSInteger bandwidth;
@property (nonatomic, readwrite) NSInteger width;
@property (nonatomic, readwrite) NSInteger height;
- (instancetype)initWithJSON:(NSDictionary *)json;
@end

@interface WMFMediaJSONParser : NSObject
- (NSArray<WMFMediaObject *> *)translateToMediaObjects:(NSData *)apiResponse;
@end

#pragma mark - media container

@implementation WMFMedia

- (instancetype)initWithJSONData:(NSData *)json {
    if (self = [super init]) {
        _sortedMediaObjects = [[WMFMediaJSONParser alloc] translateToMediaObjects:json];
        if (!_sortedMediaObjects) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithTitles:(NSString *)titles withAsyncDelegate:(id<WMFMediaDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _apiTask = [self createURLSessionTaskFor:titles];
        [_apiTask resume];
    }
    return self;
}

- (WMFMediaObject *)lowQualityMediaObject {
    return self.sortedMediaObjects.firstObject;
}

- (WMFMediaObject *)highQualityMediaObject {
    return self.sortedMediaObjects.lastObject;
}

- (NSURLSessionTask *)createURLSessionTaskFor:(NSString *)titles {
    NSString *urlString = [NSString stringWithFormat:API_URL, titles];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    @weakify(self)
        NSURLSessionDataTask *apiTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                            @strongify(self)
                                                                                [self handleApiResponse:data];
                                                                            self.apiTask = nil;
                                                                        }];
    apiTask.priority = NSURLSessionTaskPriorityLow;
    return apiTask;
}

- (void)handleApiResponse:(NSData *)apiResponse {
    if (apiResponse) {
        self.sortedMediaObjects = [[WMFMediaJSONParser alloc] translateToMediaObjects:apiResponse];
        if (self.sortedMediaObjects) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate wmf_MediaSuccess:self];
            });
            return;
        }
    }
    [self.delegate wmf_MediaFailed:self];
}

- (void)dealloc {
    [self.apiTask cancel];
}

@end

@implementation WMFMediaJSONParser

- (NSArray<WMFMediaObject *> *)translateToMediaObjects:(NSData *)apiResponse {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:apiResponse options:0 error:&error];
    if (json) {
        NSMutableArray<WMFMediaObject *> *mediaObjs = [self extractDerivatives:json];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"bandwidth" ascending:YES];
        [mediaObjs sortUsingDescriptors:@[sort]];
        return mediaObjs;
    } else
        return nil;
}

- (NSMutableArray<WMFMediaObject *> *)extractDerivatives:(id)json {
    id query = [json objectForKey:@"query"];
    id pages = [query objectForKey:@"pages"];
    id page = [[pages allValues] firstObject];
    id videoinfo = [page objectForKey:@"videoinfo"];
    NSMutableArray<WMFMediaObject *> *mediaObjs = [NSMutableArray array];
    for (id info in videoinfo) {
        id derivatives = [info objectForKey:@"derivatives"];
        for (id derivative in derivatives) {
            WMFMediaObject *obj = [[WMFMediaObject alloc] initWithJSON:derivative];
            if (obj) {
                [mediaObjs addObject:obj];
            } else {
                return nil;
            }
        }
    }
    return mediaObjs;
}

@end

#pragma mark - media file

@implementation WMFMediaObject

- (instancetype)initWithJSON:(NSDictionary *)derivative {
    if ([super init]) {
        _url = [NSURL URLWithString:[derivative objectForKey:@"src"]];
        if (!_url) {
            return nil;
        }
        _bandwidth = [[derivative objectForKey:@"bandwidth"] integerValue];
        _height = [[derivative objectForKey:@"height"] integerValue];
        _width = [[derivative objectForKey:@"width"] integerValue];
    }
    return self;
}

@end
