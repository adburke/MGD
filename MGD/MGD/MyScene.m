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
#import <GameKit/GameKit.h>
#import "GCSingleton.h"
#import "LocalScoreBoard.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define SCOREBOARD_ID @"frogglesFinishTime1"

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

typedef NS_ENUM(NSInteger, DeviceType)
{
    DeviceType_Iphone3in = 0,
    DeviceType_Iphone4in = 1,
    DeviceType_Ipad = 2,
    
};

// Movement Speed - Points Per Second
//static const float FROG_MOVE_DISTANCE = 64.0;

@implementation MyScene
{
    SKSpriteNode *_frog;
    
    SKSpriteNode *_water;
    SKSpriteNode *_dirtStart;
    SKSpriteNode *_dirtFinish;
    SKSpriteNode *_stone;
    SKSpriteNode *_grass;
    SKSpriteNode *_death;
    SKSpriteNode *_pauseBtn;
    
    SKAction *_frogAnimationForward;
    SKAction *_frogAnimationBackward;
    SKAction *_frogAnimationRight;
    SKAction *_frogAnimationLeft;
    
    SKAction *_snailAnimation;
    
    SKAction *_frogSound;
    SKAction *_waterSound;
    
    int _flies;
    int _lives;
    BOOL _gameOver;
    BOOL _win;
    BOOL _isMoving;
    BOOL _isFloating;
    BOOL startGamePlay;
    BOOL gameStarted;
    NSTimeInterval startTime;
    float _frogMoveDistance;
    DeviceType _deviceType;
    
    NSMutableArray *_flySpawnPoints;
    
    GCSingleton *_gcSingleton;
    
    CGPoint _frogRespawnPos;
    
    NSString *_sceneAtlas;

    SKLabelNode *_pauseLabel;
    SKLabelNode *_livesLabel;
    SKLabelNode *_flyLabel;
    SKLabelNode *_countDownLabel;
    SKLabelNode *_countDownLabelNumber;
    
}

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        
        _gcSingleton = [GCSingleton sharedContext];
        
        _lives = 5;
        _gameOver = NO;
        _win = NO;
        _isMoving = NO;
        self.view.paused = NO;
        gameStarted = NO;
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithUTF8String:machine];
        free(machine);

        if ([platform hasPrefix:@"iPad3,"])
        {
            _sceneAtlas = @"Ipad";
            _frogMoveDistance = 64;
            _deviceType = DeviceType_Ipad;
        }
        else if ([platform hasPrefix:@"iPhone5,"])
        {
            _sceneAtlas = @"Iphone5";
            _frogMoveDistance = 32;
            _deviceType = DeviceType_Iphone4in;
        }
        else if ([platform hasPrefix:@"iPad2,"])
        {
            _sceneAtlas = @"Ipad";
            _frogMoveDistance = 64;
            _deviceType = DeviceType_Ipad;
        }
        else if ([platform isEqualToString:@"x86_64"])
        {
            // for simulator
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            {
                if (IS_WIDESCREEN)
                {
                    _sceneAtlas = @"Iphone5";
                    _frogMoveDistance = 32;
                    _deviceType = DeviceType_Iphone4in;
                }
                else
                {
                    _sceneAtlas = @"Iphone";
                    _deviceType = DeviceType_Iphone3in;
                    if ([[UIScreen mainScreen] bounds].size.height <= 480.0f)
                    {
                        _frogMoveDistance = 32;
                    }
                    else
                    {
                        _frogMoveDistance = 32;
                    }
                }
            }
            else
            {
                _sceneAtlas = @"Ipad";
                _frogMoveDistance = 64;
                _deviceType = DeviceType_Ipad;
            }
        }
        
        
        _livesLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _livesLabel.text = [NSString stringWithFormat:@"Lives %d", _lives];
        _livesLabel.zPosition = 500;
        
        _frog = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Frog Forward/frog1"]];
        _frog.name = @"frog";
        _frog.zPosition = 300;
        _frog.userInteractionEnabled = YES;
        _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
        NSLog(@"Frog width = %f, height = %f", _frog.size.width, _frog.size.height);

        _water = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Scene/water"]];
        _water.name = @"water";
        _waterSound = [SKAction playSoundFileNamed:@"waterSplash.wav" waitForCompletion:YES];
        
        _dirtStart = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Scene/dirt"]];
        _dirtStart.name = @"start";
        
        _dirtFinish = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Scene/dirt"]];
        _dirtFinish.name = @"finish";
        
        _stone = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Scene/stone"]];
        _stone.name = @"stone";
        
        _grass = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Scene/grass"]];
        _grass.name = @"grass";
        
        _pauseBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Buttons/pause"]];
        _pauseBtn.name = @"pauseBtn";
        _pauseBtn.zPosition = 500;
        _pauseBtn.userInteractionEnabled = NO;
        
        _pauseLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial-BoldMT"];
        _pauseLabel.text = @"PAUSED";
        _pauseLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        _pauseLabel.zPosition = 500;
        
        _flyLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _flyLabel.text = [NSString stringWithFormat:@"Flies %d of 6", _flies];
        _flyLabel.zPosition = 500;
        
        _countDownLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _countDownLabel.zPosition = 500;
        _countDownLabel.text = @"Timer:";
        
        _countDownLabelNumber = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _countDownLabelNumber.zPosition = 500;
        _countDownLabelNumber.text = @"60.00";
        
        NSArray *nodes = @[_livesLabel, _frog, _water, _dirtStart, _dirtFinish, _stone, _grass, _pauseBtn, _flyLabel, _countDownLabel, _countDownLabelNumber];
        [self setupScene:_deviceType];
        for (SKSpriteNode *node in nodes)
        {
            [self addChild:node];
        }
        
        // Frog forward animation
        NSMutableArray *texturesForward = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++)
        {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        for (int i = 2; i > 0; i--)
        {
            NSString *textureName = [NSString stringWithFormat:@"frog%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Forward/%@", textureName]];
            [texturesForward addObject:texture];
        }
        _frogAnimationForward = [SKAction animateWithTextures:texturesForward timePerFrame:0.05];
        
        // Frog reverse animation
        NSMutableArray *texturesBackward = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        for (int i = 2; i > 0; i--)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogB%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Backward/%@", textureName]];
            [texturesBackward addObject:texture];
        }
        _frogAnimationBackward = [SKAction animateWithTextures:texturesBackward timePerFrame:0.05];
        
        // Frog Right animation
        NSMutableArray *texturesRight = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        for (int i = 2; i > 0; i--)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogR%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Right/%@", textureName]];
            [texturesRight addObject:texture];
        }
        _frogAnimationRight = [SKAction animateWithTextures:texturesRight timePerFrame:0.05];
        
        // Frog Left animation
        NSMutableArray *texturesLeft = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        for (int i = 2; i > 0; i--)
        {
            NSString *textureName = [NSString stringWithFormat:@"frogL%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Frog Left/%@", textureName]];
            [texturesLeft addObject:texture];
        }
        _frogAnimationLeft = [SKAction animateWithTextures:texturesLeft timePerFrame:0.05];
        
        // Snail animation
        NSMutableArray *snailTextures = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++) {
            NSString *textureName = [NSString stringWithFormat:@"snail%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Enemies/%@", textureName]];
            [snailTextures addObject:texture];
        }
        for (int i = 2; i > 0; i--) {
            NSString *textureName = [NSString stringWithFormat:@"snail%d", i];
            SKTexture *texture = [[SKTextureAtlas atlasNamed:_sceneAtlas]
                                  textureNamed:[NSString stringWithFormat:@"Enemies/%@", textureName]];
            [snailTextures addObject:texture];
        }
        _snailAnimation = [SKAction animateWithTextures:snailTextures timePerFrame:0.1];
        
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction performSelector:@selector(spawnSnail) onTarget:self],
                                              [SKAction waitForDuration:2.0]]]]];
        
        // Spawn Lily pads
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                                                                     [self spawnLily:1];
                                                                 }],
                                              [SKAction waitForDuration:4]]]]];
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                                                                     [self spawnLily:2];
                                                                 }],
                                              [SKAction waitForDuration:2]]]]];
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                             [self spawnLily:3];
                         }],
                                              [SKAction waitForDuration:5]]]]];
        
        // Spawn Logs
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                                                                    [self spawnLog:1];
                                                                    }],
                                              [SKAction waitForDuration:5]]]]];
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                                                                     [self spawnLog:2];
                                                                 }],
                                              [SKAction waitForDuration:6]]]]];
        [self runAction:[SKAction repeatActionForever:
                         [SKAction sequence:@[
                                              [SKAction runBlock:^{
                             [self spawnLog:3];
                         }],
                                              [SKAction waitForDuration:8]]]]];
        
        [self spawnFlys:6];


    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    
    for (UITouch *touch in touches)
    {
        if  (!gameStarted)
        {
            startGamePlay = YES;
        }
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.scene];
    SKNode *node = [self nodeAtPoint:location];
    
    if ([node.name isEqualToString:@"pauseBtn"])
    {
        NSLog(@"Pause Btn selected");
        [self showLabel];
        return;
        //[self pause];
    }
    else if (self.view.paused)
    {
        [self showLabel];
        return;
    }
    
    Side side = [self getSideSelected:location];
    NSLog(@"Side selected = %d", side);
    _isMoving = YES;
    [_frog removeAllActions];
    [self moveFrogInDirection:side];
    [[self scene] runAction:_frogSound];
    
}

