//
//  IssuesViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesViewController.h"
#import "CustomBadge.h"

@interface IssuesViewController ()
{
    BOOL didReorderListForNewIssue;
}

@property (nonatomic, strong) NSArray *postsArray;
@property (nonatomic, strong) NSArray *sectionHeaders;
@property (nonatomic, strong) NSMutableArray *postsNotSeen;

@end

@implementation IssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    myDatabase = [Database sharedMyDbManager];
    
    comment = [[Comment alloc] init];
    user = [[Users alloc] init];
    
    //check what kind of account is logged in
    POisLoggedIn = YES; //CT_NU uses the same logic as PO
    
    
    //PM and CT_SUP have the same function, structure and grouping logic
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PM"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SUP"] || [[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"])
    {
        PMisLoggedIn = YES;
        POisLoggedIn = NO;
    }
    
    
    self.postsNotSeen = [[NSMutableArray alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [self.issuesTable addSubview:refreshControl];

    //notification for pushing chat view after creating a new issue
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoOpenChatViewForPostMe:) name:@"autoOpenChatViewForPostMe" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoOpenChatViewForPostOthers:) name:@"autoOpenChatViewForPostOthers" object:nil];
    
    //notification for reloading issues list when a new issue was downloaded from the server
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadIssuesList) name:@"reloadIssuesList" object:nil];
    
    //notification for reloading issues when app recover from background to active;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchPostFromRecovery) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //turn on bulb icon for new unread posts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleBulbIcon:) name:@"toggleBulbIcon" object:nil];
    
    //overdue issues indicator
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thereAreOVerDueIssues:) name:@"thereAreOVerDueIssues" object:nil];
    
    //when PO close the issue
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeIssueActionSubmitFromList:) name:@"closeIssueActionSubmitFromList" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeCloseIssueActionSubmitFromList) name:@"closeCloseIssueActionSubmitFromList" object:nil];
}

- (void)thereAreOVerDueIssues:(NSNotification *)notif
{
    return;
    //not used
}

- (void)toggleBulbIcon:(NSNotification *)notif
{
    return; //update this code later
    
    NSString *toggle = [[notif userInfo] valueForKey:@"toggle"];
    UIImage *bulbImg = [UIImage imageNamed:[NSString stringWithFormat:@"bulb_%@@2x.png",toggle]];
    [self.bulbButton setImage:bulbImg forState:UIControlStateNormal];
}


- (void)fetchPostFromRecovery
{
    if(myDatabase.initializingComplete == 1)
        [self fetchPostsWithNewIssuesUp:NO];
}

- (IBAction)moveNewIssuesUp:(id)sender
{
    didReorderListForNewIssue = YES;
    
    [self fetchPostsWithNewIssuesUp:YES];
    
    didReorderListForNewIssue = NO;
}

- (void)reloadIssuesList
{
    if(self.isViewLoaded && self.view.window) //only reload the list if this VC is active
        [self fetchPostsWithNewIssuesUp:NO];
}

- (void)autoOpenChatViewForPostMe:(NSNotification *)notif
{
    NSNumber *clientPostId = [NSNumber numberWithLongLong:[[[notif userInfo] valueForKey:@"lastClientPostId"] longLongValue]];
    
    [self performSegueWithIdentifier:@"push_chat_issues" sender:clientPostId];
}

- (void)autoOpenChatViewForPostOthers:(NSNotification *)notif
{
    NSNumber *clientPostId = [NSNumber numberWithLongLong:[[[notif userInfo] valueForKey:@"lastClientPostId"] longLongValue]];
    
    [self performSegueWithIdentifier:@"push_chat_issues" sender:clientPostId];
}

- (IBAction)segmentControlChange:(id)sender
{
    //MESegmentedControl *segment = (MESegmentedControl *)sender;
    //self.segment = segment;
    
    [self fetchPostsWithNewIssuesUp:NO];
}


- (void)refresh:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadNewItems" object:nil];
    
    [(UIRefreshControl *)sender endRefreshing];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    //self.navigationController.navigationBar.hidden = YES;
    self.hidesBottomBarWhenPushed = NO;
    
    [self adjustTableRowHeightForPM];
    
    if(myDatabase.initializingComplete == 1)
    {
        [self fetchPostsWithNewIssuesUp:NO];
        [self setSegmentBadge];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.segment clearBadges];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.issuesTable reloadData];
    
    //test code
    //[post postLIstForSegment:@"OVERDUE" forUserType:@"PO"];
}

