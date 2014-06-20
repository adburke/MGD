//
//  LocalScoreBoard.m
//  MGD
//
//  Created by Aaron Burke on 6/19/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "LocalScoreBoard.h"

@implementation LocalScoreBoard

+ (LocalScoreBoard *)sharedContext
{
    static LocalScoreBoard *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LocalScoreBoard alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        // Check for GC availablility
        self.scores = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)updateScoreBoard:(double)score
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"scoreBoard.plist"];
    
    NSNumber *num = [NSNumber numberWithDouble:score];
    
    self.scores = [NSMutableArray arrayWithContentsOfFile:path];
    if (!self.scores) {
        self.scores = [[NSMutableArray alloc] initWithCapacity:10];
    }
    //[self.scores sortedArrayUsingSelector:@selector(compare:)];
    
    [self.scores addObject:num];
    
    
    NSArray *sortedArray = [self.scores sortedArrayUsingSelector:@selector(compare:)];
    
    self.scores = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    [self.scores writeToFile:path atomically:YES];
    
    NSLog(@"array: %@", self.scores);
}


@end
