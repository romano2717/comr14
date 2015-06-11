//
//  Survey.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Survey.h"

@implementation Survey

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchSurveyForSegment2:(int)segment
{
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    __block BOOL atleastOneOverdueWasFound = NO;
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*24*60*60];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    //don't add overdue survey!
                    if(atleastOneOverdueWasFound == NO)
                    {
                        [row setObject:[NSNumber numberWithBool:NO] forKey:@"overdue"];
                        [surveyArr addObject:row];
                    }
                    else
                        [row setObject:[NSNumber numberWithBool:YES] forKey:@"overdue"];
                    
                }
            }
        }];
    }
    else if (segment == 1)
    {
        NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetSurvey = [db executeQuery:@"select * from su_survey where created_by in (select user_id from block_user_mapping where user_id != ?) order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rsGetSurvey next]) {
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                            continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",clientAddressId,addressId];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        NSArray *cleanSurveyArray = [[NSOrderedSet orderedSetWithArray:surveyArr] array];
        return cleanSurveyArray;
    }
    else
    {
        __block BOOL atleastOneOverdueWasFound = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",[myDatabase.userDictionary valueForKey:@"user_id"]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                if([clientSurveyId intValue] == 0 && [surveyId intValue] == 0)
                    continue;
                
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    if([feedBackId intValue] == 0 && [clientFeedBackId intValue] == 0)
                        continue;
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        if([client_post_id intValue] == 0 && [post_id intValue] == 0)
                            continue;
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*24*60*60];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                        continue;
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,zero,zero];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    if(atleastOneOverdueWasFound == YES)
                    {
                        [surveyArr addObject:row];
                    }
                }
            }
        }];
    }
    
    return surveyArr;
}

- (NSArray *)fetchSurveyForSegmentForPM:(int)segment
{
    __block NSString *currentUser = [myDatabase.userDictionary valueForKey:@"user_id"];
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            db.traceExecution = NO;
            
            FMResultSet *rsGetSurvey = [db executeQuery:@"select * from su_survey where created_by in (select user_id from block_user_mapping where supervisor_id = ? or user_id = ? group by user_id) or created_by = ? order by survey_date desc",currentUser,currentUser,currentUser];
            
            while ([rsGetSurvey next]) {
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        //if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                          //  continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and (client_address_id <> ? or address_id <> ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    
                    if([surveyArr containsObject:groupedDict] == NO)
                        [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        return surveyArr;
    }
    else if (segment == 1)
    {
        NSMutableArray *surveyPerDivArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *rowDict = [[NSMutableDictionary alloc] init];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey su left join block_user_mapping bum on su.created_by = bum.user_id where created_by in (select user_id from block_user_mapping where supervisor_id != ?) group by su.survey_id order by survey_date desc",currentUser];
            
            NSMutableArray *row = [[NSMutableArray alloc] init];
            
            while ([rs next]) {
                
                NSString *division = [rs stringForColumn:@"division"];
                NSString *createdBy = [rs stringForColumn:@"created_by"];
                
                //count how many survey belong to this user
                int count = 0;
                FMResultSet *rsCount = [db executeQuery:@"select count(*) as count from su_survey where created_by = ?",createdBy];
                while ([rsCount next]) {
                    count = [rsCount intForColumn:@"count"];
                }
                
                NSDictionary *rowDictUsers = @{@"createdBy":createdBy,@"count":[NSNumber numberWithInt:count]};
                
                if([row containsObject:rowDictUsers] == NO)
                    [row addObject:rowDictUsers];
                
                [rowDict setObject:row forKey:division];
                
                if([surveyPerDivArray containsObject:rowDict] == NO)
                    [surveyPerDivArray addObject:rowDict];
            }
        }];
        
        DDLogVerbose(@"%@",surveyPerDivArray);
        
        return surveyPerDivArray;
    }
    
    return nil;
}

