//  Created by Jaikumar Bhambhwani on 11/10/12.

@interface NSURLRequest (DictionaryRequest)

+ (NSURLRequest *)postRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
+ (NSURLRequest *)getRequestWithURL:(NSURL *)url
                          parameters:(NSDictionary *)parameters;
@end
