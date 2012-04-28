/*****************************************************************************
*                                                                            *
*  OpenNI 1.0 Alpha                                                          *
*  Copyright (C) 2010 PrimeSense Ltd.                                        *
*                                                                            *
*  This file is part of OpenNI.                                              *
*                                                                            *
*  OpenNI is free software: you can redistribute it and/or modify            *
*  it under the terms of the GNU Lesser General Public License as published  *
*  by the Free Software Foundation, either version 3 of the License, or      *
*  (at your option) any later version.                                       *
*                                                                            *
*  OpenNI is distributed in the hope that it will be useful,                 *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of            *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the              *
*  GNU Lesser General Public License for more details.                       *
*                                                                            *
*  You should have received a copy of the GNU Lesser General Public License  *
*  along with OpenNI. If not, see <http://www.gnu.org/licenses/>.            *
*                                                                            *
*****************************************************************************/

//---------------------------------------------------------------------------
// Includes
//---------------------------------------------------------------------------
#include "SceneDrawer.h"
#import "CocoaOpenNI.h"

#if (XN_PLATFORM == XN_PLATFORM_MACOSX)
  #include <GLUT/glut.h>
#else
  #include <GL/glut.h>
#endif

// Settings
XnBool g_bDrawBackground = TRUE;
XnBool g_bDrawPixels = TRUE;
XnBool g_bDrawSkeleton = TRUE;
XnBool g_bPrintID = TRUE;
XnBool g_bPrintState = TRUE;
XnFloat Colors[][3] = {
  {0,1,1},
  {0,0,1},
  {0,1,0},
  {1,1,0},
  {1,0,0},
  {1,.5,0},
  {.5,1,0},
  {0,.5,1},
  {.5,0,1},
  {1,1,.5},
  {1,1,1}
};
XnUInt32 nColors = 10;
#define MAX_DEPTH 10000

// Global state
float g_pDepthHist[MAX_DEPTH];
GLfloat texcoords[8];

unsigned int getClosestPowerOfTwo(unsigned int n);
GLuint initTexture(void** buf, int& width, int& height);
void DrawRectangle(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY);
void DrawTexture(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY);
void glPrintString(void *font, char *str);
void DrawLimb(XnUserID player, XnSkeletonJoint eJoint1, XnSkeletonJoint eJoint2);
void PrintNodeY(XnUserID player, XnSkeletonJoint eJoint1);

unsigned int getClosestPowerOfTwo(unsigned int n) {
  unsigned int m = 2;
  while(m < n) m <<= 1;
  return m;
}

GLuint initTexture(void** buf, int& width, int& height) {
  GLuint texID = 0;
  glGenTextures(1, &texID);

  width = getClosestPowerOfTwo(width);
  height = getClosestPowerOfTwo(height); 
  *buf = new unsigned char[width * height * 4];
  glBindTexture(GL_TEXTURE_2D, texID);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  return texID;
}

