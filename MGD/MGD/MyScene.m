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
static const float FROG_MOVE_DISTANCE = 50.0;

@implementation MyScene
{
    SKSpriteNode *_snail;
    SKSpriteNode *_frog;
    SKSpriteNode *_water;
    
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
        
        _frog = [SKSpriteNode spriteNodeWithImageNamed:@"frog"];
        _frog.position = CGPointMake(400, 400);
        _frog.xScale = 0.1;
        _frog.yScale = 0.1;
        _frog.name = @"frog";
        _frog.userInteractionEnabled = YES;
        _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
        [self addChild:_frog];
        
        _water = [SKSpriteNode spriteNodeWithImageNamed:@"liquidWater"];
        _water.position = CGPointMake(500, 300);
        _water.userInteractionEnabled = YES;
        _water.name = @"water";
        _waterSound = [SKAction playSoundFileNamed:@"waterSplash.wav" waitForCompletion:YES];
        [self addChild:_water];
        
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
        [_frog runAction:actionMove];
    } else if (side == 0) {
        CGVector negDelta = CGVectorMake(FROG_MOVE_DISTANCE,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        [_frog runAction:actionMove];
    } else if (side == 2) {
        CGVector negDelta = CGVectorMake(-FROG_MOVE_DISTANCE,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        [_frog runAction:actionMove];
    } else if (side == 3) {
        CGVector negDelta = CGVectorMake(0,-FROG_MOVE_DISTANCE);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.2];
        [_frog runAction:actionMove];
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
