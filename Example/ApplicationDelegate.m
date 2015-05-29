//
//  MobileFitnessAppDelegate.m
//  MobileFitness
//
//  Created by saras rani on 16/05/10.
//  Copyright TheGreat 2010. All rights reserved.
//



#import "ApplicationDelegate.h"
#import "MIPushNotifications.h"

#define PUSH_NOTIFICATION_SUPPORTED 1

@interface ApplicationDelegate() <MIPushNotificationsDelegate>

@end
@implementation ApplicationDelegate{


}

#pragma mark - Application delegate:


-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    
    
#ifdef PUSH_NOTIFICATION_SUPPORTED
    // Easiest, to make delegate self, but this can be anything:
    [MIPushNotifications startWithLaunchOptions:launchOptions delegate:self];
#endif
    
	return YES;
}

#pragma mark - MIPushNotificationsDelegate:

-(void)handleRemoteNotificationWithPayload:(NSDictionary*)payload receivedWhileInForeground:(BOOL)receivedWhileInForeground{
    
    // Received push... again, this does not have to be in AppDelegate
    
}

#ifdef PUSH_NOTIFICATION_SUPPORTED

#pragma mark - Push iOS callbacks (redirection):

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    [MIPushNotifications application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
}
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    
    [MIPushNotifications application:application didFailToRegisterForRemoteNotificationsWithError:error];
}
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary*)userInfo{
    
    [MIPushNotifications application:application didReceiveRemoteNotification:userInfo];
    
}
#endif

#pragma mark - Other, standard app delegate methods:

/*
-(void)applicationWillTerminate:(UIApplication *)application{}

-(void)applicationDidEnterBackground:(UIApplication *)application{}
-(void)applicationWillEnterForeground:(UIApplication *)application{}

-(void)applicationWillResignActive:(UIApplication *)application{}
-(void)applicationDidBecomeActive:(UIApplication *)application{}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{}
*/

@end
