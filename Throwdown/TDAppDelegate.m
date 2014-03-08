//
//  TDAppDelegate.m
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAppDelegate.h"
#import "TestFlight.h"
#import "TDUserAPI.h"
#import "TDPostAPI.h"

@implementation TDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"6fef227c-c5cb-4505-9502-9052e2819f45"];

    NSString *storyboardId = [[TDUserAPI sharedInstance] isLoggedIn] ? @"HomeViewController" : @"WelcomeViewController";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];

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

+ (TDAppDelegate*)appDelegate
{
	return (TDAppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Post Operations
-(TDPost *)postWithPostId:(NSNumber *)postId
{
    NSArray *posts = [[TDPostAPI sharedInstance] getPosts];
    for (TDPost *post in posts) {
        if (post.postId == postId) {
            return post;
        }
    }

    return nil;
}

#pragma mark - Helpers
+(UIColor *)randomColor
{
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

+(void)fixHeightOfThisLabel:(UILabel *)aLabel
{
    aLabel.frame = CGRectMake(aLabel.frame.origin.x,
                              aLabel.frame.origin.y,
                              aLabel.frame.size.width,
                              [TDAppDelegate heightOfTextForString:aLabel.text
                                                           andFont:aLabel.font
                                                           maxSize:CGSizeMake(aLabel.frame.size.width, MAXFLOAT)]);
}

+(CGFloat)heightOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize
{
    CGSize sizeOfText = [aString boundingRectWithSize: aSize
                                              options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                           attributes: [NSDictionary dictionaryWithObject:aFont
                                                                                   forKey:NSFontAttributeName]
                                              context: nil].size;

    return ceilf(sizeOfText.height);
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
    CGSize sizeOfText = [aString boundingRectWithSize: aSize
                                              options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                           attributes: [NSDictionary dictionaryWithObject:aFont
                                                                                   forKey:NSFontAttributeName]
                                              context: nil].size;

    return ceilf(sizeOfText.width);
}

@end
