//
//  CreditsScene.m
//  MGD
//
//  Created by Aaron Burke on 5/29/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "CreditsScene.h"
#import "MenuScene.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

typedef NS_ENUM(NSInteger, DeviceType)
{
    DeviceType_Iphone3in = 0,
    DeviceType_Iphone4in = 1,
    DeviceType_Ipad = 2,
    
};


@implementation CreditsScene

{
    NSString *_sceneAtlas;
    
    SKLabelNode *_label;
    
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
        
        _label = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-CondensedBlack"];
        _label.text = [NSString stringWithFormat:@"Created by Aaron Burke 2014"];
        _label.zPosition = 500;
        _label.position = CGPointMake(self.scene.size.width/2, self.scene.size.height/2);
        
        [self setupScene:_deviceType];
        
        [self addChild:_label];
        
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */

    MenuScene *menuScene = [[MenuScene alloc] initWithSize:self.size];
    SKTransition *transition = [SKTransition flipHorizontalWithDuration:0.5];
    [self.view presentScene:menuScene transition:transition];
    
}

- (void)launchHelp
{
    
}

- (void)setupScene:(DeviceType)deviceType
{
    switch (deviceType) {
        case 0:
            _label.fontSize = 15;
            break;
        case 1:
            _label.fontSize = 15;
            break;
        case 2:
            _label.fontSize = 45;
            break;
        default:
            break;
    }
}

@end