- (void)setSegmentBadge
{
    @try {
        __block int meNewCommentsCtr = 0;
        __block int othersNewCommentsBadge = 0;
        __block int overDueNewCommentsDueCtr = 0;
        
        NSDate *now = [NSDate date];
        NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        
        NSDate *daysAgo = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:-overDueDays*24*60*60];
        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
        
        NSNumber *finishedStatus = [NSNumber numberWithInt:4];
        
        if(POisLoggedIn)
        {
            //ME
            if(self.segment.selectedSegmentIndex == 0) //just count how many post in the list found in comment noti
            {
                for (int i = 0; i < self.postsArray.count; i++) {
                    NSString *key = [[[self.postsArray objectAtIndex:i] allKeys] firstObject];

                    if([[[[self.postsArray objectAtIndex:i] objectForKey:key] valueForKey:@"post"] valueForKey:@"post_id"] ==  [NSNull null])
                        continue;
                    
                    NSNumber *thisPostId = [NSNumber numberWithInt:[[[[[self.postsArray objectAtIndex:i] objectForKey:key] valueForKey:@"post"] valueForKey:@"post_id"] intValue]];
                    
                    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        db.traceExecution = NO;
                        FMResultSet *rs = [db executeQuery:@"select * from comment_noti where status = ? and post_id = ?",[NSNumber numberWithInt:1],thisPostId];
                        
                        while ([rs next]) {
                            if([rs intForColumn:@"post_id"] > 0)
                                meNewCommentsCtr++;
                        }
                    }];
                    
                }
                
                [self.segment setBadgeNumber:meNewCommentsCtr forSegmentAtIndex:0];
            }
            
            //OTHERS
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *othersUnReadCommentsRs = [db executeQuery:@"select count(*) as count from comment_noti where status = ? and post_id not in (select p.post_id from post p, blocks_user bu where p.block_id = bu.block_id)",[NSNumber numberWithInt:1]];
                
                if([othersUnReadCommentsRs next])
                {
                    othersNewCommentsBadge = [othersUnReadCommentsRs intForColumn:@"count"];
                    [self.segment setBadgeNumber:othersNewCommentsBadge forSegmentAtIndex:1];
                }
            }];
            
            
            //OVERDUE
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *rs = [db executeQuery:@"select * from post where post_type = 1 and block_id in (select block_id from blocks_user)"];
                
                while ([rs next]) {
                    //due date
                    NSDate *now = [NSDate date];
                    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
                    NSDate *dueDate = [[[NSCalendar currentCalendar] dateFromComponents:comps] dateByAddingTimeInterval:3*23*59*59]; //add 3 days, default calculation in-case the post don't have a duedate(offline) mode
                    NSDate *nowAtZeroHour = [[NSCalendar currentCalendar] dateFromComponents:comps];
                    
                    NSNumber *thePostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                    
                    if([rs dateForColumn:@"dueDate"] != nil)
                        dueDate = [rs dateForColumn:@"dueDate"];
                    
                    int the_status = [rs intForColumn:@"status"];
                    
                    int daysBetween = [self daysBetween:dueDate and:nowAtZeroHour];
                    
                    if(the_status == 4)//closed, don't add to overdue
                        continue;
                    else
                    {
                        if(daysBetween < 0 && the_status != 4) //not overdue and closed, don't add to OVERDUE
                            continue;
                    }

                    FMResultSet *rsCommentNoti = [db executeQuery:@"select post_id from comment_noti where status = ? and post_id = ?",[NSNumber numberWithInt:1], thePostId];
                    
                    while ([rsCommentNoti next]) {
                        if([rsCommentNoti intForColumn:@"post_id"] > 0)
                            overDueNewCommentsDueCtr++;
                    }
                }
            }];
            
            if(overDueNewCommentsDueCtr > 0)
            {
                [self.segment setBadgeNumber:overDueNewCommentsDueCtr forSegmentAtIndex:2];
            }
            
        }
        else if (PMisLoggedIn)
        {
            //ME
            if(self.segment.selectedSegmentIndex == 0)
            {
                NSArray *list = [self.postsArray firstObject];
                
                for (int i = 0; i < list.count; i++) {
                    NSString *key = [[[list objectAtIndex:i] allKeys] firstObject];
                    NSNumber *thisPostId = [NSNumber numberWithInt:[[[[[list objectAtIndex:i] objectForKey:key] valueForKey:@"post"] valueForKey:@"post_id"] intValue]];
                    
                    
                    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        db.traceExecution = NO;
                        FMResultSet *rs = [db executeQuery:@"select * from comment_noti where status = ? and post_id = ?",[NSNumber numberWithInt:1],thisPostId];
                        
                        while ([rs next]) {
                            if([rs intForColumn:@"post_id"] > 0)
                                meNewCommentsCtr++;
                        }
                    }];
                    
                }
                
                [self.segment setBadgeNumber:meNewCommentsCtr forSegmentAtIndex:0];
            }
            
            
            //OTHERS
