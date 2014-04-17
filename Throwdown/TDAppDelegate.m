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

@implementation TDAppDelegate

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"52059d9d37002218b9f7913616f80b1294e806c2"];

    if ([TDConstants flurryKey]) {
        [Flurry setCrashReportingEnabled:NO];
        [Flurry startSession:[TDConstants flurryKey]];
    }
    [TestFlight takeOff:@"6fef227c-c5cb-4505-9502-9052e2819f45"];

    NSString *storyboardId = [[TDUserAPI sharedInstance] isLoggedIn] ? @"HomeViewController" : @"WelcomeViewController";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];

//    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    debug NSLog(@"app launched with options: %@", launchOptions);
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


#pragma mark - Push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[TDCurrentUser sharedInstance] registerDeviceToken:[deviceToken description]];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed device token error: %@", error);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	// debug NSLog(@"Received notification: %@", userInfo);
    // TODO: notify home view controller of new push notification (probably with NSNotification or:
    // UINavigationController *navigationController = (UINavigationController*)_window.rootViewController;
    // TDHomeViewController *homeViewController = (TDHomeViewController *)[navigationController.viewControllers objectAtIndex:0];
}

#pragma mark - app delegate

+ (TDAppDelegate*)appDelegate
{
	return (TDAppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Post Operations
-(TDPost *)postWithPostId:(NSNumber *)postId {
    NSArray *posts = [[TDPostAPI sharedInstance] getPosts];
    for (TDPost *post in posts) {
        if (post.postId == postId) {
            return post;
        }
    }

    return nil;
}

#pragma mark - Helpers
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

        return ceilf(sizeOfText.height);
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

+(void)fixWidthOfThisLabel:(UILabel *)aLabel
{
    aLabel.frame = CGRectMake(aLabel.frame.origin.x,
                              aLabel.frame.origin.y,
                              [TDAppDelegate widthOfTextForString:aLabel.text
                                                          andFont:aLabel.font
                                                          maxSize:CGSizeMake(MAXFLOAT, aLabel.frame.size.height)],
                              aLabel.frame.size.height);
}

+(CGFloat)widthOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize
{
    // iOS7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
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
-(void)showToastWithText:(NSString *)text type:(kToastIconType)type gotoPosition:(NSNumber *)positionInApp
{
    // Remove old ones
    [TDToastView removeOldToasts];

    // Build new one
    TDToastView *toastView = [TDToastView toastView];
    [self.window addSubview:toastView];

    [toastView text:text
               icon:kToastIconType_Warning
       gotoPosition:positionInApp];
    [toastView showToast];
}

@end
