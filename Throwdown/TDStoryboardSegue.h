//
//  TDStoryboardSegue.h
//  Throwdown
//
//  Created by Andrew C on 7/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * When subclassing this view you HAVE to call [super perform] and either:
 * [super presentDestination]
 * [super dismissSource]
 * [super popToRoot]
 * in your perform method, before any animations
 * You must then remove screenshots and call [self.destinationViewController view].hidden = NO;
 */
@interface TDStoryboardSegue : UIStoryboardSegue

@property (readonly, nonatomic) UIImageView *screenShotSource;
@property (readonly, nonatomic) UIImageView *screenShotDestination;

- (void)presentDestination;
- (void)dismissSource;
- (void)popToRoot;

@end
