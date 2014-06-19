//
//  GameOverScene.h
//  MGD
//
//  Created by Aaron Burke on 5/21/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <GameKit/GameKit.h>

@interface GameOverScene : SKScene <GKGameCenterControllerDelegate>

- (id)initWithSize:(CGSize)size won:(BOOL)won;

@end
