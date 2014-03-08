//
//  TDDetailsCommentsCellCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDComment.h"

@protocol TDDetailsCommentsCellDelegate <NSObject>
@optional
@end

@interface TDDetailsCommentsCell : UITableViewCell
{
    id <TDDetailsCommentsCellDelegate> __unsafe_unretained delegate;
    NSInteger row;
    TDComment *comment;
    CGRect origTimeFrame;
}

@property (nonatomic, assign) id <TDDetailsCommentsCellDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, retain) TDComment *comment;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (nonatomic, assign) CGRect origTimeFrame;

-(void)makeText:(NSString *)text;
-(void)makeTime:(NSDate *)time name:(NSString *)name;
@end
