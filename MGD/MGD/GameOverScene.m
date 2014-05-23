//
//  GameOverScene.m
//  MGD
//
//  Created by Aaron Burke on 5/21/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"

@implementation GameOverScene

- (id)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size]) {
        SKSpriteNode *background;
        if (won) {
            background = [SKSpriteNode spriteNodeWithImageNamed:@"win.png"];
        } else {
            background = [SKSpriteNode spriteNodeWithImageNamed:@"lose.png"];
        }
        background.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:background];
        
        // Start the game over
        SKAction * wait = [SKAction waitForDuration:3.0];
        SKAction * block = [SKAction runBlock:^{
            MyScene * myScene = [[MyScene alloc] initWithSize:self.size];
            SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
            [self.view presentScene:myScene transition: transition];
        }];
        [self runAction:[SKAction sequence:@[wait, block]]];
        
    }
    return self;
}

@end
