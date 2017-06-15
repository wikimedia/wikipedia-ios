@interface NSArray (WMFShuffle)

/// @return A shuffled copy of the receiver.
- (instancetype)wmf_shuffledCopy;

@end

@interface NSMutableArray (WMFShuffle)

/// Shuffles the receiver in place, then returns it.
- (instancetype)wmf_shuffle;

@end
