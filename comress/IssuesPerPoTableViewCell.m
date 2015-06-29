//
//  IssuesPerPoTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 25/6/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesPerPoTableViewCell.h"

@implementation IssuesPerPoTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    int unreadMessage = [[dict valueForKey:@"unreadPost"] intValue];
    
    self.poNameLabel.text = [NSString stringWithFormat:@"%@ (%d)",[dict valueForKey:@"po"],[[dict valueForKey:@"count"] intValue]];

    CustomBadge *customBadge = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d", unreadMessage]];
    customBadge.tag = 900;
    
    CGRect contentViewFrame = self.contentView.frame;
    
    CGRect customBadgeFrame = CGRectMake(0, 0, 30,30);
    customBadgeFrame.origin.x = contentViewFrame.size.width - 30;
    customBadgeFrame.origin.y = (contentViewFrame.size.height / 2) - 15;
    
    [customBadge setFrame:customBadgeFrame];

    [self.contentView addSubview:customBadge];
    
}

@end
