#import "Nocilla.h"

typedef LSStubResponseDSL * (^WithJSONMethod)(id json);

@interface LSStubResponseDSL (WithJSON)

@property (nonatomic, strong, readonly) WithJSONMethod withJSON;

@end
