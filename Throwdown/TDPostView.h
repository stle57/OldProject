//
//  TDPostView.h
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDLikeView.h"
#import "TDTwoButtonView.h"

@protocol TDPostViewDelegate <NSObject>
@optional
-(void)postTouchedFromRow:(NSInteger)row;
-(void)userButtonPressedFromRow:(NSInteger)row;
@end

@interface TDPostView : UITableViewCell
{
    id <TDPostViewDelegate> __unsafe_unretained delegate;
    CGRect origRectOfUserButton;
}

@property (nonatomic, assign) id <TDPostViewDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *createdLabel;
@property (weak, nonatomic) IBOutlet TDLikeView *likeView;
@property (weak, nonatomic) IBOutlet UIView *bottomPaddingLine;
@property (weak, nonatomic) IBOutlet UIButton *userNameButton;
@property (nonatomic, assign) NSInteger row;
@property (strong, nonatomic) NSString *filename;

- (void)setPost:(TDPost *)post;
- (IBAction)userButtonPressed:(UIButton *)sender;

@end
