//
//  MenuScene.m
//  MGD
//
//  Created by Aaron Burke on 5/29/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "MenuScene.h"
#import "MyScene.h"
#import "CreditsScene.h"
#import "HelpScene.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

typedef NS_ENUM(NSInteger, DeviceType)
{
    DeviceType_Iphone3in = 0,
    DeviceType_Iphone4in = 1,
    DeviceType_Ipad = 2,
    
};


@implementation MenuScene
{
    NSString *_sceneAtlas;
    
    SKSpriteNode *_creditsBtn;
    SKSpriteNode *_playBtn;
    SKSpriteNode *_helpBtn;
    
    DeviceType _deviceType;
}


-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        
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
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Scene/menu"]];
        background.name = @"background";
        background.userInteractionEnabled = NO;
        background.position = CGPointMake(self.scene.size.width/2, self.scene.size.height/2);
        
        [self addChild:background];
        
        _playBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Buttons/start-play-button"]];
        _playBtn.name = @"playBtn";
        _playBtn.userInteractionEnabled = NO;

        _creditsBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Buttons/menu-credits-button"]];
        _creditsBtn.name = @"creditsBtn";
        _creditsBtn.userInteractionEnabled = NO;
    
        _helpBtn = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Buttons/menu-help-button"]];
        _helpBtn.name = @"helpBtn";
        _helpBtn.userInteractionEnabled = NO;
      
        NSArray *nodes = @[_playBtn, _creditsBtn, _helpBtn];
        [self setupScene:_deviceType];
        for (SKSpriteNode *node in nodes) {
            [self addChild:node];
        }
        
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
    } else if ([node.name isEqualToString:@"creditsBtn"]) {
        NSLog(@"Credits Btn selected");
        [self creditsAction];
    } else if ([node.name isEqualToString:@"helpBtn"]) {
        NSLog(@"Help Btn selected");
        [self helpAction];
    }
    
}

- (void)playAction
{
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.4 duration:0.1];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1 duration:0.1];
    SKAction *performSelector = [SKAction performSelector:@selector(launchGame) onTarget:self];
    [_playBtn runAction:[SKAction sequence:@[fadeOut, fadeIn, performSelector]]];
    
    
    
}

- (void)creditsAction
{
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.4 duration:0.1];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1 duration:0.1];
    SKAction *performSelector = [SKAction performSelector:@selector(launchCredits) onTarget:self];
    [_creditsBtn runAction:[SKAction sequence:@[fadeOut, fadeIn, performSelector]]];
}

- (void)helpAction
{
    SKAction *fadeOut = [SKAction fadeAlphaTo:0.4 duration:0.1];
    SKAction *fadeIn = [SKAction fadeAlphaTo:1 duration:0.1];
    SKAction *performSelector = [SKAction performSelector:@selector(launchHelp) onTarget:self];
    [_helpBtn runAction:[SKAction sequence:@[fadeOut, fadeIn, performSelector]]];
}

- (void)launchGame
{
    MyScene *myScene = [[MyScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:myScene transition:transition];
}

- (void)launchCredits
{
    CreditsScene *creditsScene = [[CreditsScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:creditsScene transition:transition];
}

- (void)launchHelp
{
    HelpScene *helpScene = [[HelpScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:helpScene transition:transition];
}

- (void)setupScene:(DeviceType)deviceType
{
    switch (deviceType) {
        case 0:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 260);
            _creditsBtn.position = CGPointMake(self.scene.size.width/2, 209);
            _helpBtn.position = CGPointMake(self.scene.size.width/2, 150);
            break;
        case 1:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 350);
            _creditsBtn.position = CGPointMake(self.scene.size.width/2, 290);
            _helpBtn.position = CGPointMake(self.scene.size.width/2, 230);
            break;
        case 2:
            _playBtn.position = CGPointMake(self.scene.size.width/2, 596.0);
            _creditsBtn.position = CGPointMake(self.scene.size.width/2, 354.0);
            _helpBtn.position = CGPointMake(self.scene.size.width/2,474.0);
            break;
            
        default:
            break;
    }
}



@end
