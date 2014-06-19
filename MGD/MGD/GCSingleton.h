//
//  GCSingleton.h
//  MGD
//
//  Created by Aaron Burke on 6/18/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GCSingleton : NSObject

@property (assign, readonly) BOOL userAuthenticated;
@property (assign, readonly) BOOL gameCenterAvailable;
@property (nonatomic, strong) GKLocalPlayer *localPlayer;

+ (GCSingleton *)sharedContext;
- (void)authenticateLocalUser;

@end
