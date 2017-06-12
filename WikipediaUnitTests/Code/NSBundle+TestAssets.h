@interface NSBundle (TestAssets)

- (NSString *)wmf_stringFromContentsOfFile:(NSString *)filename ofType:(NSString *)type;

- (NSData *)wmf_dataFromContentsOfFile:(NSString *)filename ofType:(NSString *)type;

- (id)wmf_jsonFromContentsOfFile:(NSString *)filename;

@end
