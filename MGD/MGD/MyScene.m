//
//  MyScene.m
//  MGD
//
//  Created by Aaron Burke on 5/7/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "MyScene.h"
@import AVFoundation;

// Movement Speed - Points Per Second
static const float FROG_MPPS = 240.0;

// Calculation helper methods from tutorial
static inline CGPoint CGPointAdd(const CGPoint a,const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}
static inline CGPoint CGPointSubtract(const CGPoint a,const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}
static inline CGFloat CGPointLength(const CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}
static inline CGPoint CGPointNormalize(const CGPoint a)
{
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}
static inline CGPoint CGPointMultiplyScalar(const CGPoint a,const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

@implementation MyScene
{
    SKSpriteNode *_snail;
    SKSpriteNode *_frog;
    SKSpriteNode *_water;
    
    SKAction *_frogSound;
    SKAction *_waterSound;
    
    
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _lastTouchLocation;
    CGPoint _velocity;
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
    SKNode *node = [self nodeAtPoint:location];
    
    [self moveFrogToPosition:location];
    [[self scene] runAction:_frogSound];
    
    if ([node.name isEqualToString:@"water"]) {
        [SKAction playSoundFileNamed:@"waterSplash.wav" waitForCompletion:NO];
    }
    
    if ([node.name isEqualToString:@"frog"]) {


    }
   
    
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    [self moveFrogToPosition:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    [self moveFrogToPosition:touchLocation];
}

-(void)update:(CFTimeInterval)currentTime {
    // Used to smooth out movement due to update times being variable
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    
    CGPoint offset = CGPointSubtract(_lastTouchLocation, _frog.position);
    float distance = CGPointLength(offset);
    if (distance < FROG_MPPS * _dt) {
        _frog.position = _lastTouchLocation;
        _velocity = CGPointZero;
    } else {
        [self moveSprite:_frog velocity:_velocity];
    }
}

- (void)didEvaluateActions {
    [self checkCollisions];
}

- (void)moveSprite:(SKSpriteNode *)sprite
          velocity:(CGPoint)velocity
{
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, _dt);
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

-(void)moveFrogToPosition:(CGPoint)location
{
    
    _lastTouchLocation = location;
    CGPoint offset = CGPointSubtract(location, _frog.position);
    
    CGPoint direction = CGPointNormalize(offset);
    _velocity = CGPointMultiplyScalar(direction, FROG_MPPS);
}

- (void)checkCollisions
{
    
    [self enumerateChildNodesWithName:@"water"
                           usingBlock:^(SKNode *node, BOOL *stop){
                               SKSpriteNode *water = (SKSpriteNode *)node;
                               CGRect smallerFrame = CGRectInset(water.frame, 20, 20);
                               if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
                                   NSLog(@"Collision detected");
                                   [[self scene] runAction:_waterSound];
                               }
                           }];
}

@end
