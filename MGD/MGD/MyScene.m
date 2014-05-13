//
//  MyScene.m
//  MGD
//
//  Created by Aaron Burke on 5/7/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "MyScene.h"
#import "SKTUtils.h"
@import AVFoundation;

// Side of frog selected
typedef NS_ENUM(NSInteger, Side)
{
    SideRight = 0,
    SideLeft = 2,
    SideTop = 1,
    SideBottom = 3,
};

// Movement Speed - Points Per Second
static const float FROG_MOVE_DISTANCE = 64.0;

@implementation MyScene
{
    SKSpriteNode *_snail;
    SKSpriteNode *_frog;
    SKSpriteNode *_water;
    
    SKAction *_frogAnimationForward;
    SKAction *_frogAnimationBackward;
    SKAction *_frogAnimationRight;
    SKAction *_frogAnimationLeft;
    
    SKAction *_frogSound;
    SKAction *_waterSound;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Test Background!";
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
        [self addChild:myLabel];
        
        _snail = [SKSpriteNode spriteNodeWithImageNamed:@"snailWalk1"];
        _snail.position = CGPointMake(300, 300);
        _snail.xScale = 1.5;
        _snail.yScale = 1.5;
        _snail.name = @"snail";
        [self addChild:_snail];
        
        _frog = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:@"frog"] textureNamed: @"Frog Forward/frog1"]];
        _frog.position = CGPointMake(384, 32);
        _frog.name = @"frog";
        _frog.userInteractionEnabled = YES;
        _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
        [self addChild:_frog];
        NSLog(@"Frog width = %f, height = %f", _frog.size.width, _frog.size.height);

        _water = [SKSpriteNode spriteNodeWithImageNamed:@"liquidWater"];
        _water.position = CGPointMake(500, 300);
        _water.userInteractionEnabled = YES;
        _water.name = @"water";
        _waterSound = [SKAction playSoundFileNamed:@"waterSplash.wav" waitForCompletion:YES];
        [self addChild:_water];
        
        // Frog forward animation
        NSMutableArray *texturesForward =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        _frogAnimationForward = [SKAction animateWithTextures:texturesForward timePerFrame:0.05];
        
        // Frog reverse animation
        NSMutableArray *texturesBackward =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        _frogAnimationBackward = [SKAction animateWithTextures:texturesBackward timePerFrame:0.05];
        
        // Frog Right animation
        NSMutableArray *texturesRight =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        _frogAnimationRight = [SKAction animateWithTextures:texturesRight timePerFrame:0.05];
        
        // Frog Left animation
        NSMutableArray *texturesLeft =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:@"frog"]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        _frogAnimationLeft = [SKAction animateWithTextures:texturesLeft timePerFrame:0.05];
        
    }
    return self;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.scene];
    
    Side side = [self getSideSelected:location];
    NSLog(@"Side selected = %d", side);
    [self moveFrogInDirection:side];
    [[self scene] runAction:_frogSound];
    

   
    
}

- (void)didEvaluateActions {
    [self checkCollisions];
}

- (Side)getSideSelected:(CGPoint)location
{
    CGPoint diff = CGPointSubtract(location,_frog.position);
    CGFloat angle = CGPointToAngle(diff);
    if (angle > -M_PI_4 && angle <= M_PI_4) {
        return SideRight;
    } else if (angle > M_PI_4 && angle <= 3.0f * M_PI_4) {
        return SideTop;
    } else if (angle <= -M_PI_4 && angle > -3.0f * M_PI_4) {
        return SideBottom;
    } else {
        return SideLeft;
    }
}

-(void)moveFrogInDirection:(Side)side
{
    if (side == 1) {
        CGVector negDelta = CGVectorMake(0,FROG_MOVE_DISTANCE);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationForward]];
        [_frog runAction:group];
    } else if (side == 0) {
        CGVector negDelta = CGVectorMake(FROG_MOVE_DISTANCE,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationRight]];
        [_frog runAction:group];
    } else if (side == 2) {
        CGVector negDelta = CGVectorMake(-FROG_MOVE_DISTANCE,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationLeft]];
        [_frog runAction:group];
    } else if (side == 3) {
        CGVector negDelta = CGVectorMake(0,-FROG_MOVE_DISTANCE);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationBackward]];
        [_frog runAction:group];
    }
}

- (void)checkCollisions
{
    
    [self enumerateChildNodesWithName:@"water" usingBlock:^(SKNode *node, BOOL *stop)
    {
        SKSpriteNode *water = (SKSpriteNode *)node;
        CGRect smallerFrame = CGRectInset(water.frame, 20, 20);
        if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
           NSLog(@"Collision detected");
           [[self scene] runAction:_waterSound];
        }
    }];
}

@end
