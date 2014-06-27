//
//  GCSingleton.m
//  MGD
//
//  Created by Aaron Burke on 6/18/14.
//  Copyright (c) 2014 Aaron Burke. All rights reserved.
//

#import "GCSingleton.h"


@implementation GCSingleton

+ (GCSingleton *)sharedContext
{
    static GCSingleton *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[GCSingleton alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        // Check for GC availablility
        _gameCenterAvailable = [self isGameCenterAvailable];
        if (_gameCenterAvailable)
        {
            
            self.localPlayer = [GKLocalPlayer localPlayer];
            
            self.achievementsDictionary = [[NSMutableDictionary alloc] init];
            self.achievementDescrDictionary = [[NSMutableDictionary alloc] init];
            
            // Register notification for authentication state changes
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

- (void)authenticationChanged {
    if ([GKLocalPlayer localPlayer].isAuthenticated && !_userAuthenticated)
    {
        NSLog(@"Authentication changed: player authenticated.");
        _userAuthenticated = TRUE;
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && _userAuthenticated)
    {
        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
    }
    
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (void)authenticateLocalUser {
    
    if (!_gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    
    // Apple code with non-retain functionality added
    __weak typeof(self) weakSelf = self; // removes retain cycle error
    
    __weak GKLocalPlayer *weakPlayer = self.localPlayer;
    
    self.localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil)
        {
            //showAuthenticationDialogWhenReasonable: is an example method name. Create your own method that displays an authentication view when appropriate for your app.
            [weakSelf showAuthenticationDialogWhenReasonable: viewController];

        }
        else if (weakPlayer.isAuthenticated)
        {
            //authenticatedPlayer: is an example method name. Create your own method that is called after the loacal player is authenticated.
            [weakSelf authenticatedPlayer: weakPlayer];
            [weakSelf loadAchievements];
            [weakSelf reportAchievementInfo];
        }
        else
        {
            [weakSelf disableGameCenter];
        }
    };
}

-(void)showAuthenticationDialogWhenReasonable:(UIViewController *)controller
{
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:controller animated:YES completion:nil];
}

-(void)authenticatedPlayer:(GKLocalPlayer *)player
{
    player = self.localPlayer;
}

-(void)disableGameCenter
{
    
}

#pragma Achievement Section

- (void)loadAchievements
{
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
     {
         if (error == nil)
         {
             for (GKAchievement* achievement in achievements)
                 [self.achievementsDictionary setObject: achievement forKey: achievement.identifier];
         }
     }];
}

- (void)reportAchievementIdentifier: (NSString*) identifier percentComplete: (float) percent
{
    GKAchievement *achievement = [self getAchievementForIdentifier:identifier];
    if (achievement)
    {
        achievement.percentComplete = percent;
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 // Log the error.
             }
         }];
    }
}

- (GKAchievement*)getAchievementForIdentifier: (NSString*) identifier
{
    GKAchievement *achievement = [self.achievementsDictionary objectForKey:identifier];
    if (achievement == nil)
    {
        achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
        [self.achievementsDictionary setObject:achievement forKey:achievement.identifier];
    }
    return achievement;
}

- (void)reportAchievementInfo
{
    [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
        if (error != nil)
        {
            NSLog(@"Error in loading achievement descriptions: %@", error);
        }
        if (descriptions != nil)
        {
            for (GKAchievementDescription* descr in descriptions)
            {
                [self.achievementDescrDictionary setObject: descr forKey: descr.identifier];
            }
            NSLog(@"achievement descriptions loaded");
        }
    }];
}

- (void)reportAchievements:(NSArray*)achievements
{
    [GKAchievement reportAchievements: achievements withCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"Error in reporting achievements: %@", error);
         }
         [self loadAchievements];
     }];
}

- (void)resetAchievements
{
    // Clear all locally saved achievement objects.
    self.achievementsDictionary = [[NSMutableDictionary alloc] init];
    // Clear all progress saved on Game Center.
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             // handle the error.
         }
    }];
}



@end
