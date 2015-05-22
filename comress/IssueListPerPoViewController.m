//
//  IssueListPerPoViewController.m
//  comress
//
//  Created by Diffy Romano on 22/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssueListPerPoViewController.h"

@interface IssueListPerPoViewController ()

@end

@implementation IssueListPerPoViewController

@synthesize poDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = [poDict valueForKey:@"po"];
    
    post = [[Post alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.postsArray = [post fetchIssuesForPO:[poDict valueForKey:@"po"]];
    
    [self.issuesTableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return self.postsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    @try {
        
        static NSString *nonPmCellIdentifier = @"cell";
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        IssuesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nonPmCellIdentifier forIndexPath:indexPath];
    
        [cell initCellWithResultSet:dict forSegment:0];
    
        return cell;

    }
    @catch (NSException *exception) {
        DDLogVerbose(@"cellForRowAtIndexPath exception: %@ [%@-%@]",exception,THIS_FILE,THIS_METHOD);
    }
    @finally {
        
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_chat_issues" sender:indexPath];
}



@end