- (void)update:(NSTimeInterval)currentTime
{
    
    if (_lives <= 0 && !_gameOver)
    {
        _gameOver = YES;
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:FALSE];
        SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:transition];
    }
    else if (_lives > 0 && _win && !_gameOver)
    {
        _gameOver = YES;
        
        BOOL status = [self currentNetworkStatus];
        
        if ([[GCSingleton sharedContext] userAuthenticated] && status)
        {
            
            // Check Achievement Status
            if (![_gcSingleton.achievementsDictionary objectForKey:@"levelCompleted"]) {
                //[_gcSingleton reportAchievementIdentifier:@"levelCompleted" percentComplete:100.0];
                
                GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: @"levelCompleted"];
                achievement.percentComplete = 100.0;
                achievement.showsCompletionBanner = YES;
                
                NSArray *achievementArray = @[achievement];
                
                [_gcSingleton reportAchievements:achievementArray];
            }
            
            if (_lives == 5) {
                if (![_gcSingleton.achievementsDictionary objectForKey:@"flawlessFinish"])
                {
                    //[_gcSingleton reportAchievementIdentifier:@"flawlessFinish" percentComplete:100.0];
                    //[_gcSingleton reportAchievementIdentifier:@"flawlessMaster" percentComplete:33.0];
                    
                    GKAchievement *achievement1 = [[GKAchievement alloc] initWithIdentifier: @"flawlessFinish"];
                    GKAchievement *achievement2 = [[GKAchievement alloc] initWithIdentifier: @"flawlessMaster"];
                    achievement1.percentComplete = 100.0;
                    achievement1.showsCompletionBanner = YES;
                    
                    achievement2.percentComplete = 33.0;
                    
                    NSArray *achievementArray = @[achievement1,achievement2];
                    
                    [_gcSingleton reportAchievements:achievementArray];
                    
                }
                else
                {
                    GKAchievement *flawlessMaster = [_gcSingleton.achievementsDictionary objectForKey:@"flawlessMaster"];
                    
                    if (flawlessMaster.percentComplete < 40.0)
                    {
                        //[_gcSingleton reportAchievementIdentifier:@"flawlessMaster" percentComplete:66];
                        
                        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: @"flawlessMaster"];
                        achievement.percentComplete = 66.0;
                        
                        NSArray *achievementArray = @[achievement];
                        
                        [_gcSingleton reportAchievements:achievementArray];
                    }

                    else if (flawlessMaster.percentComplete > 40 && flawlessMaster.percentComplete < 70)
                    {
                        //[_gcSingleton reportAchievementIdentifier:@"flawlessMaster" percentComplete:100.0];
                        
                        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: @"flawlessMaster"];
                        achievement.percentComplete = 100.0;
                        achievement.showsCompletionBanner = YES;
                        
                        NSArray *achievementArray = @[achievement];
                        
                        [_gcSingleton reportAchievements:achievementArray];
                    }
                }
                
            }
            
            
            int64_t score = (60.0 - _countDownLabelNumber.text.doubleValue)*100;
            [self reportScore:score];
        }
        else
        {
            [[LocalScoreBoard sharedContext] updateScoreBoard:(60.0 - _countDownLabelNumber.text.doubleValue)];
        }
        
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:TRUE];
        SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:transition];
    }
    
    //reset counter if starting
    if (startGamePlay)
    {
        startTime = currentTime;
        gameStarted = YES;
        startGamePlay = NO;
    }
    
    double countDownInt = 60.0 -(double)(currentTime-startTime);
    if (countDownInt > 0) //if counting down to 0 show counter
    {
        _countDownLabelNumber.text = [NSString stringWithFormat:@"%.2f", countDownInt];
    }
    else if (gameStarted && !_gameOver)
    {
        _gameOver = YES;
        SKScene * gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:FALSE];
        SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:transition];
    }
    
}

