
#import <AFNetworking/AFURLRequestSerialization.h>

@interface WMFArticleRequestSerializer : AFHTTPRequestSerializer

//Set this to specify if this particular tracking header shold be sent.
//Note: internal logic only allows this to be sent once per session
@property (nonatomic, assign) BOOL shouldSendMCCMNCheader;

@end
