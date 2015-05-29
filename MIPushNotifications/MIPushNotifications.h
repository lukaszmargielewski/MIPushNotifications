//
//  MIPushNotifications.h
//  Roskilde
//
//  Created by Lukasz Margielewski on 15/05/15.
//
//

#import <Foundation/Foundation.h>

@class MIPushNotifications;

@protocol MIPushNotificationsDelegate <NSObject>

-(void)handleRemoteNotificationWithPayload:(NSDictionary*)payload receivedWhileInForeground:(BOOL)receivedWhileInForeground;

@end

@interface MIPushNotifications : NSObject

+ (void)startWithLaunchOptions:(NSDictionary *)launchOptions delegate:(id<MIPushNotificationsDelegate>)delegate;

+ (void)enablePushNotifications;
+ (void)disablePushNotifications;
+ (BOOL)arePushNotificationsEnabled;

+ (void)refreshPushNotificationSettings;

+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

#pragma mark - Push, receiving notifications:

+ (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo;

@end
