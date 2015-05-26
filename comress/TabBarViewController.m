//
//  TabBarViewController.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "TabBarViewController.h"
#import "ActivationViewController.h"

@interface TabBarViewController ()
{
    BOOL needToActivate;
    BOOL needToLogin;
}
@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    NSMutableArray *tabbarViewControllers = [NSMutableArray arrayWithArray: [self viewControllers]];
    [tabbarViewControllers removeObjectAtIndex:1]; //temp hide routine
    
    
    //hide svc. ambass, and statistics for contractor and contractor_sa
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_NU"] == YES ||[[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_SA"] == YES)
    {
        [tabbarViewControllers removeObjectAtIndex: 1]; // svc amabassador
        [tabbarViewControllers removeObjectAtIndex: 1]; // statistics
    }
    
    [self setViewControllers: tabbarViewControllers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    needToActivate = NO;
    needToLogin = NO;
    
    //check for a valid activation code
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *activationCode = nil;
        
        FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
        while([rs next])
        {
            activationCode = [rs stringForColumn:@"activation_code"];
        }
        
        if(activationCode == nil || activationCode.length == 0)
        {
            needToActivate = YES;
        }
        else
        {
            //check for active login
            FMResultSet *rsClient = [db executeQuery:@"select c.user_guid, u.* from client c, users u where c.user_guid = u.guid and u.is_active = ?",[NSNumber numberWithInt:1]];
            
            if(![rsClient next])
            {
                needToLogin = YES;
            }
        }
    }];
    
    if(needToActivate)
    {
        [self performSegueWithIdentifier:@"modal_activation" sender:self];
    }
    else if (needToLogin)
    {
        [self performSegueWithIdentifier:@"modal_login" sender:self];
    }
    else
    {
        if(myDatabase.initializingComplete == 0)
        {
            __block BOOL needtoInit = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *rs = [db executeQuery:@"select initialise from client where initialise = ?",[NSNumber numberWithInt:0]];
                if([rs next] == YES)
                    needtoInit = YES;
            }];
            if(needtoInit == YES)
                [self performSegueWithIdentifier:@"modal_initializer" sender:self];
            else if (myDatabase.userBlocksInitComplete == 0 || myDatabase.userBlocksMappingInitComplete == NO)
                [self performSegueWithIdentifier:@"modal_initializer" sender:self];
            
            return;
        }
        else if (myDatabase.userBlocksInitComplete == 0 || myDatabase.userBlocksMappingInitComplete == NO)
        {
            [self performSegueWithIdentifier:@"modal_initializer" sender:self];
            
            return;
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"modal_activation"])
    {
        [segue destinationViewController];
    }
    
    if([segue.identifier isEqualToString:@"modal_login"])
    {
        [segue destinationViewController];
    }
}


@end
