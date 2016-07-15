//
//  Orientation.swift
//  SBFrames
//
//  Created by Ed Gamble on 10/22/15.
//  Copyright © 2015 Opus Logica Inc. All rights reserved.
//
import SBUnits

public struct Orientation : Framed {

  public enum RotationConvention {
    case fixedXYZ
    case eulerZYX
  }
  
  public let frame : Frame
  
  let quat : Quaternion
  
  
  // MARK: Initialize

  //
  //
  //
  internal init (frame: Frame, quat: Quaternion) {
    self.quat = quat
    self.frame = frame
  }
  
  public init (frame: Frame, angle: Quantity<Angle>, direction: Direction) {
    let angle = angle.convert(radian).value
    
    let sin_angle_over_2 = sin (angle / 2.0)
    let cos_angle_over_2 = cos (angle / 2.0)
    
    self.init (frame: frame,
               quat: Quaternion (q0: cos_angle_over_2,
                                 q1: sin_angle_over_2 * direction.x,
                                 q2: sin_angle_over_2 * direction.y,
                                 q3: sin_angle_over_2 * direction.z));
  }
 
  public init (frame: Frame, angle: Quantity<Angle>, axis: Frame.Axis) {
    self.init (frame: frame, angle: angle, direction: Direction(frame: frame, axis: axis))
  }
  
  public init (frame: Frame, unit: UnitX<Angle>, convention: RotationConvention, x: Double, y: Double, z: Double) {

    let x = radian.convert (x, unit: unit)
    let y = radian.convert (y, unit: unit)
    let z = radian.convert (z, unit: unit)
    
    switch convention {
    case .fixedXYZ:
      self.init (frame: frame)

    case .eulerZYX:
    let c1 = cos (x / 2)
    let c2 = cos (y / 2)
    let c3 = cos (z / 2)
    let s1 = sin (x / 2)
    let s2 = sin (y / 2)
    let s3 = sin (z / 2)
    
    self.init (frame: frame,
               quat: Quaternion (q0: s1 * c2 * c3 + c1 * s2 * s3,
                                 q1: c1 * s2 * c3 - s1 * c2 * s3,
                                 q2: c1 * c2 * s3 + s1 * s2 * c3,
                                 q3: c1 * c2 * c3 - s1 * s2 * s3))

    }
  }
  
  public init? (frame: Frame, unitX: Direction, unitY: Direction, unitZ: Direction) {
    return nil
  }
  
  public init? (frame: Frame, dir1: Direction, dir2: Direction) {
    return nil
  }

 init (frame: Frame) {
    self.init (frame: frame, angle: Quantity<Angle>(value: 0.0, unit: radian), axis: Frame.Axis.z)
  }
}

// MARK: Equatable

extension Orientation : Equatable {}
public func == (lhs: Orientation, rhs: Orientation) -> Bool {
  return lhs.frame == rhs.frame &&
    lhs.quat == rhs.quat
}


// MARK: Invertable

extension Orientation : Invertable {
  //
  
  public var inverse : Orientation {
    return Orientation (frame: frame, quat: quat.conjugate)
  }
  
}

// MARK: Rotatable

extension Orientation : Rotatable {
  ///
  ///
  ///
  public func rotate (_ offset: Orientation) -> Orientation {
    let offset = offset.transform (to: frame)
    
    return Orientation (frame: frame,
                        quat: quat.rotate (by: offset.quat))
  }
}

// MARK: Transformable

extension Orientation : Transformable {
  ///
  ///
  ///
  public func transform (to frame: Frame) -> Orientation {
    guard self.frame !== frame else { return self }
    
    // Apply the transformation - inefficiently
    return Frame (orientation: self).transform (to: frame).orientation
  }
  
  ///
  /// Transform `self` by frame to produce a new `framed` that will have a *different* physical
  /// position and orientation.
  ///
  public func transform (by frame: Frame) -> Orientation {
    
    // Put `frame` into our frame
    let that = frame.transform (to: self.frame)
    
    // Apply the transformation - inefficiently
    return Frame (orientation: self).transform (by: that).orientation
  }
  
  
}

// MARK: Composable

extension Orientation : Composable {
  public func compose  (_ offset: Orientation) -> Orientation {
    let offset = offset.transform (to: frame)
    
    return Orientation (frame: frame,
                        quat: offset.quat * self.quat)
  }
}

/*
#if false
extern void frame_orientation_by_fixed_xyz (FrameOrientation o,
                                            SBReal alpha_z,
                                            SBReal beta_y,
                                            SBReal gamma_x)
{
  FrameOrientation x, y, z, yx;
  
  frame_orientation_by_axis_angle (x, SBAxis_X, gamma_x);
  frame_orientation_by_axis_angle (y, SBAxis_Y, beta_y);
  frame_orientation_by_axis_angle (z, SBAxis_Z, alpha_z);
  
  frame_orientation_rotate(yx, y,  x);
  frame_orientation_rotate( o, z, yx);
}

extern void frame_orientation_by_euler_zyx (FrameOrientation o,
                                            SBReal gamma_x,
                                            SBReal beta_y,
                                            SBReal alpha_z)
{ frame_orientation_by_fixed_xyz(o, alpha_z, beta_y, gamma_x); }

//
//
//
extern void frame_orientation_rotate (FrameOrientation tgt,
                                      const FrameOrientation rot,
                                      const FrameOrientation src)
{ matrix_mul ((SBReal *) tgt,
              (SBReal const *) rot,
              (SBReal const *) src,
              3, 3, 3); }

//
//
//
static SBReal mag (SBReal x, SBReal y, SBReal z)
{ return real_sqrt (x*x + y*y + z*z); }

extern void frame_orientation_extract_fixed_xyz_angles (FrameOrientation o,
                                                        SBReal *alpha_z,
                                                        SBReal *beta_y,
                                                        SBReal *gamma_x)
{
  SBReal beta     = real_atan2 ((- o[2][0]), mag (o[0][0], o[1][0], 0));
  SBReal cos_beta = real_cos   (beta);
  
  if (real_pi_2 == beta)
  {
    if (alpha_z) *alpha_z = 0;
    if (beta_y)  *beta_y  = beta;
    if (gamma_x) *gamma_x = real_atan2 (o[0][1], o[1][1]);
  }
  else
  {
    if (alpha_z) *alpha_z = real_atan2 ((o[1][0] / cos_beta), (o[0][0] / cos_beta));
    if (beta_y)  *beta_y  = beta;
    if (gamma_x) *gamma_x = real_atan2 ((o[2][1] / cos_beta), (o[2][2] / cos_beta));
  }
}

extern void frame_orientation_extract_euler_zyx_angles (FrameOrientation o,
                                                        SBReal *gamma_x,
                                                        SBReal *beta_y,
                                                        SBReal *alpha_z)
{ frame_orientation_extract_fixed_xyz_angles(o, alpha_z, beta_y, gamma_x); }

extern void frame_orientation_extract_spherical_angles (FrameOrientation o,
                                                        SBAxis  axis,
                                                        SBReal *phi,
                                                        SBReal *theta)
{ if (phi)   *phi   = real_acos  (o[SBAxis_Z][axis]);
  if (theta) *theta = real_atan2 (o[SBAxis_Y][axis], o[SBAxis_X][axis]); }
 
 
 extern void frame_direction_extract_spherical_angles (const FrameDirection src,
 SBReal *phi,
 SBReal *theta)
 { if (phi)   *phi   = real_acos  (src[SBAxis_Z]);
 if (theta) *theta = real_atan2 (src[SBAxis_Y], src[SBAxis_X]); }

#endif
*/

