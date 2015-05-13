//
//  ReportDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportDetailViewController.h"

@interface ReportDetailViewController ()

@end

@implementation ReportDetailViewController

@synthesize reportType;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    [self setDefaultDateRange];
    
    self.title = reportType;
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    if(textField == self.fromDateTextFied)
    {
        self.actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeDate selectedDate:self.selectedFromDate target:self action:@selector(dateWasSelected:element:) origin:textField];
    }
    else
    {
        self.actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeDate selectedDate:self.selectedToDate target:self action:@selector(dateWasSelected:element:) origin:textField];
    }
    
    [self.actionSheetPicker addCustomButtonWithTitle:@"Today" value:[NSDate date]];
    [self.actionSheetPicker addCustomButtonWithTitle:@"Last Month" value:[[NSDate date] TC_dateByAddingCalendarUnits:NSCalendarUnitMonth amount:-1]];
    self.actionSheetPicker.hideCancel = YES;
    [self.actionSheetPicker showActionSheetPicker];
        
}

- (void)setDefaultDateRange
{
    self.selectedFromDate = [[NSDate date] dateByAddingTimeInterval:-2629743.83]; //last month
    self.selectedToDate = [NSDate date];
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    NSString *datestringToday = [format stringFromDate:self.selectedToDate];
    self.toDateTextField.text = datestringToday;
    
    NSString *lastMonthString = [format stringFromDate:self.selectedFromDate];
    self.fromDateTextFied.text = lastMonthString;
    
    [self requestReportData];
}

- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element {

    UITextField *textField = (UITextField *)element;
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    if(textField == self.fromDateTextFied)
    {
        self.selectedFromDate = selectedDate;
        
        NSString *datestring = [format stringFromDate:self.selectedFromDate];
        textField.text = datestring;
    }
    else
    {
        self.selectedToDate = selectedDate;
        
        NSString *datestring = [format stringFromDate:self.selectedToDate];
        textField.text = datestring;
    }
    
    //validate date
    if([self.selectedFromDate compare:self.selectedToDate] == NSOrderedDescending)
    {
        [self setDefaultDateRange];
    }
    else
        [self requestReportData];
}

- (void)requestReportData
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM-DD-YYYY"];
    
    NSString *wcfDateFrom = [self serializedStringDateJson:self.selectedFromDate];
    NSString *wcfDateTo   = [self serializedStringDateJson:self.selectedToDate];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_po];
    NSDictionary *params = @{@"startDate":wcfDateFrom,@"endDate":wcfDateTo};
    
    if([reportType isEqualToString:@"Survey"])
        urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_survey_po];
    
    
    [myDatabase.AfManager POST:urlString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSDictionary *responseDict = (NSDictionary *)responseObject;
        
        [self drawChartToWebViewWithDict:responseDict];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@",error);
    }];
}

- (void)drawChartToWebViewWithDict:(NSDictionary *)dict
{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"TSAFBP" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}


#pragma - mark helper
- (NSString *)serializedStringDateJson: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}

@end
