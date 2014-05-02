//
//  TDEditVideoViewController.h
//  Throwdown
//
//  Created by Andrew C on 1/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDEditVideoViewController : UIViewController
- (void)editVideoAt:(NSString *)videoPath original:(BOOL)original;
- (void)editPhotoAt:(NSString *)photoPath metadata:(NSDictionary *)metadata;
- (void)editImage:(UIImage *)assetImage;
@end
