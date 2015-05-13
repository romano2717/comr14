//
//  Database.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Database.h"

static const int newDatabaseVersion = 3; //this database version is incremented everytime the database version is updated

@implementation Database

@synthesize initializingComplete,userBlocksInitComplete,allPostWasSeen;


+(instancetype)sharedMyDbManager {
    static id sharedMyDbManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyDbManager = [[self alloc] init];
    });
    return sharedMyDbManager;
}

-(id)init {
    if (self = [super init]) {
        initializingComplete = 0;
        userBlocksInitComplete = 0;
        allPostWasSeen = YES;
        
        [self copyDbToDocumentsDir];
        
        _databaseQ = [[FMDatabaseQueue alloc] initWithPath:self.dbPath];
        
        [self createClient];
        
        [self createUser];
        
        [self createAfManager];
        
        [self createDeviceToken];
        
    }
    return self;
}

- (void)createClient
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from client"];
        while ([rs next]) {
            _clientDictionary = [rs resultDictionary];
        }
    }];
    
}

- (void)createUser
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from users where is_active = ?",[NSNumber numberWithInt:1]];
        while ([rs next]) {
            _userDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createDeviceToken
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs  = [db executeQuery:@"select * from device_token"];
        while ([rs next]) {
            _deviceTokenDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createAfManager
{
//    _api_url = @"http://comresstest.selfip.com/ComressMWCF/";
//    _domain = @"http://comresstest.selfip.com/";
    
    _api_url = [NSString stringWithFormat:@"%@%@",[_clientDictionary valueForKey:@"api_url"],app_path];
    _domain = [_clientDictionary valueForKey:@"api_url"];
    
    DDLogVerbose(@"session id: %@",[_clientDictionary valueForKey:@"user_guid"]);
    
    _AfManager = [AFHTTPRequestOperationManager manager];
    _AfManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _AfManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if([_clientDictionary valueForKey:@"user_guid"] != [NSNull null])
        [_AfManager.requestSerializer setValue:[_clientDictionary valueForKey:@"user_guid"] forHTTPHeaderField:@"ComSessionId"];
    
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    policy.allowInvalidCertificates = YES;
    _AfManager.securityPolicy = policy;
}

- (NSString*)dbPath;
{
    NSArray *Paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *DocumentDir = [Paths objectAtIndex:0];
    
    return [DocumentDir stringByAppendingPathComponent:@"comress.sqlite"];
}

- (void)copyDbToDocumentsDir
{
    BOOL isExist;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    isExist = [fileManager fileExistsAtPath:[self dbPath]];
    NSString *FileDB = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"comress.sqlite"];
    if (isExist)
    {
        return;
    }
    else
    {
        NSError *error;
        
        [fileManager copyItemAtPath:FileDB toPath:[self dbPath] error:&error];
        
        if(error)
        {
            DDLogVerbose(@"settings copy error %@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            return;
        }
    }
}

#pragma - mark database migration

-(void)migrateDatabase
{
    __block NSNumber *dbVersionFlag = [NSNumber numberWithInt:0];
    
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsDbVersion = [db executeQuery:@"select version from db_version"];
        
        while ([rsDbVersion next]) {
            dbVersionFlag = [NSNumber numberWithInt:[rsDbVersion intForColumn:@"version"]];
        }
        
    }];
    
    if([dbVersionFlag intValue] == newDatabaseVersion)
        return;//latest db version, don't do any migration
    else
    {
        //create the tables
        NSArray *tablesToCreate = @[
                                    //30-apr-2015: allow crm to add image
                                    @"CREATE TABLE IF NOT EXISTS suv_crm_image (client_crm_image_id INTEGER PRIMARY KEY AUTOINCREMENT, crm_image_id INTEGER DEFAULT (0), client_crm_id INTEGER DEFAULT (0), crm_id INTEGER DEFAULT (0), image_path VARCHAR (300), uploaded BOOLEAN DEFAULT (0));",
                                    //30-apr-2015: allow crm to save post information
                                    @"CREATE TABLE IF NOT EXISTS suv_crm (client_crm_id INTEGER PRIMARY KEY AUTOINCREMENT, crm_id INTEGER DEFAULT (0), client_feed_back_issue_id INTEGER DEFAULT (0), feedback_issue_id INTEGER DEFAULT (0), description VARCHAR (300), postal_code VARCHAR (10), address VARCHAR (100), level VARCHAR (30), no_of_image INTEGER DEFAULT (0));",
                                    
                                    //11-may-2015 when PO close an issue, remarks and/or actions done is required
                                    @"CREATE TABLE post_close_issue_remarks (id INTEGER PRIMARY KEY AUTOINCREMENT, actions_taken VARCHAR (100), remarks VARCHAR (300), post_id INTEGER DEFAULT (0), uploaded INTEGER DEFAULT (0), client_post_id INTEGER DEFAULT (0));"
                                    ];
        
        
        [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            db.traceExecution = YES;
            
            for (int i = 0; i < tablesToCreate.count; i++) {
                BOOL create = [db executeUpdate:[tablesToCreate objectAtIndex:i]];

                if(!create)
                {
                    *rollback = YES;
                    return ;
                }
            }
        }];
        
        
        
        //update db version
        [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            FMResultSet *rsCheckDbVersion = [db executeQuery:@"select version from db_version"];
            if([rsCheckDbVersion next] == NO)
            {
                BOOL insDbVersion = [db executeUpdate:@"insert into db_version(version) values (?)",[NSNumber numberWithInt:newDatabaseVersion]];
                if(!insDbVersion)
                {
                    *rollback = YES;
                    return;
                }
            }
            else
            {
                BOOL insDbVersion = [db executeUpdate:@"update db_version set version = ?",[NSNumber numberWithInt:newDatabaseVersion]];
                if(!insDbVersion)
                {
                    *rollback = YES;
                    return;
                }
            }
        }];
    }
}


- (void)alertMessageWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString
{
    //the wcf is gmt+8 by default :-(
    //NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (void)notifyLocallyWithMessage:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (NSString *)toJsonString:(id)obj
{
    NSError *error;
    NSString *jsonString;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        DDLogVerbose(@"Got an error: %@", error);
    } else {
       jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

- (void)saveImageToComressAlbum:(UIImage *)image
{
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [self.assetsLibrary saveImage:image toAlbum:@"COMRESS" completion:^(NSURL *assetURL, NSError *error) {
        DDLogVerbose(@"Image saved");
    } failure:^(NSError *error) {
        DDLogVerbose(@"ERROR saving image to comress album: %@",error);
    }];
}


@end
