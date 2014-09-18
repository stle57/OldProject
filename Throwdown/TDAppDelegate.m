//
//  TDAppDelegate.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAppDelegate.h"
#import "TDUserAPI.h"
#import "TDPostAPI.h"
#import "TestFlight.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>
#import "TDAPIClient.h"
#import "TDHomeViewController.h"
#import "TDAnalytics.h"

// Used for class reference:
#import "TDRecordVideoViewController.h"
#import "TDEditVideoViewController.h"
#import "TDCreatePostViewController.h"

@interface TDAppDelegate ()
@property (nonatomic) double lastSeen;
@end

@implementation TDAppDelegate

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"52059d9d37002218b9f7913616f80b1294e806c2"];
    [[TDUserAPI sharedInstance] setCrashlyticsMeta];

    [[TDAnalytics sharedInstance] start];

    if ([TDConstants flurryKey]) {
        [Flurry setCrashReportingEnabled:NO];
        [Flurry startSession:[TDConstants flurryKey]];
    }
    if ([TDConstants environment] != TDEnvProduction) {
        [TestFlight takeOff:@"6fef227c-c5cb-4505-9502-9052e2819f45"];
    }

    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          // This method will be called EACH time the session state changes,
                                          // also for intermediate states and NOT just when the session open
                                          [self sessionStateChanged:session state:state error:error];
                                      }];
    }

    NSString *storyboardId = [[TDUserAPI sharedInstance] isLoggedIn] ? @"HomeViewController" : @"WelcomeViewController";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    
    self.rateUsController = [[TDRateUsController alloc] init];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self openPushNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
    }

    debug NSLog(@"app launched with options: %@", launchOptions);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    self.lastSeen = CFAbsoluteTimeGetCurrent();
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

    // Handle the user leaving the app while the Facebook login dialog is being shown
    // For example: when the user presses the iOS "home" button while the login dialog is active
    [FBAppCall handleDidBecomeActive];

    if (!self.lastSeen || (CFAbsoluteTimeGetCurrent() - self.lastSeen) > kAutomaticRefreshTimeout) {
        debug NSLog(@"Refreshing feed after reopen");
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationReloadHome object:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - iRate override
+ (void)initialize
{
    if ([TDConstants environment] != TDEnvProduction) {
        //set the bundle ID. normally you wouldn't need to do this
        //as it is picked up automatically from your Info.plist file
        //but we want to test with an app that's actually on the store
        [iRate sharedInstance].applicationBundleID = @"us.throwdown.throwdown";
    }
    [iRate sharedInstance].daysUntilPrompt = 2;
    [iRate sharedInstance].eventsUntilPrompt = 20;
    
	[iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    
    //enable preview mode
    [iRate sharedInstance].previewMode = NO;
    
    debug NSLog(@"iRate events=%lu", (unsigned long)[iRate sharedInstance].eventCount);
}

- (BOOL)iRateShouldPromptForRating
{
    if (self.rateUsController != nil) {
        [[TDAppDelegate appDelegate] showToastWithText:@"Like Throwdown? Tap here to rate us!" type:kToastType_RateUs payload:nil delegate:self.rateUsController];
        [[TDAnalytics sharedInstance] logEvent:@"rating_asked"];
    }
    return NO;
}

#pragma mark - Push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[TDCurrentUser sharedInstance] registerDeviceToken:[deviceToken description]];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed device token error: %@", error);
}

/*
 * Called when:
 * - app is open and receives a notification
 * - tapping a notification to open the app
 */
- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	debug NSLog(@"Received notification: %@", userInfo);

    UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    TDHomeViewController *homeViewController = (TDHomeViewController *)[navigationController.viewControllers objectAtIndex:0];

    if ([application applicationState] == UIApplicationStateInactive) {
        // App was re-launched by tapping a notification

        [self openPushNotification:userInfo];

    } else if ([application applicationState] == UIApplicationStateActive) {
        // App is already active, show in-app notification

        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                            object:self
                                                          userInfo:@{@"incrementCount": @1}];


        // Don't show notification when user is creating something on these controllers:
        NSArray *const kControllersNotElegibleForNotification = @[
            [TDRecordVideoViewController class],
            [TDEditVideoViewController class],
            [TDCreatePostViewController class]];
        UIViewController *controller = [TDAppDelegate topMostController];
        if ([kControllersNotElegibleForNotification containsObject:[controller class]]) {
            // containsObject should be returning YES or NO but returns nil !?
        } else {
            NSDictionary *aps = [userInfo objectForKey:@"aps"];
            if (aps && [aps objectForKey:@"alert"]) {
                [[TDAppDelegate appDelegate] showToastWithText:[aps objectForKey:@"alert"]
                                                          type:kToastType_Info
                                                       payload:userInfo
                                                      delegate:homeViewController];
            }
        }
    }
}