//            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
//                FMResultSet *othersUnReadCommentsRs = [db executeQuery:@"select count(*) as count from comment_noti where status = ? and post_id not in (select p.post_id from post p, blocks_user bu where p.block_id = bu.block_id)",[NSNumber numberWithInt:1]];
//                
//                if([othersUnReadCommentsRs next])
//                {
//                    othersNewCommentsBadge = [othersUnReadCommentsRs intForColumn:@"count"];
//                    [self.segment setBadgeNumber:othersNewCommentsBadge forSegmentAtIndex:1];
//                }
//            }];
            
            //OVERDUE
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                NSString *q = [NSString stringWithFormat:@"select p.post_id,client_post_id,p.updated_on,p.status,bum.user_id from post p left join block_user_mapping bum on bum.block_id = p.block_id where p.block_id in (select block_id from block_user_mapping where supervisor_id = '%@' or user_id = '%@') and dueDate <= '%f' and status != %@  ",[myDatabase.userDictionary valueForKey:@"user_id"],[myDatabase.userDictionary valueForKey:@"user_id"], timestampDaysAgo, finishedStatus];
                
                FMResultSet *rs = [db executeQuery:q];

                while ([rs next]) {
                    NSNumber *thePostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                    
                    FMResultSet *rsCommentNoti = [db executeQuery:@"select post_id from comment_noti where status = ? and post_id = ?",[NSNumber numberWithInt:1], thePostId];

                    while ([rsCommentNoti next]) {
                        if([rsCommentNoti intForColumn:@"post_id"] > 0)
                            overDueNewCommentsDueCtr++;
                    }
                }
            }];
            
            if(overDueNewCommentsDueCtr > 0)
            {
                [self.segment setBadgeNumber:overDueNewCommentsDueCtr forSegmentAtIndex:2];
            }
        }
        
        //set badge for tabbar
        int totalUnReadIssuesMessagesBadge = meNewCommentsCtr + othersNewCommentsBadge + overDueNewCommentsDueCtr;
        
        if(totalUnReadIssuesMessagesBadge > 0)
            [[self.tabBarController.tabBar.items objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d",totalUnReadIssuesMessagesBadge]];
        else
            [[self.tabBarController.tabBar.items objectAtIndex:0] setBadgeValue:0];
        
        if(overDueNewCommentsDueCtr > 0)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"thereAreOVerDueIssues" object:nil userInfo:@{@"count":[NSNumber numberWithInt:overDueNewCommentsDueCtr]}];
        }
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"Segment excp : %@",exception);
    }
    @finally {
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didDismissJSQMessageComposerViewController:(IssuesChatViewController *)vc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSNumber *postId;
    NSDictionary *dict;
    
    if([sender isKindOfClass:[NSIndexPath class]])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        
        if (self.segment.selectedSegmentIndex == 0)
        {
            if(POisLoggedIn)
                dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            else
                dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
        
        else if(self.segment.selectedSegmentIndex == 1)
        {
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
        else
        {
            if(POisLoggedIn)
                dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            else
                dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
        
        postId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
    }
    else
        postId = sender;
    
    
    if([segue.identifier isEqualToString:@"push_chat_issues"])
    {
        self.tabBarController.tabBar.hidden = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBar.hidden = NO;
        
        int ServerPostId = 0;
        
        if([[[dict objectForKey:postId] objectForKey:@"post"] valueForKey:@"post_id"] != [NSNull null])
            ServerPostId = [[[[dict objectForKey:postId] objectForKey:@"post"] valueForKey:@"post_id"] intValue];
        
        
        BOOL isFiltered = NO;
        BOOL cameFromOverDueList = NO;
        
        if(self.segment.selectedSegmentIndex == 0)
            isFiltered = YES;
        else if(self.segment.selectedSegmentIndex == 1)
            isFiltered = NO;
        else
        {
            isFiltered = YES;
            cameFromOverDueList = YES;
        }
        
        
        IssuesChatViewController *issuesVc = [segue destinationViewController];
        issuesVc.postId = [postId intValue];
        issuesVc.isFiltered = isFiltered;
        issuesVc.delegateModal = self;
        issuesVc.ServerPostId = ServerPostId;
        issuesVc.cameFromOverDueList = cameFromOverDueList;
    }
    else if ([segue.identifier isEqualToString:@"push_issues_list_per_po"])
    {
        IssueListPerPoViewController *isLpp = [segue destinationViewController];
        
        isLpp.poDict = dict;
    }
}

#pragma mark - fetch posts
- (void)fetchPostsWithNewIssuesUp:(BOOL)newIssuesUp
{
    //we don't need to fetch anything while app is in background
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        return;
    
    if(myDatabase.initializingComplete == 0)
        return;
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            post = nil;
            
            self.postsArray = nil;
            
            post = [[Post alloc] init];
            
            NSDictionary *params = @{@"order":@"order by updated_on desc"};
            
            if(self.segment.selectedSegmentIndex == 0)
            {
                if(POisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:YES newIssuesFirst:YES onlyOverDue:NO]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:YES newIssuesFirst:NO onlyOverDue:NO]];
                }
                else if (PMisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:YES newIssuesFirst:YES onlyOverDue:NO]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:YES newIssuesFirst:NO onlyOverDue:NO]];
                    
                    // group the post
                    [self groupPostForGroupType:@"under_by"];
                }
            }
            
            else if(self.segment.selectedSegmentIndex == 1)
            {
                if(POisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:NO newIssuesFirst:YES onlyOverDue:NO]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:NO newIssuesFirst:NO onlyOverDue:NO]];
                    
                    [self groupPostForGroupType:@"under_by"];
                }
                else if (PMisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:NO newIssuesFirst:YES onlyOverDue:NO]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:NO newIssuesFirst:NO onlyOverDue:NO]];
                    
                    // group the post
                    [self groupPostForPM];
                }
                
            }
            else
            {
                if(POisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:YES newIssuesFirst:YES onlyOverDue:YES]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParams:params forPostId:nil filterByBlock:YES newIssuesFirst:NO onlyOverDue:YES]];
                }
                else if (PMisLoggedIn)
                {
                    if(newIssuesUp)
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:YES newIssuesFirst:YES onlyOverDue:YES]];
                    else
                        self.postsArray = [[NSMutableArray alloc] initWithArray:[post fetchIssuesWithParamsForPM:params forPostId:nil filterByBlock:YES newIssuesFirst:NO onlyOverDue:YES]];
                    
                    // group the post
                    [self groupPostForGroupType:@"under_by"];
                }
                
            }
            
            
            //update ui
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.issuesTable reloadData];
                
                //bulb icon toggle
                if(myDatabase.allPostWasSeen == NO)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleBulbIcon" object:nil userInfo:@{@"toggle":@"on"}];
                    });
                    
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleBulbIcon" object:nil userInfo:@{@"toggle":@"off"}];
                    });
                }
            });
        }
        @catch (NSException *exception) {
            DDLogVerbose(@"fetchPostsWithNewIssuesUp: %@ [%@-%@]",exception,THIS_FILE,THIS_METHOD);
        }
        @finally {
            
        }
    
        [self setSegmentBadge];
