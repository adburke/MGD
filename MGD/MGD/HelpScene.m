//
//  HelpScene.m
//  MGD
//
//  Created by Aaron Burke on 5/29/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "HelpScene.h"
#import "MenuScene.h"

#include <sys/types.h>
#include <sys/sysctl.h>

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )


@implementation HelpScene

{
    NSString *_sceneAtlas;
    
    SKLabelNode *_label;
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
        } else if ([platform hasPrefix:@"iPhone5,"]) {
            _sceneAtlas = @"Iphone5";
        } else if ([platform hasPrefix:@"iPad2,"]) {
            _sceneAtlas = @"Ipad";
        } else if ([platform isEqualToString:@"x86_64"]) {
            // for simulator
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                if (IS_WIDESCREEN) {
                    _sceneAtlas = @"Iphone5";
                } else {
                    _sceneAtlas = @"Iphone";
                }
            } else {
                _sceneAtlas = @"Ipad";
            }
        }
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:_sceneAtlas] textureNamed:@"Scene/help"]];
        background.name = @"background";
        background.userInteractionEnabled = NO;
        background.position = CGPointMake(self.scene.size.width/2, self.scene.size.height/2);
        
        [self addChild:background];
        
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


@end
