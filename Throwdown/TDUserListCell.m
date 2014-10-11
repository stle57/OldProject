//
//  TDUserListCell.m
//  Throwdown
//
//  Created by Andrew C on 7/22/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserListCell.h"
#import "TDConstants.h"

static int const kIndentenation = 68;
static int const kMargin = 68;

@interface TDUserListCell ()

@property (nonatomic) UIView *bottomLine;

@end

@implementation TDUserListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.hidden = YES;
        self.detailTextLabel.hidden = YES;

        self.name = [[UILabel alloc] initWithFrame:CGRectMake(kIndentenation, 5, SCREEN_WIDTH - kMargin, 15)];
        self.name.font = COMMENT_MESSAGE_FONT;
        self.name.textColor = [TDConstants headerTextColor];
        [self addSubview:self.name];

        self.username = [[UILabel alloc] initWithFrame:CGRectMake(kIndentenation, 20, SCREEN_WIDTH - kMargin, 13)];
        self.username.font = [TDConstants fontRegularSized:13.0];
        self.username.textColor = [TDConstants disabledTextColor];
        [self addSubview:self.username];

        self.profileImage = [[UIImageView alloc] initWithFrame:CGRectMake(18, 4, 32, 32)];
        self.profileImage.backgroundColor = [TDConstants darkBackgroundColor];
        self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
        [self.profileImage.layer setCornerRadius:self.profileImage.frame.size.height/2.f];
        [self.profileImage.layer setMasksToBounds:YES];
        [self.profileImage setClipsToBounds:YES];
        self.profileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        [self.contentView addSubview:self.profileImage];

        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(kIndentenation, self.frame.size.height - 5, SCREEN_WIDTH - kMargin, 1.0 / [[UIScreen mainScreen] scale])];
        self.bottomLine.backgroundColor = [TDConstants lightBorderColor];
        [self addSubview:self.bottomLine];
    }
    return self;
}

- (void)dealloc {
    [self.bottomLine removeFromSuperview];
    self.bottomLine = nil;
    [self.profileImage removeFromSuperview];
    self.profileImage = nil;
}

@end
