//
//  CocoaOpenNI.mm
//  KinectWings
//
//  Created by John Boiles on 1/13/12.
//  Copyright (c) 2012 John Boiles. All rights reserved.
//

#import "CocoaOpenNI.h"

@interface CocoaOpenNI ()
- (void)userGenerator:(xn::UserGenerator&)userGenerator didGetNewWithUserID:(XnUserID)user cookie:(void *)cookie;
- (void)userGenerator:(xn::UserGenerator&)userGenerator didLoseWithUserID:(XnUserID)user cookie:(void *)cookie;
- (void)poseDetectionCapability:(xn::PoseDetectionCapability&)capability didDetectPose:(const XnChar*)pose userID:(XnUserID)userID cookie:(void *)cookie;
- (void)poseDetectionCapability:(xn::PoseDetectionCapability &)capability inProgressWithPose:(const XnChar *)pose userID:(XnUserID)userID poseStatus:(XnPoseDetectionStatus)poseStatus cookie:(void *)cookie;
- (void)skeletonCapability:(xn::SkeletonCapability&)capability didStartCalibrationForUserID:(XnUserID)userID cookie:(void *)cookie;
- (void)skeletonCapability:(xn::SkeletonCapability &)capability calibrationInProgressForUserID:(XnUserID)userID calibrationStatus:(XnCalibrationStatus)calibrationStatus cookie:(void *)cookie;
- (void)skeletonCapability:(xn::SkeletonCapability&)capability didEndCalibrationForUserID:(XnUserID)userID calibrationStatus:(XnCalibrationStatus)calibrationStatus cookie:(void *)cookie;
- (void)gestureGenerator:(xn::GestureGenerator&)gestureGenerator didRecognizeGestureAtPosition:(const XnPoint3D *)position;
@end

void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator& generator, XnUserID user, void* pCookie);
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator& generator, XnUserID user, void* pCookie);
void XN_CALLBACK_TYPE UserPose_PoseDetected(xn::PoseDetectionCapability& capability, const XnChar* strPose, XnUserID user, void* pCookie);
void XN_CALLBACK_TYPE UserPose_PoseInProgress(xn::PoseDetectionCapability& pose, const XnChar* strPose, XnUserID user, XnPoseDetectionStatus poseStatus, void* pCookie);
void XN_CALLBACK_TYPE UserCalibration_CalibrationStart(xn::SkeletonCapability& capability, XnUserID user, void* pCookie);
void XN_CALLBACK_TYPE UserCalibration_CalibrationInProgress(xn::SkeletonCapability& capability, XnUserID user, XnCalibrationStatus calibrationStatus, void* pCookie);
void XN_CALLBACK_TYPE UserCalibration_CalibrationComplete(xn::SkeletonCapability& capability, XnUserID user, XnCalibrationStatus calibrationStatus, void* pCookie);
void XN_CALLBACK_TYPE HandTracker_Gesture_Recognized(xn::GestureGenerator& generator, const XnChar* strGesture, const XnPoint3D* pIDPosition, const XnPoint3D* pEndPosition, void* pCookie);

// Callback: New user was detected
void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator& generator, XnUserID user, void* pCookie) {
  [[CocoaOpenNI sharedOpenNI] userGenerator:generator didGetNewWithUserID:user cookie:pCookie];
}

// Callback: An existing user was lost
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator& generator, XnUserID user, void* pCookie) {
  [[CocoaOpenNI sharedOpenNI] userGenerator:generator didLoseWithUserID:user cookie:pCookie];
}

// Callback: Detected a pose
void XN_CALLBACK_TYPE UserPose_PoseDetected(xn::PoseDetectionCapability& capability, const XnChar* strPose, XnUserID user, void* pCookie) {
  [[CocoaOpenNI sharedOpenNI] poseDetectionCapability:capability didDetectPose:strPose userID:user cookie:pCookie];
}

// Callback: Pose is in progress
void XN_CALLBACK_TYPE UserPose_PoseInProgress(xn::PoseDetectionCapability& pose, const XnChar* strPose, XnUserID user, XnPoseDetectionStatus poseStatus, void* pCookie) {
  [[CocoaOpenNI sharedOpenNI] poseDetectionCapability:pose inProgressWithPose:strPose userID:user poseStatus:poseStatus cookie:pCookie];
}

// Callback: Started calibration
void XN_CALLBACK_TYPE UserCalibration_CalibrationStart(xn::SkeletonCapability& capability, XnUserID user, void* pCookie)
{
  [[CocoaOpenNI sharedOpenNI] skeletonCapability:capability didStartCalibrationForUserID:user cookie:pCookie];
}

// Callback: Calibration is in progress
void XN_CALLBACK_TYPE UserCalibration_CalibrationInProgress(xn::SkeletonCapability& capability, XnUserID user, XnCalibrationStatus calibrationStatus, void* pCookie) {
  [[CocoaOpenNI sharedOpenNI] skeletonCapability:capability calibrationInProgressForUserID:user calibrationStatus:calibrationStatus cookie:pCookie];
}

