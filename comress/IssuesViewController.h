//
//  IssuesViewController.h
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "IssuesTableViewCell.h"
#import "IssuesPerPoTableViewCell.h"
#import "IssuesChatViewController.h"
#import "Comment.h"
#import "Users.h"
#import "Database.h"
#import "MESegmentedControl.h"
#import "CloseIssueActionViewController.h"
#import "MZFormSheetController.h"
#import "MZCustomTransition.h"
#import "MZFormSheetSegue.h"
#import "Synchronize.h"
#import "IssueListPerPoViewController.h"
#import "CustomBadge.h"

@interface IssuesViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,IssuesChatViewControllerDelegate,MZFormSheetBackgroundWindowDelegate>
{
    Post *post;
    IssuesTableViewCell *issuesCell;
    Comment *comment;
    Users *user;
    Database *myDatabase;
    
    BOOL PMisLoggedIn;
    BOOL POisLoggedIn;
}

@property (nonatomic, weak) IBOutlet UITableView *issuesTable;
@property (nonatomic, strong) IBOutlet MESegmentedControl *segment;
@property (nonatomic, weak) IBOutlet UIButton *bulbButton;


@end
