//
//  MIPushNotifications.m
//  Roskilde
//
//  Created by Lukasz Margielewski on 15/05/15.
//
//

#import "MIPushNotifications.h"
#import "ActionRequest.h"

@interface MIPushNotifications()

@property (nonatomic) NSTimeInterval timestamp_foreground;
@property (nonatomic, assign) id<MIPushNotificationsDelegate>delegate;

@end
@implementation MIPushNotifications{


    
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

static MIPushNotifications *sharedInstance = nil;

+ (instancetype)sharedInstance{
    
    static dispatch_once_t pred;

    
    dispatch_once(&pred, ^{
        sharedInstance = [[MIPushNotifications alloc] init];
    });
    return sharedInstance;
}

-(id)init{

    self = [super init];
    
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}


+ (void)startWithLaunchOptions:(NSDictionary *)launchOptions delegate:(id<MIPushNotificationsDelegate>)delegate{

    [[MIPushNotifications sharedInstance] startWithLaunchOptions:launchOptions delegate:delegate];
}
- (void)startWithLaunchOptions:(NSDictionary *)launchOptions delegate:(id<MIPushNotificationsDelegate>)delegate{

    self.delegate = delegate;
    
    if (launchOptions != nil)
    {
        NSDictionary* dictionary = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil)
        {
            //DLog(@"Launched from push notification: %@", dictionary);
            [MIPushNotifications handleMessageFromRemoteNotification:dictionary receivedWhileInForeground:NO];
        }
    }
}

#pragma mark - Application state changes notifications:

- (void)applicationDidBecomeActive:(NSNotification *)notification{
    
    //DLog(@"MIPushNotifications - Application DID BECOME ACTIVE!!!");
    [MIPushNotifications refreshPushNotificationSettings];
    
}
- (void)applicationWillEnterForeground:(NSNotification *)notification{
    
    sharedInstance.timestamp_foreground = [[NSDate date] timeIntervalSince1970];
    
}


#pragma mark - PUSH Messages:

+ (void)disablePushNotifications{
    
    NSString *pushToken     = [[NSUserDefaults standardUserDefaults] valueForKey:PUSH_DEVICE_TOKEN_KEY];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PUSH_DEVICE_TOKEN_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PUSH_NOTIFICATIONS_DISABLED_BY_USER];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    
    [self updatePushStatusWithOurServerForPushToken:pushToken];
}
+ (BOOL)arePushNotificationsEnabled{
    

    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        
        BOOL isRegisteredForRemoteNotifications = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
        
        return isRegisteredForRemoteNotifications;
    
        
    } else {
        
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        return  (types & UIRemoteNotificationTypeAlert);
    }
    
    return NO;
    
}
+ (void)enablePushNotifications{
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PUSH_NOTIFICATIONS_DISABLED_BY_USER];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //-- Set Notification
    if ([UIApplication instancesRespondToSelector:@selector(registerForRemoteNotifications)])
    {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
}
+ (void)refreshPushNotificationSettings{
    
    BOOL disabled_by_user   = [[NSUserDefaults standardUserDefaults] boolForKey:PUSH_NOTIFICATIONS_DISABLED_BY_USER];
    NSString *pushToken     = [[NSUserDefaults standardUserDefaults] valueForKey:PUSH_DEVICE_TOKEN_KEY];
    
    //DLog(@"PUSH disabled by user: %i | token: %@", disabled_by_user, pushToken);
    
    if (!disabled_by_user && !pushToken) {
        
        ///
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
            [self enablePushNotifications];
        });
        
        //*/
        
        
    }else{
        
       [self updatePushStatusWithOurServerForPushToken:pushToken];
    }
    
    
}


#pragma mark - Push, Apple notification state changes:


+ (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    
    //DLog(@"========");
    NSString * tokenAsString = [[[deviceToken description]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *tokenSaved = [[NSUserDefaults standardUserDefaults] valueForKey:PUSH_DEVICE_TOKEN_KEY];
    
    //DLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", deviceToken);
    //DLog(@"token just received: %@", tokenAsString);
    //DLog(@"token saved  before: %@", tokenSaved);
    
    if (!tokenSaved || ![tokenSaved isEqualToString:tokenAsString]) {
        
        [[NSUserDefaults standardUserDefaults] setValue:tokenAsString forKey:PUSH_DEVICE_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //DLog(@"Did saved token: %@", tokenAsString);
        
        
        
    }else{
        
        //DLog(@"No need to save token ....");
    }
    [self updatePushStatusWithOurServerForPushToken:tokenAsString];
    //DLog(@"========");
    
}
+ (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    
    NSString *pushToken     = [[NSUserDefaults standardUserDefaults] valueForKey:PUSH_DEVICE_TOKEN_KEY];
    //DLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PUSH_DEVICE_TOKEN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [MIPushNotifications updatePushStatusWithOurServerForPushToken:pushToken];
}


#pragma mark - Push, receiving notifications:

+ (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo{
    
    NSTimeInterval tNow = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval secondsAfterForergound = tNow - sharedInstance.timestamp_foreground;
    
    //DLog(@"Received notification secondsAfterForergound:%f %@",secondsAfterForergound, userInfo);
    [MIPushNotifications handleMessageFromRemoteNotification:userInfo receivedWhileInForeground:(secondsAfterForergound > 1)];
    
}


+ (void)handleMessageFromRemoteNotification:(NSDictionary*)userInfo receivedWhileInForeground:(BOOL)receivedWhileInForeground{
    
    [sharedInstance.delegate handleRemoteNotificationWithPayload:userInfo receivedWhileInForeground:receivedWhileInForeground];
    

    
}


#pragma mark - Push handling (mine):

+ (void)updatePushStatusWithOurServerForPushToken:(NSString *)pushToken{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        // production
        // development
        // enterprise
        NSString *cert_name = @"production";
        
#ifdef DEVELOPMENT
        cert_name = @"development";
#endif
        
        NSString *cert_bid = [[[NSBundle mainBundle] infoDictionary] valueForKeyPath:@"CFBundleIdentifier"];
        
        ActionRequest *action = [ActionRequest action:@"push" forClient:nil];
        BOOL isregistered = ([[NSUserDefaults standardUserDefaults] valueForKey:PUSH_DEVICE_TOKEN_KEY]);
        [action addParameters:@{@"register" : @(isregistered), @"cert_name" : cert_name, @"cert_app_id" : cert_bid}];
        
        if (!isregistered && pushToken) {
            [action addParameters:@{PUSH_DEVICE_TOKEN_KEY : pushToken}];
        }
        NSDictionary *response = [action synchronyousRequest];
        
        
        //DLog(@"\n\nPUSH REGISTRATION REQUEST:\n%@\n\nRESPONSE:\n%@", action.requestDictionary, response);
    });
    
}


@end