- (NSArray *)surveyDetailForSegment:(NSInteger)segment forSurveyId:(NSNumber *)surveyId forClientSurveyId:(NSNumber *)clientSurveyId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];

    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_answers sa, su_questions sq where (sa.client_survey_id = ? or sa.survey_id = ?) and ( sa.question_id = sq.question_id)  group by sa.question_id",clientSurveyId,surveyId];
            
            while ([rs next]) {
                [arr addObject:[rs resultDictionary]];
            }
        }];
    }
    
    else
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs;
            if([surveyId intValue] > 0)
                rs = [db executeQuery:@"select * from su_feedback where survey_id = ? order by client_feedback_id desc",surveyId];
            else
                rs = [db executeQuery:@"select * from su_feedback where client_survey_id = ? order by client_feedback_id desc",clientSurveyId];
            
            while ([rs next]) {
                NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                NSMutableArray *postsArray = [[NSMutableArray alloc] init];
                
                [row setObject:[rs resultDictionary] forKey:@"feedback"];
                
                //get address details
                NSNumber *client_address_id = [NSNumber numberWithInt:[rs intForColumn:@"client_address_id"]];
                NSNumber *address_id = [NSNumber numberWithInt:[rs intForColumn:@"address_id"]];
                
                FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",client_address_id,address_id];
                
                while ([rsAdd next]) {
                    [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                }
                
                
                //get post details
                NSNumber *client_feedback_id = [NSNumber numberWithInt:[rs intForColumn:@"client_feedback_id"]];
                NSNumber *feedback_id = [NSNumber numberWithInt:[rs intForColumn:@"feedback_id"]];
                
                FMResultSet *rsFeedBackIssue = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ? or feedback_id = ?",client_feedback_id,feedback_id];
                while ([rsFeedBackIssue next]) {
                    
                    NSNumber *client_post_id = [NSNumber numberWithInt:[rsFeedBackIssue intForColumn:@"client_post_id"]];
                    NSNumber *post_id = [NSNumber numberWithInt:[rsFeedBackIssue intForColumn:@"post_id"]];
                    
                    FMResultSet *rspost = [db executeQuery:@"select * from post where client_post_id = ? or post_id = ?",client_post_id,post_id];
                    
                    while ([rspost next]) {
                        [postsArray addObject:[rspost resultDictionary]];
                    }
                    
                    [row setObject:postsArray forKey:@"post"];
                }
                
                //get contract types
                FMResultSet *rsContractTypes = [db executeQuery:@"select * from contract_type"];
                NSMutableArray *contractTypesArray = [[NSMutableArray alloc] init];
                while ([rsContractTypes next]) {
                    [contractTypesArray addObject:[rsContractTypes resultDictionary]];
                }
                [row setObject:contractTypesArray forKey:@"contractTypes"];
                
                //store!
                [arr addObject:row];
            }
        }];
    }
    
    return arr;
}

- (NSDictionary *)surveyForId:(NSNumber *)surveyId forAddressType:(NSString *)addressType
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        NSDictionary *surveyDict;
        NSDictionary *addressDict;

        int surveyAddressId = 0;
        int residentAddressId = 0;
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            surveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            residentAddressId = [rs intForColumn:@"client_resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        //get address
        if([addressType isEqualToString:@"survey"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:surveyAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        //get address
        if([addressType isEqualToString:@"resident"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:residentAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        if(addressDict != nil)
            [dict setObject:addressDict forKey:@"address"];
        
    }];
    
    return dict;
}


- (NSDictionary *)surveDetailForId:(NSNumber *)surveyId forClientSurveyId:(NSNumber *)clientSurveyId
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ? or survey_id = ?",clientSurveyId,surveyId];
        NSDictionary *surveyDict;
        NSDictionary *residentAddressDict;
        NSDictionary *surveyAddressDict;
        
        int clientSurveyAddressId = 0;
        int clientResidentAddressId = 0;
        
        int surveyAddressId = 0;
        int residentAddressId = 0;
        
        
        
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            clientSurveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            clientResidentAddressId = [rs intForColumn:@"client_resident_address_id"];
            
            surveyAddressId = [rs intForColumn:@"survey_address_id"];
            residentAddressId = [rs intForColumn:@"resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",[NSNumber numberWithInt:clientSurveyAddressId],[NSNumber numberWithInt:surveyAddressId]];
            
            while ([rsAddress next]) {
                surveyAddressDict = [rsAddress resultDictionary];
            }
        
        
            FMResultSet *rsAddress2 = [db executeQuery:@"select * from su_address where (client_address_id = ? or address_id = ?) and (client_address_id > ? and address_id > ?)",[NSNumber numberWithInt:clientResidentAddressId],[NSNumber numberWithInt:residentAddressId],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
            
            while ([rsAddress2 next]) {
                residentAddressDict = [rsAddress2 resultDictionary];
            }
        
        if(residentAddressDict != nil)
            [dict setObject:residentAddressDict forKey:@"residentAddress"];
        
        if(surveyAddressDict != nil)
            [dict setObject:surveyAddressDict forKey:@"surveyAddress"];
        
    }];
    
    return dict;
}

