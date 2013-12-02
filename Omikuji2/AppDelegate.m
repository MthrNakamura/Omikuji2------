//
//  AppDelegate.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "AppDelegate.h"
#import "Reachability.h"

@implementation AppDelegate
@synthesize loggedOut;
@synthesize accessToken;
@synthesize singleAppMode;
@synthesize contentsList;
@synthesize movieId;
@synthesize topURL;
@synthesize qrURL;
@synthesize resultURL;
@synthesize resultMovieId;
@synthesize afterMovieURL;
@synthesize printInfo;
@synthesize soundId;
@synthesize drawerOpenURL, failedCutURL, headerTempURL, paperJammedURL, unusualDataURL, powerErrorURL, paperEmptyURL, pairingUrl;
@synthesize qrErrorMsg, qrResult;
@synthesize receiptImage;
@synthesize printErrorUrl;
@synthesize receiptLoaded;
@synthesize qrErrorCode;
@synthesize pError;
@synthesize networking;
@synthesize alertView;
@synthesize showingAlert;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (int)checkNetworkStatus
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    switch (status) {
        case NotReachable:
            return NO_NETWORK;
        case ReachableViaWWAN:
            return NETWORK_3G;
        case ReachableViaWiFi:
            return NETWORK_WIFI;
        default:
            return -1;
    }
}

@end