- (void)reportScore: (int64_t) score
{
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier: SCOREBOARD_ID];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    NSArray *scores = @[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error)
    {
        //Do something interesting here.
    }];
}

- (void)didEvaluateActions
{
    [self checkCollisions];
}

- (Side)getSideSelected:(CGPoint)location
{
    CGPoint diff = CGPointSubtract(location,_frog.position);
    CGFloat angle = CGPointToAngle(diff);
    if (angle > -M_PI_4 && angle <= M_PI_4)
    {
        return SideRight;
    }
    else if (angle > M_PI_4 && angle <= 3.0f * M_PI_4)
    {
        return SideTop;
    }
    else if (angle <= -M_PI_4 && angle > -3.0f * M_PI_4)
    {
        return SideBottom;
    }
    else
    {
        return SideLeft;
    }
}

-(void)moveFrogInDirection:(Side)side
{
    if (side == 1)
    {
        CGVector negDelta = CGVectorMake(0,_frogMoveDistance);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.1];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationForward]];
        SKAction *performSelector = [SKAction performSelector:@selector(checkMovement) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[group, performSelector]];
        [_frog runAction:sequence];
    }
    else if (side == 0)
    {
        CGVector negDelta = CGVectorMake(_frogMoveDistance,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.1];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationRight]];
        SKAction *performSelector = [SKAction performSelector:@selector(checkMovement) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[group, performSelector]];
        [_frog runAction:sequence];
    }
    else if (side == 2)
    {
        CGVector negDelta = CGVectorMake(-_frogMoveDistance,0);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.1];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationLeft]];
        SKAction *performSelector = [SKAction performSelector:@selector(checkMovement) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[group, performSelector]];
        [_frog runAction:sequence];
    }
    else if (side == 3)
    {
        CGVector negDelta = CGVectorMake(0,-_frogMoveDistance);
        SKAction *actionMove = [SKAction moveBy:negDelta duration:0.1];
        SKAction *group = [SKAction group:@[actionMove, _frogAnimationBackward]];
        SKAction *performSelector = [SKAction performSelector:@selector(checkMovement) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[group, performSelector]];
        [_frog runAction:sequence];
    }
