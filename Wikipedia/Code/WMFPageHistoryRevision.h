#import <WMF/WMFMTLModel.h>

@interface WMFPageHistoryRevision : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *_Nullable user;
@property (nonatomic, copy, readonly) NSDate *_Nullable revisionDate;
@property (nonatomic, copy, readonly) NSString *_Nullable parsedComment;
@property (nonatomic, assign, readonly) BOOL isAnon;
@property (nonatomic, assign, readonly) BOOL isMinor;
@property (nonatomic, assign, readonly) NSInteger parentID;
@property (nonatomic, assign, readonly) NSInteger revisionID;
@property (nonatomic, assign, readonly) NSInteger articleSizeAtRevision;
@property (nonatomic, assign, readwrite) NSInteger revisionSize;

- (NSInteger)daysFromToday;

@end
