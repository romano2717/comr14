//
//  SettingsViewController.m
//  comress
//
//  Created by Diffy Romano on 2/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SettingsViewController.h"
#import "Synchronize.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize userFullNameLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    users = [[Users alloc] init];
    client = [[Client alloc] init];
    
    __block NSString *dbVersion;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select version from db_version"];
        while ([rs next]) {
            dbVersion = [NSString stringWithFormat:@"%d",[rs intForColumn:@"version"]];
        }
    }];
    self.versionLabel.text = [NSString stringWithFormat:@"%@|%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],dbVersion];
    
    //get user profile
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select user_guid from client"];
        if([rs next])
        {
            FMResultSet *rs2 = [db executeQuery:@"select * from users where guid = ?",[rs stringForColumn:@"user_guid"]];
            
            if([rs2 next])
                userFullNameLabel.text = [rs2 stringForColumn:@"full_name"];
        }
        
        userFullNameLabel.text = users.full_name;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logout:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.tag = 1;
    [alert show];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"modal_login"])
    {
        [segue destinationViewController];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        if(buttonIndex == 1)
        {
            [self logoutWithRelogin:YES];
        }
    }
}

- (void)logoutWithRelogin:(BOOL )relogin
{
    if([self checkIfSomethingWasNotSync] == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Synchronise" message:@"Cannot sign out at this moment. Synchronise is not yet finished." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alert show];
        
        return;
    }
    
    [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@%@",myDatabase.api_url,api_logout,[myDatabase.clientDictionary valueForKey:@"user_guid"] ] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        if([[dict valueForKey:@"Result"] intValue] == 1)
        {
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                db.traceExecution = NO;
                
                //clear tables
                NSArray *tableToDelete =
                @[@"blocks_last_request_date",
                @"blocks_user",
                @"blocks_user_last_request_date",
                @"comment_last_request_date",
                @"comment_noti_last_request_date",
                @"post_last_request_date",
                @"post_image_last_request_date",
                @"ro_checkarea_last_req_date",
                @"ro_checklist_last_req_date",
                @"ro_job_last_req_date",
                @"ro_scanchecklist_last_req_date",
                @"ro_scanchecklist_blk_last_req_date",
                @"ro_schedule_last_req_date",
                @"ro_user_blk_last_req_date",
                @"su_feedback_issues_last_req_date",
                @"su_questions_last_req_date",
                  @"su_survey_last_req_date"];

                for (int i = 0; i < tableToDelete.count; i++) {
                    NSString *tbl = [NSString stringWithFormat:@"delete from %@",[tableToDelete objectAtIndex:i]];
                    BOOL del = [db executeUpdate:tbl];
                    
                    if(!del)
                    {
                        *rollback = YES;
                        return ;
                    }
                }
                
                
                
                BOOL upClient = [db executeUpdate:@"update client set initialise = ?",[NSNumber numberWithInt:0]];
                if(!upClient)
                {
                    *rollback = YES;
                    return;
                }
                
                
                BOOL q;
                NSNumber *isActiveNo = [NSNumber numberWithInt:0];
                
                q = [db executeUpdate:@"update users set is_active = ? where guid = ?",isActiveNo,[myDatabase.clientDictionary valueForKey:@"user_guid"]];
                
                myDatabase.userBlocksInitComplete = 0;
                myDatabase.initializingComplete = 0;
                
                if(!q)
                {
                    *rollback = YES;
                    return;
                }
                
                //stop sync
                Synchronize *sync = [Synchronize sharedManager];
                sync.stop = YES;
                
            }];
            
            if(!relogin)
                return;
            
            if(self.presentingViewController != nil) //the tab was presented modally, dismiss it first.
            {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            else //the tab was presented at first launch(user previously logged)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self performSegueWithIdentifier:@"modal_login" sender:self];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

- (BOOL)checkIfSomethingWasNotSync
{
    __block BOOL everythingIsSync = YES;
    
    NSNumber *zero = [NSNumber numberWithInt:0]; // haven't uploaded
    NSNumber *one = [NSNumber numberWithInt:1]; //require to sync
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsPostCheck = [db executeQuery:@"select post_id from post where post_id = ?",zero];
        if([rsPostCheck next] == YES)
            everythingIsSync = NO;
        
        FMResultSet *rsSurveyCheck = [db executeQuery:@"select survey_id from su_survey where survey_id = ? and status = ?",zero,one];
        if([rsSurveyCheck next] == YES)
            everythingIsSync = NO;
        
        /*
         comment = comment_id
         post_image = post_image_id, post_id, comment_id
         su_address = address_id
         su_answers = answer_id, survey_id
         su_feedback = feedback_id, survey_id, address_id
         su_feedback_issue = feedback_issue_id, feedback_id, post_id
         */
    }];
    
    return everythingIsSync;
}

- (IBAction)reset:(id)sender
{
    [self logoutWithRelogin:NO];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        [theDb executeUpdate:@"delete from client"];
        
        BOOL qComment = [theDb executeUpdate:@"delete from comment"];
        if(!qComment)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qCommentNoti = [theDb executeUpdate:@"delete from comment_noti"];
        if(!qCommentNoti)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qDToken = [theDb executeUpdate:@"delete from device_token"];
        if(!qDToken)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qPost = [theDb executeUpdate:@"delete from post"];
        if(!qPost)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qPostImg = [theDb executeUpdate:@"delete from post_image"];
        if(!qPostImg)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qUser = [theDb executeUpdate:@"delete from users"];
        if(!qUser)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qBlocks = [theDb executeUpdate:@"delete from blocks"];
        if(!qBlocks)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate = [theDb executeUpdate:@"delete from blocks_last_request_date"];
        if(!qReqDate)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        
        BOOL qBlocks2 = [theDb executeUpdate:@"delete from blocks_user"];
        if(!qBlocks2)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate22 = [theDb executeUpdate:@"delete from blocks_user_last_request_date"];
        if(!qReqDate22)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        
        BOOL qReqDate2 = [theDb executeUpdate:@"delete from comment_last_request_date"];
        if(!qReqDate2)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate3 = [theDb executeUpdate:@"delete from comment_noti_last_request_date"];
        if(!qReqDate3)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate4 = [theDb executeUpdate:@"delete from post_image_last_request_date"];
        if(!qReqDate4)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate5 = [theDb executeUpdate:@"delete from post_last_request_date"];
        if(!qReqDate5)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        //delete images
        NSArray *directoryContents =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] error:NULL];
        
        if([directoryContents count] > 0)
        {
            for (NSString *path in directoryContents)
            {
                NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:path];
                
                NSRange r =[fullPath rangeOfString:@".jpg"];
                if (r.location != NSNotFound || r.length == [@".jpg" length])
                {
                    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                }
            }
        }
        
        myDatabase.initializingComplete = 0;
        myDatabase.userBlocksInitComplete = 0;
    }];
}

- (void)exit
{
    exit(1);
}

@end