//    _isMoving = NO;
//    SKAction *wait = [SKAction waitForDuration:1];
//    SKAction *performSelector = [SKAction performSelector:@selector(respawnFrog) onTarget:self];
//    SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
//    [self runAction:sequence];

}

- (void)checkMovement
{
    _isMoving = NO;
    _isFloating = NO;
    [self checkCollisions];
    if (_frog.position.y > (_dirtStart.size.height + _grass.size.height + _stone.size.height) &&
        _frog.position.y < (self.scene.size.height - 64) && !_isFloating)
    {
        NSLog(@"DIED IN WATER");
        
        // Check Achievement Status
        if (![_gcSingleton.achievementsDictionary objectForKey:@"sleepWithFishes"])
        {
            //[_gcSingleton reportAchievementIdentifier:@"sleepWithFishes" percentComplete:100.0];
            
            GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: @"sleepWithFishes"];
            achievement.percentComplete = 100.0;
            achievement.showsCompletionBanner = YES;
            
            NSArray *achievementArray = @[achievement];
            
            [_gcSingleton reportAchievements:achievementArray];
        }
        
        [[self scene] runAction:_waterSound];
        _lives--;
        _livesLabel.text = [NSString stringWithFormat:@"Lives %d", _lives];
        
        _death = _death = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Frog Death/death"]];
        _death.position = CGPointMake(_frog.position.x, _frog.position.y);
        _death.zPosition = 500;
        [_frog removeFromParent];
        [self addChild:_death];
        
        SKAction *wait = [SKAction waitForDuration:1];
        SKAction *performSelector = [SKAction performSelector:@selector(respawnFrog) onTarget:self];
        SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
        [self runAction:sequence];
    }
}

