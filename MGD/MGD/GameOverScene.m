//
//  GameOverScene.m
//  MGD
//
//  Created by Aaron Burke on 5/21/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"
#import "MenuScene.h"
#import <GameKit/GameKit.h>
#import "GCSingleton.h"
#import "LocalScoreBoardTableVC.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>


#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

typedef NS_ENUM(NSInteger, DeviceType)
{
    DeviceType_Iphone3in = 0,
    DeviceType_Iphone4in = 1,
    DeviceType_Ipad = 2,
    
};

@implementation GameOverScene 
{
    NSString *_sceneAtlas;
    
    SKSpriteNode *_background;
    SKSpriteNode *_menuBtn;
    SKSpriteNode *_playBtn;
    
    DeviceType _deviceType;
}


- (id)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size]) {
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithUTF8String:machine];
        free(machine);
        
        if ([platform hasPrefix:@"iPad3,"]){
            _sceneAtlas = @"Ipad";
            _deviceType = DeviceType_Ipad;
        } else if ([platform hasPrefix:@"iPhone5,"]) {
            _sceneAtlas = @"Iphone5";
            _deviceType = DeviceType_Iphone4in;
        } else if ([platform hasPrefix:@"iPad2,"]) {
            _sceneAtlas = @"Ipad";
            _deviceType = DeviceType_Ipad;
        } else if ([platform isEqualToString:@"x86_64"]) {
            // for simulator
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                if (IS_WIDESCREEN) {
                    _sceneAtlas = @"Iphone5";
                    _deviceType = DeviceType_Iphone4in;
                } else {
                    _sceneAtlas = @"Iphone";
                    _deviceType = DeviceType_Iphone3in;
                }
            } else {
                _sceneAtlas = @"Ipad";
                _deviceType = DeviceType_Ipad;
            }
        }
    
        if (won) {
            _background = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Scene/win"]];
            
            SKAction *wait = [SKAction waitForDuration:1];
            SKAction *performSelector = [SKAction performSelector:@selector(launchLeaderBoard) onTarget:self];
            SKAction *sequence = [SKAction sequence:@[wait, performSelector]];
            [self runAction:sequence];
        } else {
        
            _background = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Scene/lose"]];
        }
        
        _background.name = @"background";
        _background.userInteractionEnabled = NO;
        _background.position = CGPointMake(self.scene.size.width/2, self.scene.size.height/2);
        
        [self addChild:_background];
        
        _playBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Buttons/start-play-button"]];
        _playBtn.name = @"playBtn";
        _playBtn.userInteractionEnabled = NO;
        
        _menuBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Buttons/start-menu-button"]];
        _menuBtn.name = @"menuBtn";
        _menuBtn.userInteractionEnabled = NO;
        
        NSArray *nodes = @[_playBtn, _menuBtn];
        [self setupScene:_deviceType];
        for (SKSpriteNode *node in nodes) {
            [self addChild:node];
        }
        
//        // Start the game over
//        SKAction * wait = [SKAction waitForDuration:3.0];
//        SKAction * block = [SKAction runBlock:^{
//            MyScene * myScene = [[MyScene alloc] initWithSize:self.size];
//            SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
//            [self.view presentScene:myScene transition: transition];
//        }];
//        [self runAction:[SKAction sequence:@[wait, block]]];
        
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.scene];
    SKNode *node = [self nodeAtPoint:location];
    
    if ([node.name isEqualToString:@"playBtn"]) {
        NSLog(@"Play Btn selected");
        [self playAction];
    } else if ([node.name isEqualToString:@"menuBtn"]) {
        NSLog(@"Menu Btn selected");
        [self menuAction];
    }
    
}

- (void)playAction
{
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.4 duration:0.1];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1 duration:0.1];
    SKAction *performSelector = [SKAction performSelector:@selector(launchGame) onTarget:self];
    [_playBtn runAction:[SKAction sequence:@[fadeOut, fadeIn, performSelector]]];
    
    
    
}

- (void)menuAction
{
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.4 duration:0.1];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1 duration:0.1];
    SKAction *performSelector = [SKAction performSelector:@selector(launchMenu) onTarget:self];
    [_menuBtn runAction:[SKAction sequence:@[fadeOut, fadeIn, performSelector]]];
}

- (void)launchGame
{
    MyScene *myScene = [[MyScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:myScene transition:transition];
}

- (void)launchMenu
{
    MenuScene *menuScene = [[MenuScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:menuScene transition:transition];
}

- (void)setupScene:(DeviceType)deviceType
{
    switch (deviceType) {
        case 0:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 131);
            _menuBtn.position = CGPointMake(self.scene.size.width/2, 80);
            break;
        case 1:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 160.0);
            _menuBtn.position = CGPointMake(self.scene.size.width/2, 100.0);
            break;
        case 2:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 210.0);
            _menuBtn.position = CGPointMake(self.scene.size.width/2, 88.0);
            break;
            
        default:
            break;
    }
}

- (void)launchLeaderBoard
{
    BOOL status = [self currentNetworkStatus];
    
    if ([[GCSingleton sharedContext] userAuthenticated] && status) {
        GKGameCenterViewController *leaderboardViewController = [[GKGameCenterViewController alloc] init];
        leaderboardViewController.gameCenterDelegate = self;
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:leaderboardViewController animated:YES completion:nil];
    } else {
        LocalScoreBoardTableVC *scoreTable = [[LocalScoreBoardTableVC alloc] init];
//        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scoreTable];
//        navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//        navController.modalPresentationStyle = UIModalPresentationFormSheet;
//        navController.title = @"Local Score Board";
//        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(launchFacebookPost)];
//        
//        [navController.navigationItem setRightBarButtonItem:button];
        
        scoreTable.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        scoreTable.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:scoreTable animated:YES completion:nil];
    }
    
}

-(void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)currentNetworkStatus {
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