- (void)openPushNotification:(NSDictionary *)notification {
    // Reset app badge count when user opens directly
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

    if ([[TDCurrentUser sharedInstance] isLoggedIn]) {

        UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
        TDHomeViewController *homeViewController = (TDHomeViewController *)[navigationController.viewControllers objectAtIndex:0];

        if ([notification objectForKey:@"activity_id"]) {
            [[TDAPIClient sharedInstance] updateActivity:[notification objectForKey:@"activity_id"] seen:YES clicked:YES];
        }

        [homeViewController openPushNotification:notification];
    }
}

#pragma mark - Facebook handling callbacks

// During the Facebook login flow, your app passes control to the Facebook iOS app or Facebook in a mobile browser.
// After authentication, your app will be called back with the session information.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    if (!wasHandled && [[TDCurrentUser sharedInstance] isLoggedIn]) {
        if ([[TDConstants appScheme] isEqualToString:[url scheme]]) {
            UINavigationController *navigationController = (UINavigationController *)_window.rootViewController;
            TDHomeViewController *homeViewController = (TDHomeViewController *)[navigationController.viewControllers objectAtIndex:0];
            [homeViewController openURL:url];
            wasHandled = YES;
            [[TDAnalytics sharedInstance] logEvent:@"open_url" withInfo:[url path] source:sourceApplication];
        }
    }
    return wasHandled;
}

// This method will handle ALL the Facebook session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error success:(void (^)(void))success failure:(void (^)(NSString *error))failure {

    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen) {
        NSLog(@"FB::Session opened");
        [[TDAnalytics sharedInstance] logEvent:@"facebook_connected"];

        // Get the user's name
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            // Result includes:
            //            "first_name" = Andrew;
            //            gender = male;
            //            id = 339540109545923;
            //            "last_name" = Throwers;
            //            link = "https://www.facebook.com/app_scoped_user_id/339540109545923/";
            //            locale = "en_US";
            //            name = "Andrew Throwers";
            //            timezone = "-7";
            //            "updated_time" = "2014-06-26T19:27:41+0000";
            //            verified = 1;

            NSString *name;
            NSString *facebookId;
            if (!error && [result isKindOfClass:[NSDictionary class]]) {
                name = [result objectForKey:@"name"];
                facebookId = [result objectForKey:@"id"];
            } else {
                // See: https://developers.facebook.com/docs/ios/errors
                NSLog(@"FB::Error %@", error);
                [[TDAnalytics sharedInstance] logEvent:@"facebook_error" withInfo:[error description] source:nil];
            }
            if (!name) {
                name = @"Facebook";
            }
            if (!facebookId) {
                if (failure) {
                    [[TDAnalytics sharedInstance] logEvent:@"facebook_error" withInfo:@"failed user info request" source:nil];
                    failure(@"Unknown error");
                }
                return;
            }

            NSString *accessToken = FBSession.activeSession.accessTokenData.accessToken;
            NSDate *expiresAt = FBSession.activeSession.accessTokenData.expirationDate;
            [[TDCurrentUser sharedInstance] registerFacebookAccessToken:accessToken expiresAt:expiresAt userId:facebookId identifier:name callback:^(BOOL registered) {
                if (registered && success) {
                    success();
                } else if (!registered && failure) {
                    failure(@"Unknown error");
                }

            }];
        }];
        return;
    }

    // If the session was closed
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        NSLog(@"FB::Session closed");
        [[TDCurrentUser sharedInstance] unlinkFacebook];
        if (failure) {
            failure(@"Session closed");
        }
    }

    if (error) {
        NSString *alertText;

        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            // If the error requires people using an app to make an action outside of the app in order to recover
            alertText = [FBErrorUtility userMessageForError:error];
            [[TDAnalytics sharedInstance] logEvent:@"facebook_error" withInfo:alertText source:nil];
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            // If the user canceled login, no error.
            NSLog(@"FB::Login User cancelled login");
            alertText = @"Canceled";
            [[TDAnalytics sharedInstance] logEvent:@"facebook_canceled"];
        } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
            // Handle session closures that happen outside of the app
            alertText = @"Login error. Please log in again.";
            [[TDAnalytics sharedInstance] logEvent:@"facebook_error" withInfo:@"FBErrorCategoryAuthenticationReopenSession" source:nil];
        } else {
            // Get more error information from the error
            // https://developers.facebook.com/docs/ios/errors/
            NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
            NSLog(@"FB::Error %@", errorInformation);
            [[TDAnalytics sharedInstance] logEvent:@"facebook_error" withInfo:[error.userInfo description] source:nil];
            alertText = [NSString stringWithFormat:@"Facebook: Unknown Error. Please retry."];
        }
        NSLog(@"FB::Error %@", alertText);

        [FBSession.activeSession closeAndClearTokenInformation];

        if (failure) {
            failure(alertText);
        }
    }
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error {
    [self sessionStateChanged:session state:state error:error success:nil failure:nil];
}


