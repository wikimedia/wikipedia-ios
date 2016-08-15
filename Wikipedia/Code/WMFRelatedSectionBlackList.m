#import "WMFRelatedSectionBlackList.h"
#import "MWKList+Subclass.h"
#import "MWKTitle.h"

static NSString *const WMFRelatedSectionBlackListFileName = @"WMFRelatedSectionBlackList";
static NSString *const WMFRelatedSectionBlackListFileExtension = @"plist";

@implementation NSURL (MWKListObject)

- (id<NSCopying, NSObject>)listIndex {
  return self;
}

@end

@interface WMFRelatedSectionBlackList ()

@end

@implementation WMFRelatedSectionBlackList

+ (instancetype)sharedBlackList {
  static WMFRelatedSectionBlackList *blackList = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blackList = [self loadFromDisk];
    if (!blackList) {
      blackList = [[WMFRelatedSectionBlackList alloc] init];
    }
  });

  return blackList;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {

    __block BOOL foundNonURL = NO;

    NSArray *fixed = [self.entries wmf_mapAndRejectNil:^id _Nullable(id _Nonnull obj) {

      if ([obj isKindOfClass:[NSURL class]]) {
        return obj;
      } else if ([obj isKindOfClass:[MWKTitle class]]) {
        foundNonURL = YES;
        return [(MWKTitle *)obj URL];
      } else {
        foundNonURL = YES;
        return nil;
      }
    }];

    if (foundNonURL) {
      [self removeAllEntries];
      [self importEntries:fixed];
    }
  }
  return self;
}

+ (NSUInteger)modelVersion {
  return 1;
}

- (id)decodeValueForKey:(NSString *)key withCoder:(NSCoder *)coder modelVersion:(NSUInteger)modelVersion {
  if ([key isEqualToString:WMF_SAFE_KEYPATH(self, entries)] && modelVersion == 0) {
    NSArray *titles = [self decodeValueForKey:WMF_SAFE_KEYPATH(self, entries) withCoder:coder modelVersion:0];
    return [titles wmf_mapAndRejectNil:^id(NSURL *obj) {
      if ([obj isKindOfClass:[NSURL class]]) {
        return obj;
      } else if ([obj isKindOfClass:[MWKTitle class]]) {
        return [(MWKTitle *)obj URL];
      } else {
        return nil;
      }
    }];
  } else {
    return [super decodeValueForKey:key withCoder:coder modelVersion:modelVersion];
  }
}

+ (NSURL *)fileURL {
  return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFRelatedSectionBlackListFileName] stringByAppendingPathExtension:WMFRelatedSectionBlackListFileExtension]];
}

- (void)performSaveWithCompletion:(dispatch_block_t)completion error:(WMFErrorHandler)errorHandler {
  @synchronized(self) {
    if (![NSKeyedArchiver archiveRootObject:self toFile:[[[self class] fileURL] path]]) {
      DDLogError(@"Failed to save sections to disk!");
      if (errorHandler) {
        errorHandler([NSError wmf_unableToSaveErrorWithReason:@"NSKeyedArchiver failed to save blacklist to disk"]);
      }
    } else {
      if (completion) {
        completion();
      }
    }
  }
}

+ (instancetype)loadFromDisk {
  return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self fileURL] path]];
}

- (void)addBlackListArticleURL:(NSURL *)url {
  [self addEntry:url];
}

- (void)addEntry:(NSURL *)entry {
  @synchronized(self) {
    [super addEntry:entry];
  }
}

- (void)removeBlackListArticleURL:(NSURL *)url {
  [self removeEntry:url];
}

- (void)removeEntry:(NSURL *)entry {
  @synchronized(self) {
    [super removeEntry:entry];
  }
}

- (BOOL)articleURLIsBlackListed:(NSURL *)url {
  return [self containsEntryForListIndex:url];
}

- (BOOL)containsEntryForListIndex:(NSURL *)url {
  @synchronized(self) {
    return [super containsEntryForListIndex:url];
  }
}

@end
