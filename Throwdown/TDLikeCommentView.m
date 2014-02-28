//
//  TDLikeCommentView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLikeCommentView.h"


@implementation TDLikeCommentView

@synthesize delegate;
@synthesize row;

- (void)dealloc
{
    delegate = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:[[[UINib nibWithNibName:@"TDLikeCommentView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0]];

    }
    return self;
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(likeButtonPressedFromRow:)]) {
            [delegate likeButtonPressedFromRow:row];
        }
    }
}

- (IBAction)commentButtonPressed:(UIButton *)sender
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
            [delegate commentButtonPressedFromRow:row];
        }
    }
}

@end
