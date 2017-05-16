#import "WikiTextSectionUploader.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

@interface WikiTextSectionUploader ()

@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) NSURL *articleURL;
@property (strong, nonatomic) NSString *section;
@property (strong, nonatomic) NSString *summary;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaWord;
@property (strong, nonatomic) NSString *token;

@end

@implementation WikiTextSectionUploader

- (instancetype)initAndUploadWikiText:(NSString *)wikiText
                        forArticleURL:(NSURL *)articleURL
                              section:(NSString *)section
                              summary:(NSString *)summary
                            captchaId:(NSString *)captchaId
                          captchaWord:(NSString *)captchaWord
                                token:(NSString *)token
                          withManager:(AFHTTPSessionManager *)manager
                   thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
    NSParameterAssert(articleURL.wmf_title);
    self = [super init];
    if (self) {
        self.wikiText = wikiText ? wikiText : @"";
        self.articleURL = articleURL;
        self.section = section ? section : @"";
        self.summary = summary ? summary : @"";
        self.captchaId = captchaId ? captchaId : @"";
        self.captchaWord = captchaWord ? captchaWord : @"";
        self.token = token ? token : @"";

        self.fetchFinishedDelegate = delegate;
        [self uploadWithManager:manager];
    }
    return self;
}

- (void)uploadWithManager:(AFHTTPSessionManager *)manager {
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.articleURL.wmf_language];

    NSDictionary *params = [self getParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString
        parameters:params
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            //NSLog(@"JSON: %@", responseObject);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            // Fake out an error if non-dictionary response received.
            if (![responseObject isDict]) {
                responseObject = @{ @"error": @{@"info": @"WikiText upload data not found."} };
            }

            //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);

            // Handle case where response is received, but API reports error.
            NSError *error = nil;
            if (responseObject[@"error"]) {
                NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                error = [NSError errorWithDomain:@"WikiText Uploader"
                                            code:WIKITEXT_UPLOAD_ERROR_SERVER
                                        userInfo:errorDict];
            }

            NSDictionary *resultDict = responseObject[@"edit"];
            NSString *result = resultDict[@"result"];

            if (!error && !result) {
                NSMutableDictionary *errorDict = [@{} mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = WMFLocalizedStringWithDefaultValue(@"wikitext-upload-result-unknown", nil, nil, @"Unable to determine wikitext upload result.", @"Alert text shown when the result of saving section wikitext changes is unknown");

                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_UNKNOWN userInfo:errorDict];
            }

            if (!error && result && [result isEqualToString:@"Failure"]) {
                if (responseObject[@"edit"][@"captcha"]) {
                    NSMutableDictionary *errorDict = [@{} mutableCopy];

                    errorDict[NSLocalizedDescriptionKey] = (self.captchaWord && (self.captchaWord.length > 0)) ? WMFLocalizedStringWithDefaultValue(@"wikitext-upload-captcha-error", nil, nil, @"CAPTCHA verification error.", @"Alert text shown when section wikitext upload captcha fails")
                                                                                                               : WMFLocalizedStringWithDefaultValue(@"wikitext-upload-captcha-needed", nil, nil, @"Need CAPTCHA verification.", @"Alert text shown when section wikitext upload captcha is required");

                    // Make the capcha id and url available from the error.
                    errorDict[@"captchaId"] = responseObject[@"edit"][@"captcha"][@"id"];
                    errorDict[@"captchaUrl"] = responseObject[@"edit"][@"captcha"][@"url"];

                    // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                    error = [NSError errorWithDomain:@"Upload Wikitext Op" code:WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA userInfo:errorDict];
                } else if (responseObject[@"edit"][@"code"]) {
                    NSString *abuseFilterCode = responseObject[@"edit"][@"code"];
                    WikiTextSectionUploaderErrors errorType = WIKITEXT_UPLOAD_ERROR_UNKNOWN;

                    if ([abuseFilterCode hasPrefix:@"abusefilter-warning"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter-disallowed"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED;
                    } else if ([abuseFilterCode hasPrefix:@"abusefilter"]) {
                        errorType = WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER;
                    }

                    switch (errorType) {
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED:
                        case WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER: {
                            NSMutableDictionary *errorDict = [@{} mutableCopy];

                            errorDict[NSLocalizedDescriptionKey] = responseObject[@"edit"][@"info"];

                            // Make the verbose warning available from the error.
                            errorDict[@"warning"] = responseObject[@"edit"][@"warning"];
                            errorDict[@"code"] = abuseFilterCode;

                            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                            error = [NSError errorWithDomain:@"Upload Wikitext Op" code:errorType userInfo:errorDict];
                        } break;

                        default:
                            break;
                    }
                }
            }

            [self finishWithError:error
                      fetchedData:resultDict];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {

            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            [self finishWithError:error
                      fetchedData:nil];
        }];
}

- (NSMutableDictionary *)getParams {
    NSParameterAssert(self.token);
    NSAssert(self.token.length > 0, @"Expected token length greater than zero");
    NSMutableDictionary *params =
        @{
            @"action": @"edit",
            @"token": self.token,
            @"text": self.wikiText,
            @"summary": self.summary,
            @"section": self.section,
            @"title": self.articleURL.wmf_title,
            @"format": @"json"
        }.mutableCopy;

    if (self.captchaWord) {
        params[@"captchaid"] = self.captchaId;
        params[@"captchaword"] = self.captchaWord;
    }

    return params;
}

@end
