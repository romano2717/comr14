//
//  ReportListViewController.m
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportListViewController.h"
#import "ReportDetailViewController.h"

@interface ReportListViewController ()

@end

@implementation ReportListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PM"] == YES)
        PMisLoggedIn = YES;
    else if ([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"] == YES)
        POisLoggedIn = YES;
        
    //default by PO
    self.reportsArray = [NSArray arrayWithObjects:@"Survey",@"Feedback Issues", nil];
    
    if(PMisLoggedIn)
        self.reportsArray = [NSArray arrayWithObjects:@"Survey",@"Feedback Issues",@"Average Sentiment", nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_report_detail"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        
        ReportDetailViewController *rdvc = [segue destinationViewController];
        rdvc.reportType = [self.reportsArray objectAtIndex:indexPath.row];
        rdvc.PMisLoggedIn = PMisLoggedIn;
        rdvc.POisLoggedIn = POisLoggedIn;
    }
}

#pragma mark - table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.segment.selectedSegmentIndex == 0)
        return 1;
    else
        return self.headerssArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 0)
        return self.reportsArray.count;
    else
        return [[self.reportsArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 1)
        return [self.headerssArray objectAtIndex:section];
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    
    if(self.segment.selectedSegmentIndex == 0)
        cell.textLabel.text = [self.reportsArray objectAtIndex:indexPath.row];
    else
        cell.textLabel.text = [[self.reportsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_report_detail" sender:indexPath];

}

@end
