//
//  UIPlaceHolderTextView.h
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copied from http://stackoverflow.com/questions/1328638/placeholder-in-uitextview
//

#import <UIKit/UIKit.h>

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
