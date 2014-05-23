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
#import "GameOverScene.h"
#include <sys/types.h>
#include <sys/sysctl.h>

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

#define ARC4RANDOM_MAX      0x100000000
static inline CGFloat ScalarRandomRange(CGFloat min,
                                        CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) *
                  (max - min) + min);
}

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
    SKSpriteNode *_frog;
    
    SKSpriteNode *_water;
    SKSpriteNode *_dirtStart;
    SKSpriteNode *_dirtFinish;
    SKSpriteNode *_stone;
    SKSpriteNode *_grass;
    SKSpriteNode *_death;
    
    SKAction *_frogAnimationForward;
    SKAction *_frogAnimationBackward;
    SKAction *_frogAnimationRight;
    SKAction *_frogAnimationLeft;
    
    SKAction *_snailAnimation;
    
    SKAction *_frogSound;
    SKAction *_waterSound;
    
    int _lives;
    BOOL _gameOver;
    BOOL _win;
    
    NSString *_frogAtlas;
    NSString *_sceneAtlas;
    NSString *_ext;
    
    UISwipeGestureRecognizer *_leftSwipeGestureRecognizer;
    UISwipeGestureRecognizer *_rightSwipeGestureRecognizer;
    
    SKLabelNode *_pauseLabel;
    SKLabelNode *_livesLabel;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        _lives = 5;
        _gameOver = NO;
        _win = NO;
        self.view.paused = NO;
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithUTF8String:machine];
        free(machine);

        if ([platform hasPrefix:@"iPad3,"]){
            _frogAtlas = @"frog";
            _sceneAtlas = @"scene";
        } else if ([platform hasPrefix:@"iPhone5,"]) {
            _frogAtlas = @"frog-iphone";
            _sceneAtlas = @"scene-iphone";
        } else if ([platform hasPrefix:@"iPad2,"]) {
            _frogAtlas = @"frog";
            _sceneAtlas = @"scene";
        } else if ([platform isEqualToString:@"x86_64"]) {
            // for simulator
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                if (IS_WIDESCREEN) {
                    _frogAtlas = @"frog-iphone";
                    _sceneAtlas = @"scene-iphone";
                } else {
                    _frogAtlas = @"frog-iphone";
                    _sceneAtlas = @"scene-iphone";
                }
            } else {
                _frogAtlas = @"frog";
                _sceneAtlas = @"scene";
            }
        }
        
        _livesLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _livesLabel.text = [NSString stringWithFormat:@"Lives %d", _lives];
        _livesLabel.fontSize = 35;
        _livesLabel.position = CGPointMake(65, 980);
        _livesLabel.zPosition = 500;
        [self addChild:_livesLabel];
        
        //@"Frog Forward/frog1@2x"
        _frog = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_frogAtlas] textureNamed:@"Frog Forward/frog1"]];
        _frog.position = CGPointMake(384, 32);
        _frog.name = @"frog";
        _frog.zPosition = 300;
        _frog.userInteractionEnabled = YES;
        _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
        [self addChild:_frog];
        NSLog(@"Frog width = %f, height = %f", _frog.size.width, _frog.size.height);

        _water = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"water"]];
        _water.position = CGPointMake(384, 767);
        _water.name = @"water";
        _waterSound = [SKAction playSoundFileNamed:@"waterSplash.wav" waitForCompletion:YES];
        [self addChild:_water];
        
        _dirtStart = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"dirt"]];
        _dirtStart.position = CGPointMake(384, 33);
        _dirtStart.name = @"start";
        [self addChild:_dirtStart];
        
        _dirtFinish = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"dirt"]];
        _dirtFinish.position = CGPointMake(384, 991);
        _dirtFinish.name = @"finish";
        [self addChild:_dirtFinish];
        
        _stone = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"stone"]];
        _stone.position = CGPointMake(384, 545);
        _stone.name = @"stone";
        [self addChild:_stone];
        
        _grass = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"grass"]];
        _grass.position = CGPointMake(384, 289);
        _grass.name = @"grass";
        [self addChild:_grass];
        
        // Frog forward animation
        NSMutableArray *texturesForward =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        _frogAnimationForward = [SKAction animateWithTextures:texturesForward timePerFrame:0.05];
        
        // Frog reverse animation
        NSMutableArray *texturesBackward =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        _frogAnimationBackward = [SKAction animateWithTextures:texturesBackward timePerFrame:0.05];
        
        // Frog Right animation
        NSMutableArray *texturesRight =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        _frogAnimationRight = [SKAction animateWithTextures:texturesRight timePerFrame:0.05];
        
        // Frog Left animation
        NSMutableArray *texturesLeft =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_frogAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        _frogAnimationLeft = [SKAction animateWithTextures:texturesLeft timePerFrame:0.05];
        
        // Snail animation
        NSMutableArray *snailTextures =
        [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 3; i++) {
            NSString *textureName = [NSString stringWithFormat:@"snailWalk%d", i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [snailTextures addObject:texture];
        }
        for (int i = 1; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"snailWalk%d", i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [snailTextures addObject:texture];
        }
        _snailAnimation = [SKAction animateWithTextures:snailTextures timePerFrame:0.05];
        
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction performSelector:@selector(spawnSnail) onTarget:self],
                                              [SKAction waitForDuration:0.5]]]]];
        
    }
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    _leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] init];
    [_leftSwipeGestureRecognizer addTarget:self action:@selector(showLabel)];
    [_leftSwipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer: _leftSwipeGestureRecognizer];
    _rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] init];
    [_rightSwipeGestureRecognizer addTarget:self action:@selector(showLabel)];
    [_rightSwipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer: _rightSwipeGestureRecognizer];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.scene];
    if (self.view.paused) {
        self.view.paused = NO;
        [_pauseLabel removeFromParent];
    }
    Side side = [self getSideSelected:location];
    NSLog(@"Side selected = %d", side);
    [self moveFrogInDirection:side];
    [[self scene] runAction:_frogSound];
    
}