//    });
}

#pragma mark - grouping of post
- (void)groupPostForGroupType:(NSString *)groupType
{
    NSMutableArray *sectionHeaders = [[NSMutableArray alloc] init];
    
    //reconstruct array to create headers
    for (int i = 0; i < self.postsArray.count; i++) {
        NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:i];
        NSString *topKey = [[top allKeys] objectAtIndex:0];
        
        NSString *post_by = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:groupType];

        if([[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:[NSString stringWithFormat:@"under_by%d",i+1]] != nil)
            [sectionHeaders addObject:[[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:[NSString stringWithFormat:@"under_by%d",i+1]]];
        else
            [sectionHeaders addObject:post_by];
    }
    
    //remove dupes of sections
    NSArray *cleanSectionHeadersArray = [[NSOrderedSet orderedSetWithArray:sectionHeaders] array];
    self.sectionHeaders = nil;
    self.sectionHeaders = cleanSectionHeadersArray;
    
    NSMutableArray *groupedPost = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < cleanSectionHeadersArray.count; i++) {
        
        NSString *section = [cleanSectionHeadersArray objectAtIndex:i];
        
        NSMutableArray *row = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < self.postsArray.count; j++) {
            
            NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:j];
            NSString *topKey = [[top allKeys] objectAtIndex:0];
            NSString *post_by = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:groupType];
            NSString *post_byIncremental = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:[NSString stringWithFormat:@"under_by%d",j+1]];
            
            if([[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:[NSString stringWithFormat:@"under_by%d",i+1]] != nil)
            {
                
                NSString *post_bySamePo = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:[NSString stringWithFormat:@"under_by%d",i+1]];

                if([post_byIncremental isEqualToString:post_bySamePo] && [row containsObject:top] == NO)
                    [row addObject:top];
            }
            else
            {
                if([post_by isEqualToString:section] && [row containsObject:top] == NO)
                {
                    [row addObject:top];
                }
            }
        }
        [groupedPost addObject:row];
    }
    
    self.postsArray = groupedPost;
}

