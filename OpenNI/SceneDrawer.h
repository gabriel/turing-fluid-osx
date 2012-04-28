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

#ifndef XNV_POINT_DRAWER_H_
#define XNV_POINT_DRAWER_H_

#include <XnCppWrapper.h>

void DrawDepthMap(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd);
void DrawUserInfo();
void DrawUser(XnUserID user);
void DrawUserStatus(XnUserID user);

typedef enum {
  UserLocationTypeCenter = 0,
  UserLocationTypeRight,
  UserLocationTypeLeft,
  UserLocationTypeTop,
} UserLocationType;

void UserLocations(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd, XnPoint3D *locations, UserLocationType locationType);

BOOL HasUser(XnUserID aUsers[], XnUInt16 nUsers);

BOOL Position3DForJoints(XnUserID player, XnSkeletonJoint eJoint[], XnPoint3D position[], int length);

BOOL Position2DForJoints(XnUserID player, XnSkeletonJoint eJoint[], XnPoint3D position[], int length);

double AngleBetweenXnVector3D(XnVector3D v1, XnVector3D v2);

double XnVector3DMagnitude(XnVector3D vector);

double XnVector3DDotProduct(XnVector3D v1, XnVector3D v2);

XnVector3D XnVector3DDifference(XnVector3D v1, XnVector3D v2);

double AngleAboveHorizon(XnVector3D vector);

#endif