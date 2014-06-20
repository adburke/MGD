//
//  LocalScoreBoard.h
//  MGD
//
//  Created by Aaron Burke on 6/19/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalScoreBoard : NSObject

@property (nonatomic, strong) NSMutableArray *scores;

+ (LocalScoreBoard *)sharedContext;
- (void)updateScoreBoard:(double)score;

@end