#pragma mark - grouping for PM
- (void)groupPostForPM
{
    NSMutableArray *sectionHeaders = [[NSMutableArray alloc] init];
    
    //reconstruct array to create headers
    for (int i = 0; i < self.postsArray.count; i++) {
        NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:i];
        
        NSString *division = [top valueForKey:@"division"];
        
        [sectionHeaders addObject:division];
    }
    
    //remove dupes of sections
    NSArray *cleanSectionHeadersArray = [[NSOrderedSet orderedSetWithArray:sectionHeaders] array];
    self.sectionHeaders = nil;
    self.sectionHeaders = cleanSectionHeadersArray;
    
    NSMutableArray *groupedPost = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < cleanSectionHeadersArray.count; i++) {
        
        NSString *section = [cleanSectionHeadersArray objectAtIndex:i];
        
        NSMutableArray *row = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < self.postsArray.count; j++) {
            
            NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:j];
            
            NSString *division = [top valueForKey:@"division"];
            
            if([division isEqualToString:section])
            {
                if([row containsObject:top] == NO)
                    [row addObject:top];
            }
        }
        [groupedPost addObject:row];
    }
    
    self.postsArray = groupedPost;
}

#pragma mark - Table view data source
-(void)adjustTableRowHeightForPM
{
    if(PMisLoggedIn && self.segment.selectedSegmentIndex == 1)
        self.issuesTable.estimatedRowHeight = 38.0;
    else
        self.issuesTable.estimatedRowHeight = 115.0;
    
    self.issuesTable.rowHeight = UITableViewAutomaticDimension;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
    long count;
    
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
            count = 1;
        else
            count = self.sectionHeaders.count;
    }
    else if(self.segment.selectedSegmentIndex == 1)
        count = self.sectionHeaders.count;
    else
    {
        if(POisLoggedIn)
            count = 1;
        else
            count = self.sectionHeaders.count;
    }
    
    
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    long count;
    
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
            count = self.postsArray.count;
        else
            count = [[self.postsArray objectAtIndex:section] count];
    }
    
    else if(self.segment.selectedSegmentIndex == 1)
        count = [[self.postsArray objectAtIndex:section] count];
    else
    {
        if(POisLoggedIn)
            count = self.postsArray.count;
        else
            count = [[self.postsArray objectAtIndex:section] count];
    }
    

    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    @try {
        
        static NSString *nonPmCellIdentifier = @"cell";
        static NSString *pmCellIdentifier = @"PMcell";
        
        NSDictionary *dict;
        
        if(self.segment.selectedSegmentIndex == 0)
        {
            if(POisLoggedIn)
                dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            else
                dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
        
        else if(self.segment.selectedSegmentIndex == 1)
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        else
        {
            if(POisLoggedIn)
                dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            else
                dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        }
        
        
        
        if(PMisLoggedIn && self.segment.selectedSegmentIndex == 1) //PM and inside Others segment
        {
            IssuesPerPoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pmCellIdentifier forIndexPath:indexPath];
                
            [cell initCellWithResultSet:dict];
            
            return cell;
        }
        else
        {
            IssuesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nonPmCellIdentifier forIndexPath:indexPath];
            
            [cell initCellWithResultSet:dict forSegment:self.segment.selectedSegmentIndex];
            
            return cell;
        }
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"cellForRowAtIndexPath exception: %@ [%@-%@]",exception,THIS_FILE,THIS_METHOD);
    }
    @finally {
        
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
            return nil;
        else
            return [self.sectionHeaders objectAtIndex:section];
    }
    if(self.segment.selectedSegmentIndex == 1)
        return [self.sectionHeaders objectAtIndex:section];
    else
    {
        if(POisLoggedIn)
            return nil;
        else
            return [self.sectionHeaders objectAtIndex:section];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.segment.selectedSegmentIndex == 1 && PMisLoggedIn)
        [self performSegueWithIdentifier:@"push_issues_list_per_po" sender:indexPath];
    else
        [self performSegueWithIdentifier:@"push_chat_issues" sender:indexPath];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict;
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        else
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else if(self.segment.selectedSegmentIndex == 1)
        dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    else
    {
        if(POisLoggedIn)
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        else
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    
    
    NSDictionary *topDict = (NSDictionary *)[[dict allValues] firstObject];
    NSDictionary *postDict = [topDict valueForKey:@"post"];
    
    int status = [[postDict valueForKey:@"status"] intValue] ? [[postDict valueForKey:@"status"] intValue] : 0;
    
    UITableViewRowAction *close;
    
    if(status == 4)//already closed, no need for action
    {
        close = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Close" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self fetchPostsWithNewIssuesUp:NO];
        }];
        close.backgroundColor = [UIColor darkGrayColor];
    }
    else
    {
        close = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Close" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            
            [self POwillCloseTheIssue:indexPath];
        }];
        close.backgroundColor = [UIColor darkGrayColor];
    }
    
    
    UITableViewRowAction *completed = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Completed" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        //NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:3] withPostDict:dict withActionsDict:nil];
        [self fetchPostsWithNewIssuesUp:NO];
    }];
    completed.backgroundColor = [UIColor greenColor];
    
    UITableViewRowAction *start = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Start" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        //NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:1] withPostDict:dict withActionsDict:nil];
        [self fetchPostsWithNewIssuesUp:NO];
    }];
    start.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *stop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Stop" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        //NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:2] withPostDict:dict withActionsDict:nil];
        [self fetchPostsWithNewIssuesUp:NO];
    }];
    stop.backgroundColor = [UIColor redColor];
    
    
    //enable/disable status change
    switch (status) {
        case 1:
            return  @[stop, completed];
            break;
            
        case 2:
            return  @[start];
            break;
            
        case 3:
            return  @[close];
            break;
            
        case 4:
            return @[close];
            break;
            
        default:
            return  @[start];
            break;
    }
    
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"])
        return  @[start,stop, completed,close];
    else if ([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_NU"])
        return  @[start,stop, completed];
    else
        return  @[start,stop, completed,close];
}

- (void)POwillCloseTheIssue:(NSIndexPath *)indexPath
{
    CloseIssueActionViewController *closeIssueVc = [self.storyboard instantiateViewControllerWithIdentifier:@"CloseIssueActionViewController"];
    closeIssueVc.indexPath = indexPath;
    closeIssueVc.calledFromList = 1;
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:closeIssueVc];
    
    formSheet.presentedFormSheetSize = CGSizeMake(300, 400);
    formSheet.shadowRadius = 2.0;
    formSheet.shadowOpacity = 0.3;
    formSheet.shouldDismissOnBackgroundViewTap = YES;
    formSheet.shouldCenterVertically = YES;
    formSheet.movementWhenKeyboardAppears = MZFormSheetWhenKeyboardAppearsCenterVertically;
    
    // If you want to animate status bar use this code
    formSheet.didTapOnBackgroundViewCompletionHandler = ^(CGPoint location) {
        
    };
    
    formSheet.willPresentCompletionHandler = ^(UIViewController *presentedFSViewController) {
        DDLogVerbose(@"will present");
    };
    formSheet.transitionStyle = MZFormSheetTransitionStyleCustom;
    
    [MZFormSheetController sharedBackgroundWindow].formSheetBackgroundWindowDelegate = self;
    
    [self mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        DDLogVerbose(@"did present");
    }];
    
    formSheet.willDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
        DDLogVerbose(@"will dismiss");
    };
}