- (void)spawnFlys:(int)num
{
    for (int i = 0, j = num; i<j; i++)
    {
        SKSpriteNode *fly = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Collection/fly"]];
        fly.name = @"fly";
        fly.zPosition = 500;
        
        CGPoint flyScenePos = CGPointMake(ScalarRandomRange(0, self.size.width),ScalarRandomRange(0, self.size.height-50));
        fly.position = [self convertPoint:flyScenePos toNode:self];
        
        [self addChild:fly];
    }
    
    

}


-(void)spawnSnail
{
    SKSpriteNode *snail = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Enemies/snail1"]];
//    _snail.position = CGPointMake(300, 300);
//    snail.xScale = 1.5;
//    snail.yScale = 1.5;
    snail.zPosition = 300;
    snail.name = @"snail";
    
    CGPoint snailScenePos = CGPointMake(self.size.width + snail.size.width/2,ScalarRandomRange(snail.size.width, _grass.size.height));
    snail.position = [self convertPoint:snailScenePos toNode:self];
    
    [self addChild:snail];
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-snail.size.width/2,snail.position.y) duration:5.0];
    SKAction *actionRemove = [SKAction removeFromParent];
    SKAction *repeatAnimation = [SKAction repeatAction:_snailAnimation count:10.0];
    SKAction *group = [SKAction group:@[actionMove, repeatAnimation]];
    [snail runAction:[SKAction sequence:@[group, actionRemove]]];
}

- (void)spawnLily:(int)position
{
    switch (position)
    {
        case 1:
        {
            SKSpriteNode *lily = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/lily"]];
            lily.name = @"lily";
            CGPoint lilyScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-64-_water.frame.size.height+32);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+16);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+16);
            }
            lily.position = [self convertPoint:lilyScenePos toNode:self];
            [self addChild:lily];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(-lily.size.width/2,lily.position.y) duration:10.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [lily runAction:[SKAction sequence:@[actionMove, actionRemove]]];
        }
        case 2:
        {
            SKSpriteNode *lily = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/lily"]];
            lily.name = @"lily";
            CGPoint lilyScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-64-_water.frame.size.height+2*64+32+5);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+2*32+16+1);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+2*32+16+7);
            }
            lily.position = [self convertPoint:lilyScenePos toNode:self];
            [self addChild:lily];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(-lily.size.width/2,lily.position.y) duration:8.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [lily runAction:[SKAction sequence:@[actionMove, actionRemove]]];
        }
        case 3:
        {
            SKSpriteNode *lily = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/lily"]];
            lily.name = @"lily";
            CGPoint lilyScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-64-_water.frame.size.height+4*64+32+5);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+4*32+16+1);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                lilyScenePos = CGPointMake(self.size.width + lily.size.width/2,self.frame.size.height-32-_water.frame.size.height+4*32+16+10);
            }
            lily.position = [self convertPoint:lilyScenePos toNode:self];
            [self addChild:lily];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(-lily.size.width/2,lily.position.y) duration:5.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [lily runAction:[SKAction sequence:@[actionMove, actionRemove]]];
        }
        default:
            break;
    }
}

