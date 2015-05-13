//
//  ApiCallUrl.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#ifndef comress_ApiCallUrl_h
#define comress_ApiCallUrl_h

static NSString * AFkey_allowInvalidCertificates = @"allowInvalidCertificates";

static NSString *google_api_key = @"AIzaSyDAD3ZNjQ4n3AfqV-IIOklSiLbmyfX7IWo";

static NSString *google_ios_api_key = @"AIzaSyBp8nNVujNkbk13h2W05vJDZYOPvlhdiLE"; //we use this for google places api


static NSString *api_activationUrl = @"http://fmit.com.sg/comressmainservice/AddressManager.svc/json/GetUrlAddress/?group=";

static NSString *app_path = @"ComressMWCF/v1.02/";

static NSString *api_login = @"User.svc/ComressLogin";

static NSString *api_logout = @"User.svc/Logout?sessionId=";

static NSString *api_post_send = @"Messaging/Post.svc/UploadPost";

static NSString *api_comment_send = @"Messaging/Comment.svc/UploadComment";

static NSString *api_send_images = @"Messaging/PostImage.svc/UploadImageWithBase64";

static NSString *api_download_blocks = @"PublicSetup.svc/GetBlocks";

static NSString *api_download_user_blocks = @"Job/Block.svc/GetBlocksByUser";

static NSString *api_update_device_token = @"User.svc/UpdateDeviceToken?";

static NSString *api_download_posts = @"Messaging/Post.svc/GetPosts";

static NSString *api_download_comments = @"Messaging/Comment.svc/GetComments";

static NSString *api_download_images = @"Messaging/PostImage.svc/GetImages";

static NSString *api_download_comment_noti = @"Messaging/CommentNoti.svc/GetCommentNotis";

static NSString *api_upload_comment_noti = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_status_after_read = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_post_status = @"Messaging/Post.svc/UpdatePostActionStatus";




//routine

static NSString *api_download_checklist = @"Job/Setup.svc/GetCheckLists";

static NSString *api_download_checkarea = @"Job/Setup.svc/GetCheckAreas";

static NSString *api_download_scan_checklist_blk =  @"Job/Setup.svc/GetScanCheckListBlks";

static NSString *api_download_scan_checklist = @"PublicSetup.svc/GetScanCheckLists";

static NSString *api_download_jobs = @"Job/Setup.svc/GetJobs";

static NSString *api_download_sup_sked = @"Job/Schedule.svc/GetSUPSchedules";

static NSString *api_download_spo_sked = @"Job/Schedule.svc/GetSPOSchedules";

static NSString *api_updated_sup_sked = @"Job/Schedule.svc/UpdateSchedulesBySUP";

static NSString *api_update_spo_sked = @"Job/Schedule.svc/UpdateSchedulesBySPO";

static NSString *api_upload_scan_blk = @"Job/ScanBlock.svc/UploadScanBlock";

static NSString *api_upload_scan_inspection = @"Job/ScanInspection.svc/UploadScanInspection";

static NSString *api_upload_inspection_res = @"Job/InspectionResult.svc/UploadInspectionResult";

static NSString *api_download_sup_active_blocks = @"Job/Block.svc/GetActiveSUPBlocks";



//feedback

static NSString *api_download_fed_questions = @"Survey/Question.svc/GetQuestions";

static NSString *api_upload_survey =  @"Survey/Survey.svc/UploadSurvey";

static NSString *api_download_survey = @"Survey/Survey.svc/GetSurveys";

static NSString *api_upload_crm = @"Survey/Survey.svc/UploadCRMIssue";

static NSString *api_download_feedback_issues = @"Survey/Survey.svc/GetFeedbackIssues";

static NSString *api_upload_resident_info_edit = @"Survey/Survey.svc/UpdateResidentInfo";

static NSString *api_upload_crm_image = @"Survey/Survey.svc/UploadCRMImageWithBase64";


#endif