- (NSArray *)fetchSurveyForSegment:(int) segment
{
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    __block BOOL atleastOneOverdueWasFound = NO;
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where isMine = ? order by survey_date desc",[NSNumber numberWithBool:YES]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*24*60*60];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,[NSNumber numberWithInt:0],[NSNumber numberWithInt:0]];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    //don't add overdue survey!
                    if(atleastOneOverdueWasFound == NO)
                    {
                        [row setObject:[NSNumber numberWithBool:NO] forKey:@"overdue"];
                        [surveyArr addObject:row];
                    }
                    else
                        [row setObject:[NSNumber numberWithBool:YES] forKey:@"overdue"];
                    
                }
            }
        }];
    }
    else if(segment == 1)
    {
        NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsGetSurvey = [db executeQuery:@"select created_by from su_survey where isMine = ? group by created_by order by survey_date desc",[NSNumber numberWithBool:NO]];
            
            while ([rsGetSurvey next]) {
                NSString *createdBy = [rsGetSurvey stringForColumn:@"created_by"];
                
                FMResultSet *rs = [db executeQuery:@"select * from su_survey where created_by = ? order by survey_date desc",createdBy];
                
                NSMutableArray *surveyArrRow = [[NSMutableArray alloc] init];
                
                while ([rs next]) {
                    
                    //check if this survey got atleast 1 answer, if not, don't add this survery
                    FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
                    
                    BOOL checkBool = NO;
                    
                    NSMutableArray *answers = [[NSMutableArray alloc] init];
                    while ([check next]) {
                        checkBool = YES;
                        [answers addObject:[check resultDictionary]];
                    }
                    
                    if(checkBool == YES)
                    {
                        
                        NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                        
                        [row setObject:answers forKey:@"answers"];
                        
                        [row setObject:[rs resultDictionary] forKey:@"survey"];
                        
                        //get address details
                        NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                        NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                        
                        if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                            continue;
                        
                        FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ?",clientAddressId,addressId];
                        
                        BOOL thereIsAnAddress = NO;
                        
                        while ([rsAdd next]) {
                            thereIsAnAddress = YES;
                            [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                        }
                        
                        [surveyArrRow addObject:row];
                    }
                }
                if(surveyArrRow.count > 0 && createdBy != nil)
                {
                    [groupedDict setObject:surveyArrRow forKey:createdBy];
                    [surveyArr addObject:groupedDict];
                }
            }
        }];
        
        NSArray *cleanSurveyArray = [[NSOrderedSet orderedSetWithArray:surveyArr] array];
        return cleanSurveyArray;
    }
    else
    {
        __block BOOL atleastOneOverdueWasFound = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_survey where isMine = ? order by survey_date desc",[NSNumber numberWithBool:YES]];
            
            while ([rs next]) {
                
                NSNumber *clientSurveyId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]];
                NSNumber *surveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
                
                if([clientSurveyId intValue] == 0 && [surveyId intValue] == 0)
                    continue;
                
                
                //check if this survey got feedback
                FMResultSet *rsChecFeedB = [db executeQuery:@"select * from su_feedback where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                while ([rsChecFeedB next]) {
                    NSNumber *feedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"feedback_id"]];
                    NSNumber *clientFeedBackId = [NSNumber numberWithInt:[rsChecFeedB intForColumn:@"client_feedback_id"]];
                    
                    if([feedBackId intValue] == 0 && [clientFeedBackId intValue] == 0)
                        continue;
                    
                    //check if this feedback got issues with existing post_id
                    FMResultSet *rsCheckFi = [db executeQuery:@"select * from su_feedback_issue where (client_feedback_id = ? or feedback_id = ?) and (client_post_id != ? or post_id != ?) and (client_feedback_id != ? and feedback_id != ?)",clientFeedBackId,feedBackId,zero,zero,zero,zero];
                    
                    while ([rsCheckFi next]) {
                        NSNumber *client_post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"client_post_id"]];
                        NSNumber *post_id = [NSNumber numberWithInt:[rsCheckFi intForColumn:@"post_id"]];
                        
                        if([client_post_id intValue] == 0 && [post_id intValue] == 0)
                            continue;
                        
                        NSDate *now = [NSDate date];
                        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*24*60*60];
                        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
                        
                        //check if this post is overdue
                        FMResultSet *rsCheckPost = [db executeQuery:@"select * from post where (client_post_id = ? or post_id = ?) and dueDate <= ? and status != ? and (client_post_id != ? and post_id != ?)",client_post_id,post_id,[NSNumber numberWithDouble:timestampDaysAgo],[NSNumber numberWithInt:4],zero,zero];
                        
                        if([rsCheckPost next])
                            atleastOneOverdueWasFound = YES;
                    }
                }
                
                
                
                //check if this survey got atleast 1 answer, if not, don't add this survery
                FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ? and (client_survey_id != ? and survey_id != ?)",clientSurveyId,surveyId,zero,zero];
                
                BOOL checkBool = NO;
                
                NSMutableArray *answers = [[NSMutableArray alloc] init];
                while ([check next]) {
                    checkBool = YES;
                    [answers addObject:[check resultDictionary]];
                }
                
                if(checkBool == YES)
                {
                    
                    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                    
                    [row setObject:answers forKey:@"answers"];
                    
                    [row setObject:[rs resultDictionary] forKey:@"survey"];
                    
                    //get address details
                    NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                    NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                    
                    if([clientAddressId intValue] == 0 && [addressId intValue] == 0)
                        continue;
                    
                    FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or address_id = ? and (client_address_id != ? and address_id != ?)",clientAddressId,addressId,zero,zero];
                    
                    BOOL thereIsAnAddress = NO;
                    
                    while ([rsAdd next]) {
                        thereIsAnAddress = YES;
                        [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                    }
                    
                    if(atleastOneOverdueWasFound == YES)
                    {
                        [surveyArr addObject:row];
                    }
                }
            }
        }];
    }
    
    
    return surveyArr;
}

@end