- (void)spawnLog:(int)position
{
    switch (position)
    {
        case 1:
        {
            SKSpriteNode *log = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/log"]];
            log.name = @"log";
            //log.yScale = 0.8;
            CGPoint logScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-64-_water.frame.size.height+64+32+5);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+32+16+1);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+32+16+5);
            }
            log.position = [self convertPoint:logScenePos toNode:self];
            [self addChild:log];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(self.size.width + log.size.width/2,log.position.y) duration:10.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [log runAction:[SKAction sequence:@[actionMove, actionRemove]]];
            break;
        }
        case 2:
        {
            SKSpriteNode *log = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/log"]];
            log.name = @"log";
            CGPoint logScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-64-_water.frame.size.height+3*64+32+5);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+3*32+16+1);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+3*32+16+9);
            }
            log.position = [self convertPoint:logScenePos toNode:self];
            [self addChild:log];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(self.size.width + log.size.width/2,log.position.y) duration:20.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [log runAction:[SKAction sequence:@[actionMove, actionRemove]]];
            break;
        }
        case 3:
        {
            SKSpriteNode *log = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Objects/log"]];
            log.name = @"log";
            //log.yScale = 0.7;
            CGPoint logScenePos;
            if ([_sceneAtlas  isEqual: @"Ipad"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-64-_water.frame.size.height+5*64+32+5);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+5*32+16+1);
            }
            else if ([_sceneAtlas  isEqual: @"Iphone5"])
            {
                logScenePos = CGPointMake(0 - log.size.width/2,self.frame.size.height-32-_water.frame.size.height+5*32+16+13);
            }
            log.position = [self convertPoint:logScenePos toNode:self];
            [self addChild:log];
            
            SKAction *actionMove = [SKAction moveTo:CGPointMake(self.size.width + log.size.width/2,log.position.y) duration:15.0];
            SKAction *actionRemove = [SKAction removeFromParent];
            [log runAction:[SKAction sequence:@[actionMove, actionRemove]]];
            break;
        }
            
        default:
            break;
    }
    
}

- (void)checkCollisions
{
    
    [self enumerateChildNodesWithName:@"finish" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *finish = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(finish.frame, 0, 15);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame))
         {
             NSLog(@"Collision detected");
             if (_flies == 6)
             {
                 SKAction *wait = [SKAction waitForDuration:0.4];
                 SKAction *performSelector = [SKAction performSelector:@selector(winGame) onTarget:self];
                 SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
                 [self runAction:sequence];
             }
         }
     }];
    
    if (_death) {return;}
    
    [self enumerateChildNodesWithName:@"snail" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *snail = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(snail.frame, 10, 10);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame))
         {
             NSLog(@"Collision detected");
             [[self scene] runAction:[SKAction playSoundFileNamed:@"frogGroan.wav" waitForCompletion:YES]];
             _lives--;
             _livesLabel.text = [NSString stringWithFormat:@"Lives %d", _lives];
             
             _death = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Frog Death/death"]];
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
    
    [self enumerateChildNodesWithName:@"fly" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *fly = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(fly.frame, 5, 5);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame))
         {
             NSLog(@"Collision detected");
             _flies ++;
             _flyLabel.text = [NSString stringWithFormat:@"Flies %d of 6", _flies];
             [fly removeFromParent];
         }
     }];
    
    if (_isMoving) {return;}
    
    [self enumerateChildNodesWithName:@"lily" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *lily = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(lily.frame, 10, 10);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame))
         {
             NSLog(@"Collision detected");
             _isFloating = YES;
             [self frogFloat:lily];
             
         }
     }];
    
    [self enumerateChildNodesWithName:@"log" usingBlock:^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *log = (SKSpriteNode *)node;
         CGRect smallerFrame = CGRectInset(log.frame, 10, 10);
         if (CGRectIntersectsRect(smallerFrame, _frog.frame))
         {
             NSLog(@"Collision detected");
             _isFloating = YES;
             [self frogFloat:log];
             
         }
     }];
    
//    if (!_isMoving && !_isFloating) {
//        [self enumerateChildNodesWithName:@"water" usingBlock:^(SKNode *node, BOOL *stop)
//         {
//             SKSpriteNode *water = (SKSpriteNode *)node;
//             CGRect smallerFrame = CGRectInset(water.frame, 20, 20);
//             if (CGRectIntersectsRect(smallerFrame, _frog.frame)) {
//                 NSLog(@"Collision detected");
//                 [[self scene] runAction:_waterSound];
//                 _lives--;
//                 [_frog removeFromParent];
//                 [self respawnFrog];
//             }
//         }];
//    }
    
    
}

- (void)frogFloat:(SKSpriteNode*)node
{
    SKAction *actionMove;
    if ([node.name  isEqual: @"lily"])
    {
        actionMove = [SKAction moveTo:CGPointMake(node.position.x-15,node.position.y) duration:0.1];
    }
    else if ([node.name  isEqual: @"log"]){
        actionMove = [SKAction moveTo:CGPointMake(node.position.x,node.position.y) duration:0.1];
    }
    
    [_frog runAction:actionMove];
    
}