#pragma mark - app delegate

+ (TDAppDelegate*)appDelegate {
	return (TDAppDelegate*)[[UIApplication sharedApplication] delegate];
}

// TODO: These should be moved to helper class
#pragma mark - Helpers

+ (UIViewController *)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

+ (UIColor *)randomColor {
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

+ (void)fixHeightOfThisLabel:(UILabel *)aLabel {
    CGFloat height = [TDAppDelegate heightOfTextForString:aLabel.text
                                 andFont:aLabel.font
                                 maxSize:CGSizeMake(aLabel.frame.size.width, MAXFLOAT)];
    aLabel.frame = CGRectMake(aLabel.frame.origin.x,
                              aLabel.frame.origin.y,
                              aLabel.frame.size.width,
                              height);
}

+ (CGFloat)heightOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize {
    // iOS7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGSize sizeOfText = [aString boundingRectWithSize: aSize
                                                  options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                               attributes: [NSDictionary dictionaryWithObject:aFont
                                                                                       forKey:NSFontAttributeName]
                                                  context: nil].size;

        return ceilf(ceilf(sizeOfText.height) * kTextLineHeight);
    }

// iOS6
// to remove deprecation warning (we already handled that!)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize textSize = [aString sizeWithFont:aFont
                          constrainedToSize:aSize
                              lineBreakMode:NSLineBreakByWordWrapping];
    return textSize.height;
#pragma clang diagnostic pop
}

+ (void)fixWidthOfThisLabel:(UILabel *)aLabel {
    aLabel.frame = CGRectMake(aLabel.frame.origin.x,
                              aLabel.frame.origin.y,
                              [TDAppDelegate widthOfTextForString:aLabel.text
                                                          andFont:aLabel.font
                                                          maxSize:CGSizeMake(MAXFLOAT, aLabel.frame.size.height)],
                              aLabel.frame.size.height);
}

+ (CGFloat)widthOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize {
    // iOS7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGSize sizeOfText = [aString boundingRectWithSize: aSize
                                                  options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                               attributes: [NSDictionary dictionaryWithObject:aFont
                                                                                       forKey:NSFontAttributeName]
                                                  context: nil].size;

        return ceilf(sizeOfText.width);
    }
    
    // iOS6
    // to remove deprecation warning (we already handled that!)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize textSize = [aString sizeWithFont:aFont
                          constrainedToSize:aSize
                              lineBreakMode:NSLineBreakByWordWrapping];
    return textSize.width;
#pragma clang diagnostic pop
}

+ (CGFloat)minWidthOfThisLabel:(UILabel *)aLabel {
    return [TDAppDelegate widthOfTextForString:aLabel.text
                                       andFont:aLabel.font
                                       maxSize:CGSizeMake(MAXFLOAT, aLabel.frame.size.height)];
}

#pragma mark - Image Helpers
+ (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;

    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);

    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }

    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);


    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

#pragma mark - Toast
- (void)showToastWithText:(NSString *)text type:(kToastType)type payload:(NSDictionary *)payload delegate:(id<TDToastViewDelegate>)delegate {
    // Remove old ones
    [TDToastView removeOldToasts];

    // Build new one
    TDToastView *toastView = [TDToastView toastView];
    [self.window addSubview:toastView];

    if (delegate) {
        toastView.delegate = delegate;
    }

    [toastView text:text type:type payload:payload];
    [toastView showToast];
}

@end
