//
//  TDRefreshImageView.m
//  Throwdown
//
//  Created by Stephanie Le on 12/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRefreshImageView.h"
@interface TDRefreshImageView ()
@property (nonatomic, retain) NSMutableArray *animationImages;
// (nonatomic, retain) UIImage *cjImage;
@end

@implementation TDRefreshImageView
//@synthesize animationImages;
//@synthesize cjImage;

- (id)initWithFrame:(CGRect)frame {
    debug NSLog(@"***TDRefreshImageView - inside initWithFrame");
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        NSMutableArray *images = [[NSMutableArray alloc] init];
        // first add 0008-0029
        for (int i = 8; i < 30; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-00%02d", i];
            [images addObject:[UIImage imageNamed:imageName]];
        }
        // then add 0100-0029
        for (int i = 0; i < 30; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-01%02d", i];
            [images addObject:[UIImage imageNamed:imageName]];
        }
        // last add 0000-0007
        for (int i = 0; i < 8; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-00%02d", i];
            [images addObject:[UIImage imageNamed:imageName]];
        }
        
        self.image = [UIImage imageNamed:@"ptr-0000"];
        self.animationDuration = 2;
        self.animationImages = [images copy];
        self.userInteractionEnabled = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [self stopAnimating];
    self.animationImages = nil;
}
@end