- (void)update:(NSTimeInterval)currentTime
{
    if (_lives <= 0 && !_gameOver) {
        _gameOver = YES;
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:FALSE];
        SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:transition];
    } else if (_lives > 0 && _win && !_gameOver){
        _gameOver = YES;
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:TRUE];
        SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:transition];
    }
    
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

-(void)spawnSnail
{
    SKSpriteNode *snail = [SKSpriteNode spriteNodeWithImageNamed:@"snailWalk1"];
//    _snail.position = CGPointMake(300, 300);
    snail.xScale = 1.5;
    snail.yScale = 1.5;
    snail.zPosition = 300;
    snail.name = @"snail";
    
    CGPoint snailScenePos = CGPointMake(self.size.width + snail.size.width/2,ScalarRandomRange(snail.size.width, _grass.size.height));
    snail.position = [self convertPoint:snailScenePos toNode:self];
    
    [self addChild:snail];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-snail.size.width/2,snail.position.y) duration:3.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    SKAction *group = [SKAction group:@[actionMove, _snailAnimation]];
    [snail runAction:[SKAction sequence:@[group, actionRemove]]];
}

- (void)checkCollisions
{
    
//    [self enumerateChildNodesWithName:@"water" usingBlock:^(SKNode *node, BOOL *stop)
//    {
//        SKSpriteNode *water = (SKSpriteNode *)node;
//        CGRect smallerFrame = CGRectInset(water.frame, 20, 20);
//        if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
//            NSLog(@"Collision detected");
//            [[self scene] runAction:_waterSound];
//            _lives--;
//            [_frog removeFromParent];
//            [self respawnFrog];
//        }
//    }];
    
    [self enumerateChildNodesWithName:@"finish" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *finish = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(finish.frame, 0, 30);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
             NSLog(@"Collision detected");
             SKAction *wait = [SKAction waitForDuration:0.4];
             SKAction *performSelector = [SKAction performSelector:@selector(winGame) onTarget:self];
             SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
             [self runAction:sequence];
         }
     }];
    
    if (_death) {return;}
    
    [self enumerateChildNodesWithName:@"snail" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *snail = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(snail.frame, 20, 20);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
             NSLog(@"Collision detected");
             [[self scene] runAction:[SKAction playSoundFileNamed:@"frogGroan.wav" waitForCompletion:YES]];
             _lives--;
             _livesLabel.text = [NSString stringWithFormat:@"Lives %d", _lives];
             
             _death = [SKSpriteNode spriteNodeWithImageNamed:@"death.png"];
             _death.position = CGPointMake(_frog.position.x, _frog.position.y);
             _death.zPosition = 500;
             [_frog removeFromParent];
             [self addChild:_death];
             
             SKAction *wait = [SKAction waitForDuration:1];
             SKAction *performSelector = [SKAction performSelector:@selector(respawnFrog) onTarget:self];
             SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
             [self runAction:sequence];
             
         }
     }];
}

- (void)respawnFrog
{
    [_death removeFromParent];
    _death = nil;
    
    _frog = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:@"frog"] textureNamed: @"Frog Forward/frog1"]];
    _frog.position = CGPointMake(384, 32);
    _frog.name = @"frog";
    _frog.zPosition = 300;
    _frog.userInteractionEnabled = YES;
    _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
    [self addChild:_frog];
}

- (void)winGame
{
    _win = YES;
}

- (void)showLabel
{
    if (self.view.paused) {
        [_pauseLabel removeFromParent];
        SKAction *wait = [SKAction waitForDuration:0.4];
        SKAction *performSelector = [SKAction performSelector:@selector(pause) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
        [self runAction:sequence];
    } else {
        _pauseLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        _pauseLabel.text = @"PAUSED";
        _pauseLabel.fontSize = 50;
        _pauseLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        _pauseLabel.zPosition = 500;
        [self addChild:_pauseLabel];
        SKAction *wait = [SKAction waitForDuration:0.4];
        SKAction *performSelector = [SKAction performSelector:@selector(pause) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
        [self runAction:sequence];
        
    }
}

- (void)pause
{
    if (self.view.paused) {
        self.view.paused = NO;
    } else {
        self.view.paused = YES;
    }
    
}


@end
