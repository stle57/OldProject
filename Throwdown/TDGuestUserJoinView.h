//
//  TDGuestUserJoinView.h
//  Throwdown
//
//  Created by Stephanie Le on 1/2/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
enum {
    kFollow_LabelType,
    kLike_LabelType,
    kComment_LabelType,
    kPost_LabelType
};
typedef NSInteger kLabelType;

@interface TDGuestUserJoinView : UIView
{
    id delegate;
    UIView *AlertView;
}

+(id)guestUserJoinView:(kLabelType)labelType;
-(void)showInView;
@end