- (void)respawnFrog
{
    [_death removeFromParent];
    _death = nil;
    
    _frog = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed: @"Frog Forward/frog1"]];
    _frog.position = _frogRespawnPos;
    _frog.name = @"frog";
    _frog.zPosition = 300;
    _frog.userInteractionEnabled = YES;
    _frogSound = [SKAction playSoundFileNamed:@"frogJump.wav" waitForCompletion:NO];
    _isMoving = NO;
    [self addChild:_frog];
}

- (void)winGame
{
    _win = YES;
}

- (void)showLabel
{
    if (self.view.paused)
    {
        [_pauseLabel removeFromParent];
        [self pauseGame];
    }
    else
    {
        [self addChild:_pauseLabel];
        [self runAction:[SKAction waitForDuration:0.1] completion:^{
            [self pauseGame];
        }];
        
    }
}

- (void)pauseGame
{
    if (self.view.paused)
    {
        self.view.paused = NO;
    }
    else
    {
        self.view.paused = YES;
    }
    
}

// Pause button
//- (SKSpriteNode *)pauseButtonNode
//{
//    SKSpriteNode *pauseNode = [SKSpriteNode spriteNodeWithImageNamed:@"fireButton.png"];
//    fireNode.position = CGPointMake(fireButtonX,fireButtonY);
//    fireNode.name = @"fireButtonNode";//how the node is identified later
//    fireNode.zPosition = 1.0;
//    return fireNode;
//}

- (void)setupScene:(DeviceType)deviceType
{
    switch (deviceType) {
        case 0:
            _livesLabel.position = CGPointMake(35, 460);
            _livesLabel.fontSize = 20;
            _frog.position = CGPointMake(160, 16);
            _water.position = CGPointMake(160, 352);
            _dirtStart.position = CGPointMake(160, 16);
            _dirtFinish.position = CGPointMake(160, 464);
            _stone.position = CGPointMake(160, 240);
            _grass.position = CGPointMake(160, 128);
            
            _pauseBtn.position = CGPointMake(20, 16);
            _pauseLabel.fontSize = 50;
            
            _frogRespawnPos = CGPointMake(160, 16);
            break;
        case 1:
            _livesLabel.position = CGPointMake(35, 540);
            _livesLabel.fontSize = 20;
            _frog.position = CGPointMake(160, 16);
            _water.position = CGPointMake(160, 425.7);
            _dirtStart.position = CGPointMake(160, 18);
            _dirtFinish.position = CGPointMake(160, 550);
            _stone.position = CGPointMake(160, 301);
            _grass.position = CGPointMake(160, 159);
            
            _pauseBtn.position = CGPointMake(20, 16);
            _pauseLabel.fontSize = 50;
            
            _frogRespawnPos = CGPointMake(160, 16);
            break;
        case 2:
            _livesLabel.position = CGPointMake(65, 980);
            _livesLabel.fontSize = 35;
            _frog.position = CGPointMake(384, 32);
            _water.position = CGPointMake(384, 767);
            _dirtStart.position = CGPointMake(384, 33);
            _dirtFinish.position = CGPointMake(384, 991);
            _stone.position = CGPointMake(384, 545);
            _grass.position = CGPointMake(384, 289);
            _pauseBtn.position = CGPointMake(40, 29);
            _pauseLabel.fontSize = 130;
            _flyLabel.position = CGPointMake(680, 995);
            _flyLabel.fontSize = 25;
            _countDownLabel.position = CGPointMake(650, 965);
            _countDownLabel.fontSize = 25;
            _countDownLabelNumber.position = CGPointMake(720, 965);
            _countDownLabelNumber.fontSize = 25;
        
            _frogRespawnPos = CGPointMake(384, 32);
            break;
            
        default:
            break;
    }
}

- (BOOL)currentNetworkStatus
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    BOOL connected;
    BOOL isConnected;
    const char *host = "www.apple.com";
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host);
    SCNetworkReachabilityFlags flags;
    connected = SCNetworkReachabilityGetFlags(reachability, &flags);
    isConnected = NO;
    isConnected = connected && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
    CFRelease(reachability);
    return isConnected;
}


@end
