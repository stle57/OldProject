//
//  TDAppDelegate.h
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDConstants.h"
#import "TDToastView.h"

@interface TDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (TDAppDelegate*)appDelegate;
-(TDPost *)postWithPostId:(NSNumber *)postId;
+(UIColor *)randomColor;
+(void)fixHeightOfThisLabel:(UILabel *)aLabel;
+(void)fixWidthOfThisLabel:(UILabel *)aLabel;
+(CGFloat)heightOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize;
+ (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
-(void)showToastWithText:(NSString *)text type:(kToastIconType)type gotoPosition:(NSNumber *)positionInApp;
@end
