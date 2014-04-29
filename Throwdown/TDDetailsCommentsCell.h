//
//  TDDetailsCommentsCellCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDComment.h"
#import "TDUpdatingDateLabel.h"

@protocol TDDetailsCommentsCellDelegate <NSObject>
@optional
- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber;
@end

@interface TDDetailsCommentsCell : UITableViewCell
{
    id <TDDetailsCommentsCellDelegate> __unsafe_unretained delegate;
    NSInteger row;
    TDComment *comment;
    NSInteger commentNumber;
    CGRect origTimeFrame;
    CGRect origRectOfUserButton;
}

@property (nonatomic, assign) id <TDDetailsCommentsCellDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, retain) TDComment *comment;
@property (nonatomic, assign) NSInteger commentNumber;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet TDUpdatingDateLabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *userButton;
@property (nonatomic, assign) CGRect origTimeFrame;

-(void)makeText:(NSString *)text;
-(void)makeTime:(NSDate *)time name:(NSString *)name;
-(IBAction)userButtonPressed:(id)sender;
@end