- (void)closeIssueActionSubmitFromList:(NSNotification *)notif
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:nil];
    
    NSDictionary *notifDict = [notif userInfo];
    NSIndexPath *indexPath = [notifDict objectForKey:@"indexPath"];
    
    //upload post status change
    NSDictionary *dict;
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        else
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else if(self.segment.selectedSegmentIndex == 1)
        dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    else
    {
        if(POisLoggedIn)
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        else
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    
    
    //save PO action
    NSString *key = [[dict allKeys] objectAtIndex:0];
    
    NSNumber *thePostId = [NSNumber numberWithInt:0];
    if([[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"] != [NSNull null])
        thePostId = [NSNumber numberWithInt:[[[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"] intValue]];
    
    NSNumber *clientPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
    NSDictionary *actionsDict = @{@"actions":[notif userInfo],@"post_id":thePostId,@"client_post_id":clientPostId};
    BOOL issueActionBool =  [post setIssueCloseActionRemarks:actionsDict];
    
    if(issueActionBool)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Synchronize *sync = [Synchronize sharedManager];
            [sync uploadPostStatusChangeFromSelf:NO];
        });
    }
    
    //close the issue
    [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:4] withPostDict:dict withActionsDict:actionsDict];
    [self fetchPostsWithNewIssuesUp:NO];
}

- (void)closeCloseIssueActionSubmitFromList
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:nil];
}

- (void)setPostStatusAtIndexPath:(NSIndexPath *)indexPath withStatus:(NSNumber *)clickedStatus withPostDict:(NSDictionary *)dict withActionsDict:(NSDictionary *)actionsDict
{
    NSNumber *clickedPostId;
    
    if(self.segment.selectedSegmentIndex == 0)
    {
        if(POisLoggedIn)
        {
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
        else
        {
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
        
    }
    else if(self.segment.selectedSegmentIndex == 1)
    {
        dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
    }
    else
    {
        if(POisLoggedIn)
        {
            dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
        else
        {
            dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
    }
    

    //update status of this post
    [post updatePostStatusForClientPostId:clickedPostId withStatus:clickedStatus];
    
    NSString *statusString;
    NSString *closeActionString;
    
    switch ([clickedStatus intValue]) {
        case 1:
            statusString = @"Issue set status Start";
            break;
            
        case 2:
            statusString = @"Issue set status Stop";
            break;
            
        case 3:
            statusString = @"Issue set status Completed";
            break;
            
        case 4:
        {
            statusString = @"Issue set status Close";
            
            NSString *actions = [[actionsDict objectForKey:@"actions"] valueForKey:@"actionsTaken"];
            NSString *remarks = [[actionsDict objectForKey:@"actions"] valueForKey:@"remarks"];
            closeActionString = [NSString stringWithFormat:@"\n\nClosed by: %@\nRemarks: %@",actions,remarks];
            break;
        }
            
            
        default:
            statusString = @"Issue set status Pending";
            break;
    }
    
    
    //create a comment about this post update
    NSDate *date = [NSDate date];
    
    NSDictionary *dictCommentStatus = @{@"client_post_id":clickedPostId, @"text":[NSString stringWithFormat:@"%@ %@",statusString,closeActionString],@"senderId":user.user_id,@"date":date,@"messageType":@"text",@"comment_type":[NSNumber numberWithInt:2]};
    
    [comment saveCommentWithDict:dictCommentStatus];
    
    
    //update post
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *rightNow = [NSDate date];
        
        BOOL upPostDateOn = [db executeUpdate:@"update post set updated_on = ? where client_post_id = ?",rightNow,clickedPostId];
        
        if(!upPostDateOn)
        {
            *rollback = YES;
            return;
        }
    }];
}

 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


- (int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2 {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return (int)[components day]+1;
}

@end
