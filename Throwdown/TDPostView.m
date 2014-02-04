//
//  TDPostView.m
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostView.h"

@implementation TDPostView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) awakeFromNib
{
    self.profileImage.layer.cornerRadius = 16.0;
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profileImage.layer.borderWidth = 1.0;
//    [self.profileImage setImage:[UIImage imageWithContentsOfFile:@"prof_pic_med2.png"]];
}

- (void) setPreviewImageFrom:(NSString *)filename
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDDownloadPreviewImageNotification"
                                                        object:self
                                                      userInfo:@{@"imageView":self.previewImage, @"filename":filename}];
}

@end