// Callback: Finished calibration
void XN_CALLBACK_TYPE UserCalibration_CalibrationComplete(xn::SkeletonCapability& capability, XnUserID user, XnCalibrationStatus calibrationStatus, void* pCookie)
{
  [[CocoaOpenNI sharedOpenNI] skeletonCapability:capability didEndCalibrationForUserID:user calibrationStatus:calibrationStatus cookie:pCookie];
}

void XN_CALLBACK_TYPE HandTracker_Gesture_Recognized(xn::GestureGenerator& generator, const XnChar* strGesture, const XnPoint3D* pIDPosition, const XnPoint3D* pEndPosition, void* pCookie)
{
  [[CocoaOpenNI sharedOpenNI] gestureGenerator:generator didRecognizeGestureAtPosition:pEndPosition];
}


CocoaOpenNI *gSharedOpenNI;

@implementation CocoaOpenNI

@synthesize started=_started;

+ (CocoaOpenNI *)sharedOpenNI {
  if (!gSharedOpenNI) {
    gSharedOpenNI = [[CocoaOpenNI alloc] init];
  }
  return gSharedOpenNI;
}

- (id)init {
  if ((self = [super init])) {
    _bNeedPose = FALSE;
    //_strPose[20] = "";
  }
  return self;
}

- (XnStatus)startWithConfigPath:(NSString *)configPath skeletonProfile:(XnSkeletonProfile)skeletonProfile handsProfile:(BOOL)handsProfile {
  XnStatus nRetVal = XN_STATUS_OK;
  xn::EnumerationErrors errors;

  XnBool fileExists;
  xnOSDoesFileExist([configPath UTF8String], &fileExists);
  if (fileExists) printf("Reading config from: '%s'\n", [configPath UTF8String]);

  nRetVal = _context.InitFromXmlFile([configPath UTF8String], _scriptNode, &errors);
  // If there is no Kinect connected
  if (nRetVal == XN_STATUS_NO_NODE_PRESENT) {
    XnChar strError[1024];
    errors.ToString(strError, 1024);
    printf("%s\n", strError);
    //return (nRetVal);
  } else if (nRetVal != XN_STATUS_OK) {
    printf("Open failed: %s\n", xnGetStatusString(nRetVal));
    return (nRetVal);
  }

  // Create depth generator
  nRetVal = _context.FindExistingNode(XN_NODE_TYPE_DEPTH, _depthGenerator);
  if (nRetVal != XN_STATUS_OK) {
    printf("Find depth generator failed: %s\n", xnGetStatusString(nRetVal));
    return nRetVal;
  }
  
  // Create hand generator
  if (handsProfile) {
    nRetVal = _context.FindExistingNode(XN_NODE_TYPE_GESTURE, _gestureGenerator);
    if (nRetVal != XN_STATUS_OK) {
      nRetVal = _gestureGenerator.Create(_context);
      if (nRetVal != XN_STATUS_OK) {
        printf("Find gesture generator failed: %s\n", xnGetStatusString(nRetVal));
        return nRetVal;
      }
    }
    
    nRetVal = _context.FindExistingNode(XN_NODE_TYPE_HANDS, _handsGenerator);
    if (nRetVal != XN_STATUS_OK) {
      nRetVal = _handsGenerator.Create(_context);
      if (nRetVal != XN_STATUS_OK) {
        printf("Find hands generator failed: %s\n", xnGetStatusString(nRetVal));
        return nRetVal;
      }
    }
    
    XnCallbackHandle hGestureCallbacks;
    _gestureGenerator.RegisterGestureCallbacks(HandTracker_Gesture_Recognized, NULL, NULL, hGestureCallbacks);
  }

  // Create user generator
  nRetVal = _context.FindExistingNode(XN_NODE_TYPE_USER, _userGenerator);
  if (nRetVal != XN_STATUS_OK) {
    nRetVal = _userGenerator.Create(_context);
    if (nRetVal != XN_STATUS_OK) {
      printf("Find user generator failed: %s\n", xnGetStatusString(nRetVal));
      return nRetVal;
    }
  }

  if (skeletonProfile != XN_SKEL_PROFILE_NONE) {
    // Start user tracking
    if (!_userGenerator.IsCapabilitySupported(XN_CAPABILITY_SKELETON)) {
      printf("Supplied user generator doesn't support skeleton\n");
      return 1;
    }
    XnCallbackHandle hUserCallbacks, hCalibrationStart, hCalibrationComplete, hPoseDetected, hCalibrationInProgress, hPoseInProgress;
    _userGenerator.RegisterUserCallbacks(User_NewUser, User_LostUser, NULL, hUserCallbacks);
    _userGenerator.GetSkeletonCap().RegisterToCalibrationStart(UserCalibration_CalibrationStart, NULL, hCalibrationStart);
    _userGenerator.GetSkeletonCap().RegisterToCalibrationComplete(UserCalibration_CalibrationComplete, NULL, hCalibrationComplete);

    // See if we need a pose for calibration
    if (_userGenerator.GetSkeletonCap().NeedPoseForCalibration()) {
      _bNeedPose = TRUE;
      if (!_userGenerator.IsCapabilitySupported(XN_CAPABILITY_POSE_DETECTION)) {
        printf("Pose required, but not supported\n");
        return 1;
      }
      _userGenerator.GetPoseDetectionCap().RegisterToPoseDetected(UserPose_PoseDetected, NULL, hPoseDetected);
      _userGenerator.GetSkeletonCap().GetCalibrationPose(_strPose);
    }

    _userGenerator.GetSkeletonCap().SetSkeletonProfile(skeletonProfile); //XN_SKEL_PROFILE_UPPER); //XN_SKEL_PROFILE_ALL);

    nRetVal = _userGenerator.GetSkeletonCap().RegisterToCalibrationInProgress(UserCalibration_CalibrationInProgress, NULL, hCalibrationInProgress);
    nRetVal = _userGenerator.GetPoseDetectionCap().RegisterToPoseInProgress(UserPose_PoseInProgress, NULL, hPoseInProgress);
  }

  // Maybe this will retain it?
  xnProductionNodeAddRef(_depthGenerator);
  xnProductionNodeAddRef(_userGenerator);
  xnProductionNodeAddRef(_handsGenerator);
  xnProductionNodeAddRef(_gestureGenerator);

  // Start generating some users
  nRetVal = _context.StartGeneratingAll();
  if (nRetVal != XN_STATUS_OK) {
    printf("StartGenerating failed: %s\n", xnGetStatusString(nRetVal));
    return nRetVal;
  }
  
  if (_gestureGenerator) {
    _gestureGenerator.AddGesture("Wave", NULL);
    //_gestureGenerator.AddGesture("Click", NULL);
  }

  _started = YES;
  return 0;
}

