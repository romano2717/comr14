//
//  IssueListPerPoViewController.h
//  comress
//
//  Created by Diffy Romano on 22/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IssueListPerPoViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITableView *issuesTableView;

@property (nonatomic, strong) NSDictionary *poDict;

@end