void DrawRectangle(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY) {
  GLfloat verts[8] = {
    topLeftX, topLeftY,
    topLeftX, bottomRightY,
    bottomRightX, bottomRightY,
    bottomRightX, topLeftY
  };
  glVertexPointer(2, GL_FLOAT, 0, verts);
  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

void DrawTexture(float topLeftX, float topLeftY, float bottomRightX, float bottomRightY) {
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glTexCoordPointer(2, GL_FLOAT, 0, texcoords);

  DrawRectangle(topLeftX, topLeftY, bottomRightX, bottomRightY);

  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

void glPrintString(void *font, char *str) {
  size_t i, l = strlen(str);
  for(i = 0; i < l; i++) {
    glutBitmapCharacter(font, *str++);
  }
}

BOOL Position3DForJoints(XnUserID player, XnSkeletonJoint eJoint[], XnPoint3D position[], int length) {
  for (int i = 0; i < length; i++) {
    XnSkeletonJointPosition joint;
    [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, eJoint[i], joint);
    if (joint.fConfidence < 0.5) {
      return NO;
    }
    
    position[i] = joint.position;
  }
  return YES;
}

BOOL Position2DForJoints(XnUserID player, XnSkeletonJoint eJoint[], XnPoint3D position[], int length) {
  for (int i = 0; i < length; i++) {
    XnSkeletonJointPosition joint;
    [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, eJoint[i], joint);
    if (joint.fConfidence < 0.5) {
      return NO;
    }

    position[i] = joint.position;
    
    [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, position, position);  
  }
  return YES;
}

void DrawLimb(XnUserID player, XnSkeletonJoint eJoint1, XnSkeletonJoint eJoint2) {
  if (![[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(player)) {
    printf("not tracked!\n");
    return;
  }

  XnSkeletonJointPosition joint1, joint2;
  // Looks like this is how you get the skeleton position for the player
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, eJoint1, joint1);
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, eJoint2, joint2);

  if (joint1.fConfidence < 0.5 || joint2.fConfidence < 0.5) {
    return;
  }

  XnPoint3D pt[2];
  pt[0] = joint1.position;
  pt[1] = joint2.position;

  [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(2, pt, pt);
  glVertex3i(pt[0].X, pt[0].Y, 0);
  glVertex3i(pt[1].X, pt[1].Y, 0);
}

void PrintNodeY(XnUserID player, XnSkeletonJoint eJoint1) {
  if (![[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(player)) {
    printf("not tracked!\n");
    return;
  }

  XnSkeletonJointPosition joint1;
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(player, eJoint1, joint1);

  if (joint1.fConfidence < 0.5) {
      //printf("joint confidence was low (%f)", joint1.fConfidence);
    return;
  }

  printf("Joint position x: %0.1f y: %0.1f z: %0.1f\n", joint1.position.X, joint1.position.Y, joint1.position.Z);
}

BOOL HasUser(XnUserID aUsers[], XnUInt16 nUsers) {
  for (int i = 0; i < nUsers; i++) {
    if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(aUsers[i])) {
      return YES;
    }
  }
  return NO;
}

void UserLocations(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd, XnPoint3D *locations, UserLocationType locationType) {
  
  XnUInt16 g_nXRes = dmd.XRes();
  XnUInt16 g_nYRes = dmd.YRes();
    
  const XnDepthPixel *pDepth = dmd.Data();
  const XnLabel *pLabels = smd.Data();
  
  unsigned int nValue = 0;
  
  XnPoint3D minX[16];
  XnPoint3D minY[16];
  XnPoint3D maxX[16];
  XnPoint3D maxY[16];
  
  for (int i = 0; i < 16; i++) {
    minX[i].X = g_nXRes;
    minX[i].Y = g_nYRes;
    minY[i].X = g_nXRes;
    minY[i].Y = g_nYRes;

    maxX[i].X = 0;
    maxX[i].Y = 0;
    maxY[i].X = 0;
    maxY[i].Y = 0;
  }
  
  XnUserID users[15];
  XnUInt16 nUsers = 15;
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetUsers(users, nUsers);
  BOOL isTracking[15] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

  for (int i = 0; i < nUsers; ++i) {
    XnUserID userId = users[i];
    if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(userId)) {
      
      XnSkeletonJointPosition joint1;
      [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().GetSkeletonJointPosition(userId, XN_SKEL_RIGHT_HAND, joint1);
      
      if (joint1.fConfidence < 0.5) {
        continue;
      }
      
      XnPoint3D pt[2];
      pt[0] = joint1.position;
      [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, pt, pt);
      
      locations[userId].X = pt[0].X;
      locations[userId].Y = pt[0].Y;
      isTracking[userId] = YES;
    }
  }

  for (int nY = 0; nY < g_nYRes; nY++) {
    for (int nX = 0; nX < g_nXRes; nX++) {
      nValue = *pDepth;
      XnLabel label = *pLabels;
      
      if (nValue != 0 && label != 0 && label < 16 && !isTracking[label]) {
        
        if (nX < minX[label].X) {
          minX[label].X = nX;
          minX[label].Y = nY;
        }
        if (nX > maxX[label].X) {
          maxX[label].X = nX;
          maxX[label].Y = nY;
        }
        if (nY < minY[label].Y) {
          minY[label].X = nX;
          minY[label].Y = nY;
        }
        if (nY > maxY[label].Y) {
          maxY[label].X = nX;
          maxY[label].Y = nY;
        }
        
      }
      
      pDepth++;
      pLabels++;
    }
  }

  for (int i = 0; i < 16; i++) {
    locations[i].Z = 0;
    if (maxX[i].X == 0 || maxX[i].Y == 0) {
      locations[i].X = -1;
      locations[i].Y = -1;
    } else {
      switch (locationType) {
        case UserLocationTypeLeft: {
          float centerX = (maxX[i].X + minX[i].X)/2.0f;
          float centerY = (maxY[i].Y + minY[i].Y)/2.0f;
          if ((centerX - minX[i].X) > 115) {
            locations[i].X = minX[i].X;
            locations[i].Y = minX[i].Y;
          } else {
            locations[i].X = minX[i].X;
            locations[i].Y = centerY;
          }
          break;
        }
        case UserLocationTypeTop:
          locations[i].X = (maxX[i].X + minX[i].X)/2.0f;
          locations[i].Y = minY[i].Y;
          break;
        case UserLocationTypeCenter:
          locations[i].X = (maxX[i].X + minX[i].X)/2.0f;
          locations[i].Y = (maxY[i].Y + minY[i].Y)/2.0f;
          break;
        case UserLocationTypeRight: {
          float centerX = (maxX[i].X + minX[i].X)/2.0f;
          float centerY = (maxY[i].Y + minY[i].Y)/2.0f;
          if ((maxX[i].X - centerX) > 115) {
            locations[i].X = maxX[i].X;
            locations[i].Y = maxX[i].Y;
          } else {
            locations[i].X = maxX[i].X;
            locations[i].Y = centerY;
          }
          break;
        }
      }
    }
  }
}

void DrawDepthMap(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd) {
  static bool bInitialized = false;  
  static GLuint depthTexID;
  static unsigned char* pDepthTexBuf;
  static int texWidth, texHeight;

  float topLeftX;
  float topLeftY;
  float bottomRightY;
  float bottomRightX;
  float texXpos;
  float texYpos;

  if(!bInitialized) {
    texWidth =  getClosestPowerOfTwo(dmd.XRes());
    texHeight = getClosestPowerOfTwo(dmd.YRes());

    printf("Initializing depth texture: width = %d, height = %d\n", texWidth, texHeight);
    depthTexID = initTexture((void**)&pDepthTexBuf,texWidth, texHeight) ;
    printf("Initialized depth texture: width = %d, height = %d\n", texWidth, texHeight);

    bInitialized = true;

    topLeftX = dmd.XRes();
    topLeftY = 0;
    bottomRightY = dmd.YRes();
    bottomRightX = 0;
    texXpos =(float)dmd.XRes()/texWidth;
    texYpos  =(float)dmd.YRes()/texHeight;

    memset(texcoords, 0, 8*sizeof(float));
    texcoords[0] = texXpos, texcoords[1] = texYpos, texcoords[2] = texXpos, texcoords[7] = texYpos;
  }

  unsigned int nValue = 0;
  unsigned int nHistValue = 0;
  unsigned int nIndex = 0;
  unsigned int nX = 0;
  unsigned int nY = 0;
  unsigned int nNumberOfPoints = 0;
  XnUInt16 g_nXRes = dmd.XRes();
  XnUInt16 g_nYRes = dmd.YRes();

  unsigned char* pDestImage = pDepthTexBuf;

  const XnDepthPixel* pDepth = dmd.Data();
  const XnLabel* pLabels = smd.Data();

  // Calculate the accumulative histogram
  memset(g_pDepthHist, 0, MAX_DEPTH*sizeof(float));
  for (nY=0; nY<g_nYRes; nY++)
  {
    for (nX=0; nX<g_nXRes; nX++)
    {
      nValue = *pDepth;

      if (nValue != 0)
      {
        g_pDepthHist[nValue]++;
        nNumberOfPoints++;
      }

      pDepth++;
    }
  }

  for (nIndex=1; nIndex<MAX_DEPTH; nIndex++) {
    g_pDepthHist[nIndex] += g_pDepthHist[nIndex-1];
  }
  if (nNumberOfPoints) {
    for (nIndex=1; nIndex<MAX_DEPTH; nIndex++) {
      g_pDepthHist[nIndex] = (unsigned int)(256 * (1.0f - (g_pDepthHist[nIndex] / nNumberOfPoints)));
    }
  }

  pDepth = dmd.Data();
  if (g_bDrawPixels) {
    XnUInt32 nIndex = 0;
    // Prepare the texture map
    for (nY=0; nY<g_nYRes; nY++)
    {
      for (nX=0; nX < g_nXRes; nX++, nIndex++)
      {

        pDestImage[0] = 0;
        pDestImage[1] = 0;
        pDestImage[2] = 0;
  
        // Draw the depth
        if (g_bDrawBackground || *pLabels != 0) {
          nValue = *pDepth;
          XnLabel label = *pLabels;
          XnUInt32 nColorID = label % nColors;
          if (label == 0)
          {
            nColorID = nColors;
          }

          if (nValue != 0)
          {
            nHistValue = g_pDepthHist[nValue];

            pDestImage[0] = nHistValue * Colors[nColorID][0]; 
            pDestImage[1] = nHistValue * Colors[nColorID][1];
            pDestImage[2] = nHistValue * Colors[nColorID][2];
          }
        }

        pDepth++;
        pLabels++;
        pDestImage+=3;
      }

      pDestImage += (texWidth - g_nXRes) *3;
    }
  } else {
    xnOSMemSet(pDepthTexBuf, 0, 3*2*g_nXRes*g_nYRes);
  }

  glBindTexture(GL_TEXTURE_2D, depthTexID);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, texWidth, texHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, pDepthTexBuf);

  // Display the OpenGL texture map
  glColor4f(0.75, 0.75, 0.75, 1);

  glEnable(GL_TEXTURE_2D);
  DrawTexture(dmd.XRes(), dmd.YRes(), 0, 0);
  glDisable(GL_TEXTURE_2D);
}

void DrawUser(XnUserID user) {
  glColor4f(1 - Colors[user%nColors][0], 1 - Colors[user%nColors][1], 1 - Colors[user%nColors][2], 1);
  
  glBegin(GL_LINES);
  DrawLimb(user, XN_SKEL_HEAD, XN_SKEL_NECK);
  
  DrawLimb(user, XN_SKEL_NECK, XN_SKEL_LEFT_SHOULDER);
  DrawLimb(user, XN_SKEL_LEFT_SHOULDER, XN_SKEL_LEFT_ELBOW);
  DrawLimb(user, XN_SKEL_LEFT_ELBOW, XN_SKEL_LEFT_HAND);
  
  DrawLimb(user, XN_SKEL_NECK, XN_SKEL_RIGHT_SHOULDER);
  DrawLimb(user, XN_SKEL_RIGHT_SHOULDER, XN_SKEL_RIGHT_ELBOW);
  DrawLimb(user, XN_SKEL_RIGHT_ELBOW, XN_SKEL_RIGHT_HAND);
  
  DrawLimb(user, XN_SKEL_LEFT_SHOULDER, XN_SKEL_TORSO);
  DrawLimb(user, XN_SKEL_RIGHT_SHOULDER, XN_SKEL_TORSO);
  
  DrawLimb(user, XN_SKEL_TORSO, XN_SKEL_LEFT_HIP);
  DrawLimb(user, XN_SKEL_LEFT_HIP, XN_SKEL_LEFT_KNEE);
  DrawLimb(user, XN_SKEL_LEFT_KNEE, XN_SKEL_LEFT_FOOT);
  
  DrawLimb(user, XN_SKEL_TORSO, XN_SKEL_RIGHT_HIP);
  DrawLimb(user, XN_SKEL_RIGHT_HIP, XN_SKEL_RIGHT_KNEE);
  DrawLimb(user, XN_SKEL_RIGHT_KNEE, XN_SKEL_RIGHT_FOOT);
  
  DrawLimb(user, XN_SKEL_LEFT_HIP, XN_SKEL_RIGHT_HIP);
  
  glEnd();
}

void DrawUserStatus(XnUserID user) {
  XnPoint3D com;
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetCoM(user, com);
  [[CocoaOpenNI sharedOpenNI] depthGenerator].ConvertRealWorldToProjective(1, &com, &com);
  
  char strLabel[50] = "";
  xnOSMemSet(strLabel, 0, sizeof(strLabel));
  if (!g_bPrintState) {
    // Tracking
    sprintf(strLabel, "%d", user);
  } else if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(user)) {
    // Tracking
    sprintf(strLabel, "%d - Tracking", user);
  } else if ([[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsCalibrating(user)) {
    // Calibrating
    sprintf(strLabel, "%d - Calibrating...", user);
  } else {
    // Nothing
    sprintf(strLabel, "%d - Looking for pose", user);
  }
  
  glColor4f(1 - Colors[user%nColors][0], 1 - Colors[user%nColors][1], 1 - Colors[user%nColors][2], 1);
  glRasterPos2i(com.X, com.Y);
  glPrintString(GLUT_BITMAP_HELVETICA_18, strLabel);
}

void DrawUserInfo() {
  XnUserID aUsers[15];
  XnUInt16 nUsers = 15;
  [[CocoaOpenNI sharedOpenNI] userGenerator].GetUsers(aUsers, nUsers);
  for (int i = 0; i < nUsers; ++i)
  {
    // Mark users with status
    if (g_bPrintID) {
      DrawUserStatus(aUsers[i]);
    }

    if (g_bDrawSkeleton && [[CocoaOpenNI sharedOpenNI] userGenerator].GetSkeletonCap().IsTracking(aUsers[i])) {
      DrawUser(aUsers[i]);
    }
  }
}

double AngleAboveHorizon(XnVector3D vector) {
  // Just pythagorean theorum and trig
  return atan(vector.Y / sqrt(pow(vector.X, 2) + pow(vector.Z, 2))) * 180 / M_PI;
}

double AngleBetweenXnVector3D(XnVector3D v1, XnVector3D v2) {
  // cos^-1(a.b/|a||b|)*(180/pi) gives the angle in degrees.
  // See http://www.wikihow.com/Find-the-Angle-Between-Two-Vectors
  return acos(XnVector3DDotProduct(v1, v2) / (XnVector3DMagnitude(v1) * XnVector3DMagnitude(v2))) * (180 / M_PI);
}

XnVector3D XnVector3DDifference(XnVector3D v1, XnVector3D v2) {
  XnVector3D difference;
  difference.X = v1.X - v2.X;
  difference.Y = v1.Y - v2.Y;
  difference.Z = v1.Z - v2.Z;
  return difference;
}

double XnVector3DMagnitude(XnVector3D vector) {
  return sqrt(pow(vector.X, 2) + pow(vector.Y, 2) + pow(vector.Z, 2));
}

double XnVector3DDotProduct(XnVector3D v1, XnVector3D v2) {
  return v1.X * v2.X + v1.Y * v2.Y + v1.Z * v2.Z;
}