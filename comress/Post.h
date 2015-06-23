//
//  Post.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Post : NSObject
{
    Database *myDatabase;
}

@property (nonatomic) int client_post_id;
@property (nonatomic) int post_id;
@property (nonatomic, strong) NSString *post_topic;
@property (nonatomic, strong) NSString *post_by;
@property (nonatomic, strong) NSDate *post_date;
@property (nonatomic, strong) NSDate *updated_on;
@property (nonatomic, strong) NSString *post_type;
@property (nonatomic, strong) NSNumber *severity;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSNumber *status;
@property (nonatomic, strong) NSString *level;
@property (nonatomic, strong) NSNumber *block_id;
@property (nonatomic, strong) NSString *postal_code;
@property (nonatomic, strong) NSNumber *seen;
@property (nonatomic, strong) NSNumber *contract_type;

- (long long)savePostWithDictionary:(NSDictionary *)dict;

- (long long)savePostWithDictionary:(NSDictionary *)dict forBlockId:(NSNumber *)blockId;

- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue;

- (NSArray *)fetchIssuesWithParamsForPM:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue;

- (NSArray *)fetchIssuesForPO:(NSString *)poID;

- (NSArray *)postsToSend;

- (BOOL)updatePostStatusForClientPostId:(NSNumber *)clientPostId withStatus:(NSNumber *)theStatus;

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;

- (BOOL)updatePostAsSeen:(NSNumber *)clientPostId serverPostId:(NSNumber *)serverPostId;

-(NSArray *)fetchPostsForBlockId:(NSNumber *)blockId;

- (BOOL)setIssueCloseActionRemarks:(NSDictionary *)dict;

- (NSArray *)searchPostWithKeyword:(NSString *)keyword;

- (NSArray *)postLIstForSegment:(NSString *)segment forUserType:(NSString *)userType;

- (NSDictionary *)postInfoForPostId:(NSNumber *)serverPostId clientPostId:(NSNumber *)clientPostId;

@end