- (void)stop {
  _context.Shutdown();
}

- (xn::Context)context {
  return _context;
}

- (xn::DepthGenerator)depthGenerator {
  return _depthGenerator;
}

- (xn::UserGenerator)userGenerator {
  return _userGenerator;
}

- (xn::GestureGenerator)gestureGenerator {
  return _gestureGenerator;
}

- (xn::HandsGenerator)handsGenerator {
  return _handsGenerator;
}

#pragma mark - OpenNI Callbacks

- (void)userGenerator:(xn::UserGenerator&)userGenerator didGetNewWithUserID:(XnUserID)user cookie:(void *)cookie {
  printf("New User %d\n", user);
  // New user found
  if (_bNeedPose) {
    _userGenerator.GetPoseDetectionCap().StartPoseDetection(_strPose, user);
  } else {
    _userGenerator.GetSkeletonCap().RequestCalibration(user, TRUE);
  }
}

- (void)userGenerator:(xn::UserGenerator&)userGenerator didLoseWithUserID:(XnUserID)user cookie:(void *)cookie {
  printf("Lost user %d\n", user);
}

- (void)poseDetectionCapability:(xn::PoseDetectionCapability&)capability didDetectPose:(const XnChar *)pose userID:(XnUserID)userID cookie:(void *)cookie {
  printf("Pose %s detected for user %d\n", pose, userID);
  _userGenerator.GetPoseDetectionCap().StopPoseDetection(userID);
  _userGenerator.GetSkeletonCap().RequestCalibration(userID, TRUE);
}

- (void)poseDetectionCapability:(xn::PoseDetectionCapability &)capability inProgressWithPose:(const XnChar *)pose userID:(XnUserID)userID poseStatus:(XnPoseDetectionStatus)poseStatus cookie:(void *)cookie {
  //printf("Pose in progress\n");
}

- (void)skeletonCapability:(xn::SkeletonCapability&)capability didStartCalibrationForUserID:(XnUserID)userID cookie:(void *)cookie {
  printf("Calibration started for user %d\n", userID);
}

- (void)skeletonCapability:(xn::SkeletonCapability &)capability calibrationInProgressForUserID:(XnUserID)userID calibrationStatus:(XnCalibrationStatus)calibrationStatus cookie:(void *)cookie {
  printf("Calibration in progress for user id %d\n", userID);
}

- (void)skeletonCapability:(xn::SkeletonCapability&)capability didEndCalibrationForUserID:(XnUserID)userID calibrationStatus:(XnCalibrationStatus)calibrationStatus cookie:(void *)cookie {
  if (calibrationStatus == XN_CALIBRATION_STATUS_OK) {
    // Calibration succeeded
    printf("Calibration complete, start tracking user %d\n", userID);
    _userGenerator.GetSkeletonCap().StartTracking(userID);
  } else {
    // Calibration failed
    printf("Calibration failed for user %d\n", userID);
    if (_bNeedPose) {
      _userGenerator.GetPoseDetectionCap().StartPoseDetection(_strPose, userID);
    } else {
      _userGenerator.GetSkeletonCap().RequestCalibration(userID, TRUE);
    }
  }
}

- (void)gestureGenerator:(xn::GestureGenerator&)gestureGenerator didRecognizeGestureAtPosition:(const XnPoint3D *)position {
  _handsGenerator.StartTracking(*position);
}

@end
