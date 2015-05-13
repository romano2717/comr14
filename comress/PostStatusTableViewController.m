//
//  PostStatusTableViewController.m
//  comress
//
//  Created by Diffy Romano on 15/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostStatusTableViewController.h"
#import "IssuesChatViewController.h"
#import "Database.h"

@interface PostStatusTableViewController ()
{
    Database *myDatabase;
}
@property (nonatomic, strong)NSArray *status;

@end

@implementation PostStatusTableViewController

@synthesize delegate=_delegate,selectedStatus;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    myDatabase = [Database sharedMyDbManager];
    
    if([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"PO"])
        self.status = [NSArray arrayWithObjects:@"Pending",@"Start",@"Stop",@"Completed",@"Close", nil];
    else if ([[myDatabase.userDictionary valueForKey:@"group_name"] isEqualToString:@"CT_NU"])
        self.status = [NSArray arrayWithObjects:@"Pending",@"Start",@"Stop",@"Completed", nil];
    else
        self.status = [NSArray arrayWithObjects:@"Pending",@"Start",@"Stop",@"Completed",@"Close", nil];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.status.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static  NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if([selectedStatus intValue] == indexPath.row)
    {
        cell.contentView.backgroundColor = [UIColor blueColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
//    Apply Following Action Status Logic.
//    1. Start -> Completed
//    2. Start -> Stop
//    3. Stop - > Reopen
//    4. Reopen -> Completed
//    5. Reopen -> Stop
//    6. Completed -> Reopen
//    7. Completed - > Close
    
    cell.userInteractionEnabled = NO;
    cell.backgroundColor = [UIColor lightGrayColor];
    
    switch ([selectedStatus intValue]) {
        case 1: //start
        {
//            if(indexPath.row == 0) //pending
//            {
//                cell.userInteractionEnabled = YES;
//                cell.backgroundColor = [UIColor whiteColor];
//            }
            
            if(indexPath.row == 2) //stop
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            
            if(indexPath.row == 3)//completed
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            
            break;
        }
        
        case 2: //stop
        {
            if(indexPath.row == 1)//start
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            break;
            
        }
            
        case 3: //completed
        {
            if(indexPath.row == 0)//pending
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            
            if(indexPath.row == 4) //close
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            break;
        }
            
        case 4: //close
        {
//            if(indexPath.row == 0) //pending
//            {
//                cell.userInteractionEnabled = YES;
//                cell.backgroundColor = [UIColor whiteColor];
//            }
            
            break;
        }
            
        default: //pending
            if(indexPath.row == 1) //start
            {
                cell.userInteractionEnabled = YES;
                cell.backgroundColor = [UIColor whiteColor];
            }
            break;
    }
    
    // Configure the cell...
    cell.textLabel.text = [self.status objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *row = [NSNumber numberWithInt:(int)indexPath.row];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectedTableRow" object:nil userInfo:@{@"row":row}];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
