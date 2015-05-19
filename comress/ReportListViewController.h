//
//  ReportListViewController.h
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"

@interface ReportListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    Database *myDatabase;
    BOOL PMisLoggedIn;
    BOOL POisLoggedIn;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, strong) NSArray *reportsArray;
@property (nonatomic, strong) NSArray *headerssArray;

@end
