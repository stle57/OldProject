//
//  TDUserListCell.m
//  Throwdown
//
//  Created by Andrew C on 7/22/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserListCell.h"
#import "TDConstants.h"

@interface TDUserListCell ()

@property (nonatomic) UIView *bottomLine;

@end

@implementation TDUserListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.font = [TDConstants fontBoldSized:14.0];
        self.detailTextLabel.font = [TDConstants fontLightSized:12.0];
        self.indentationLevel = 5;
        self.indentationWidth = 6;

        self.profileImage = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
        self.profileImage.backgroundColor = [TDConstants darkBackgroundColor];
        self.profileImage.contentMode = UIViewContentModeScaleAspectFit;
        [self.profileImage.layer setCornerRadius:self.profileImage.frame.size.height/2.f];
        [self.profileImage.layer setMasksToBounds:YES];
        [self.profileImage setClipsToBounds:YES];
        self.profileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        [self.contentView addSubview:self.profileImage];

        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 5, 320, 1.0 / [[UIScreen mainScreen] scale])];
        self.bottomLine.backgroundColor = [TDConstants borderColor];
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
