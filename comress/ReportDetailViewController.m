//
//  ReportDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 13/5/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ReportDetailViewController.h"
#import "ReportFiltersViewController.h"

@interface ReportDetailViewController ()

@end

@implementation ReportDetailViewController

@synthesize reportType,POisLoggedIn,PMisLoggedIn;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    self.selectedDivisionId = [NSNumber numberWithInt:0];
    self.selectedZoneId = [NSNumber numberWithInt:0];
    
    if(POisLoggedIn)
        self.filterLabel.hidden = YES;
    else if (PMisLoggedIn)
        self.filterLabel.hidden = NO;
    
    //add tap gesture to filter to toggle filter view
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFilter)];
    tap.numberOfTapsRequired = 1;
    self.filterLabel.userInteractionEnabled = YES;
    [self.filterLabel addGestureRecognizer:tap];
    
    
    [self setDefaultDateRange];
    
    self.title = reportType;
    
    //filter listeners

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterReports:) name:@"filterReports" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeReportsFilter) name:@"closeReportsFilter" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self loadWebView];
}

- (void)filterReports:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    NSString *filter = @"Filters: None";
    
    if ([[dict objectForKey:@"division"] valueForKey:@"DivName"] != nil) {
        NSString *zoneStr;
        
        if([[dict objectForKey:@"zone"] valueForKey:@"ZoneName"] != [NSNull null])
            zoneStr = [[dict objectForKey:@"zone"] valueForKey:@"ZoneName"];
        
        if(zoneStr.length == 0)
            zoneStr = @"All";
        
        filter = [NSString stringWithFormat:@"Filters: %@, %@",[[dict objectForKey:@"division"] valueForKey:@"DivName"],zoneStr];
        
        self.selectedDivisionId = [NSNumber numberWithInt:[[[dict objectForKey:@"division"] valueForKey:@"DivId"] intValue]];
        self.selectedZoneId = [NSNumber numberWithInt:[[[dict objectForKey:@"zone"] valueForKey:@"ZoneId"] intValue]];
    }
    
    self.filterLabel.text = filter;
    
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        [self requestReportData];
    }];
}

- (void)closeReportsFilter
{
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:nil];
}

- (void)toggleFilter
{
    ReportFiltersViewController *reportsFilterVc = [self.storyboard instantiateViewControllerWithIdentifier:@"ReportFiltersViewController"];

    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:reportsFilterVc];
    
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

- (void)loadWebView
{
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlFile = nil;
    
    if(POisLoggedIn)
    {
        htmlFile = [[NSBundle mainBundle] pathForResource:@"TSAFBPO" ofType:@"html"];
        
        if([reportType isEqualToString:@"Feedback Issues"])
        {
//            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            htmlFile = [[NSBundle mainBundle] pathForResource:@"TIWSBPO" ofType:@"html"];
        }
        
    }
    else if (PMisLoggedIn)
    {
        htmlFile = [[NSBundle mainBundle] pathForResource:@"TSAFBPM" ofType:@"html"];
        
        if([reportType isEqualToString:@"Feedback Issues"])
            htmlFile = [[NSBundle mainBundle] pathForResource:@"TIWSBPM" ofType:@"html"];
        else if([reportType isEqualToString:@"Average Sentiment"])
            htmlFile = [[NSBundle mainBundle] pathForResource:@"ASBPM" ofType:@"html"];
    }
    
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
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
#pragma - mark date selection delegate
- (void)setDefaultDateRange
{
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:[NSDate date]];
    NSDate *startDate = [[NSCalendar currentCalendar]
                         dateFromComponents:components];
    
    self.selectedFromDate = [startDate dateByAddingTimeInterval:-2592000]; //last month
    self.selectedToDate = startDate;
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MMM-YYYY"];
    
    NSString *datestringToday = [format stringFromDate:self.selectedToDate];
    self.toDateTextField.text = datestringToday;
    
    NSString *lastMonthString = [format stringFromDate:self.selectedFromDate];
    self.fromDateTextFied.text = lastMonthString;
}

- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element {

    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:selectedDate];
    NSDate *cleanDateWithoutTime = [[NSCalendar currentCalendar]
                         dateFromComponents:components];
    
    selectedDate = cleanDateWithoutTime;
    
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
    
    [self requestReportData];
}

#pragma - mark division and zone filter
- (IBAction)filterDivision:(id)sender
{

}

- (IBAction)filterZone:(id)sender
{
    
}

#pragma - mark uiwebview delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self requestReportData];
    
    CGRect newBounds = webView.bounds;
    newBounds.size.height = webView.scrollView.contentSize.height;
    webView.bounds = newBounds;
}

#pragma  - mark data request
- (void)requestReportData
{
    NSString *wcfDateFrom = [self serializedStringDateJson:self.selectedFromDate];
    NSString *wcfDateTo   = [self serializedStringDateJson:self.selectedToDate];
    
    
    NSString *urlString = nil;
    NSString *params = nil;
    
    if(POisLoggedIn)
    {
        urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_po];
        
        if([reportType isEqualToString:@"Survey"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_survey_po];
        
        params = [myDatabase toJsonString:@{@"startDate":wcfDateFrom,@"endDate":wcfDateTo,@"url":urlString,@"session":[myDatabase.userDictionary valueForKey:@"guid"]}];
    }
    else if (PMisLoggedIn)
    {
        urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_po];
        
        if([reportType isEqualToString:@"Survey"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_survey_pm];
        else if ([reportType isEqualToString:@"Feedback Issues"])
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_total_issue_pm];
        else
            urlString = [NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_survey_report_average_sentiment_pm];
        
        params = [myDatabase toJsonString:@{@"startDate":wcfDateFrom,@"endDate":wcfDateTo,@"url":urlString,@"session":[myDatabase.userDictionary valueForKey:@"guid"],@"divId":self.selectedDivisionId,@"zoneId":self.selectedZoneId}];
    }

    
    [self executeJavascript:@"requestData" withJsonObject:params];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

-(void)executeJavascript:(NSString *)methodName withJsonObject:(NSString *)object
{
    NSData *jsonData = [object dataUsingEncoding:NSUTF8StringEncoding];
    
    // Base64 encode the string to avoid problems
    NSString *encodedString = [jsonData base64EncodedStringWithOptions:0];
    
    // Evaluate your JavaScript function with the encoded string as input
    NSString *jsCall = [NSString stringWithFormat:@"%@(\"%@\")",methodName, encodedString];
    [self.webView stringByEvaluatingJavaScriptFromString:jsCall];
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
