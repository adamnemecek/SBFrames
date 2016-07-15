//
//  Frame.swift
//  SBFrames
//
//  Created by Ed Gamble on 10/22/15.
//  Copyright © 2015 Opus Logica Inc. All rights reserved.
//
import SBUnits

// https://en.wikipedia.org/wiki/Coordinate_system
// https://en.wikipedia.org/wiki/Celestial_coordinate_system
// https://en.wikipedia.org/wiki/List_of_common_coordinate_transformations

public enum AxisX : Int, CustomStringConvertible {
  case x = 0
  case y = 1
  case z = 2
  
  static var names = ["X", "Y", "Z"]
  
  var name : String { return AxisX.names[self.rawValue] }
  
  public var description : String { return name }
}

let NUMBER_OF_AXES = 1 + AxisX.z.rawValue

// NOTE: The position and orientation of a FRAME needs to be writeable.  For
// example, a Spacecraft has a frame which defines the coordinate system for
// all spacecraft devices.  Each device will define their own coordinate system
// with a parent given by the spacecraft's frame.  When the spacecraft moves,
// the physical coordinate system of the spacecraft changes.  If an SBFrame
// is immutable then the spacecraft's frame could be changed but then all the
// attached devices would a) still reference the old frame or b) all need to be
// updated to the changed frame - that at least if one needed to transform from
// the device to coordiates 'above' the spacecraft (like planets, stars, etc).
// As it stands a frame does not maintain an association with its children and
// thus option 'b' - updating all referencing frames with the next frame - is
// practically impossible.  The other option is to make SBFrame properties for
// POSITION and ORIENTATION writeable.
//
// If a FRAME's POSITION and ORIENTATION are writeable then changes would need
// to be monitorable.  Thus, for example, a star tracker could compute the ever
// changing direction of the sun so as to avoid staring into the light.  And, of
// course, on change, any cached FrameTransform data would need to be flushed.
//

// Does a frame have UNIT?  It doesn't make sense to inherit the unit from the
// frame's position because that position is in the frame's parent frame.
//
// Should a frame be a factory for SBPosition, SBDirection and SBOrientation.
// Yea, kind of - since each of those needs a SBFrame (as each is a
// SBFramedObject).

// Dimensionality: 1D, 2D, 3D, ...
// Type: Rectangular, Spherical, Cylindrical, etc.
//   => Created POSITION, ORIENTATION off of FRAME must be of the correct type.


// MORE DISCUSSION

// Every frame has a position and an orientation - for the 'base frame' they are 'zero'
//   No, the position itself has a 'frame' even if zero.  If user accesses that frame, then the 
//   user now has a frame w/o a position.
//
// Base frame has no parent, no position, no orientation.  THERE IS NO OTHER POSSIBILITY
//   (at least if position, orientation will have a frame)
//
// What is the coordindate system for a base frame: rectangular, spherical, cylindrical?


// ============================================================================================== //
//
// Imagine:
//   a well-defined base frame
//   a sun expressed in the base-frame
//   a moving spacecraft in the base-frame
//   a camera on the spacecraft with a frame relative to the spacecraft's and a view direction
//     (assume the camera and/or the camera's frame listens to spacecraft motion and will close
//      a shutter if the camera's view 'hits' the sun)
//
// The spacecraft moves:
//   The sun itself didn't move, but the postion/orientation relative to the spacecraft did.
//   The camera moved - it is attached to the spacecraft
//     The angle between the camera's direction and the sun changed.
//
// Key Question // Design Issue
//
//  Q-1-A: Is the frame of the spacecraft modified (spacecraft reference to the frame is unchanged
//    but the frame's position and orientation changed)
//
//  Q-1-B: Is the spacecraft's frame changed (perhaps a frame is immutable (value semantics); the
//    spacecraft has a newly allocated frame)
//  Analysis: the camera registered with the spacecraft; the camera knows it is mounted on the
//    spacecraft with a fixed (parameterized) position/orientation offet.  The camera, like the
//    spacecraft has it's own frame.  On callback, the camera frame is changed as:
//      cFrame2 = Frame(scFrame2, Postion(scFrame2, fixedOffset), Orientation(scFrame2, fixedOffset)
//        where fixedOffset are the 'hard numbers' relative to the original scFrame1
//    On callback, the view direcion is updated
//    With new direction, the angle between view and sun is measured; shutter is closed if needed.
//
//  Q-2: The spacecraft has a 'reference frame' with reference semantics; a 'coordinate system'
//     has value semantics?

//  Q-3: A Position is 'Framed'; a Spacecraft is 'Framed' - that does not seem correct as they are
//    vastly different conceptually.  Position vs Point?  Point expressed with different positions
//    depending on coordinate system.  Point moves -> all positions changed.
//      Point -> Position
//      Line -> Direction
//      Body -> Frame (position + orientation)
//
//  Q-4: Race Condition: Two objects a camera and a thruster on the spacecraft; camera is 
//    interested in thruster plume.  Spacecraft moves (position+orientation); camera and thruster
//    are updated (somehow, see Q-1), camera computes plume impact.
//  Answer-ish: If reference semantics, when spacecraft moves, both camera and thruster 
//    'instantaneously' have different positions/orientations (relative to some third frame). If
//    value semantics, camera and thruster frames need to be updated and only then computed.
//
//  Q-5: Sun moves.  Spacecraft registered as 'interested'; updates computed properties.  Does the
//    Sun notify (should be) or does the Sun's frame notify the S/C frame (can't be)?
//
//  Q-6: Updating Race Condition - A Frame is having it's Postion + Orientation updated, any
//    subframe may perform a computation using its 'half updated' parent...  Unless updates are
//    atomic.
//
//    Frame notifies listeners of its replacement?  Listeners assign the replacement as the new
//    parent?  [Listeners need to be sure they are not between computations using the parent -
//    which gets changed during the computations.]
//
//    New frame allocated as (parent: new, position: old, orientation: old) - no, old position and
//    orientation will point to old frame.
//
//

// MARK: Framed Protcol

///
/// The `Framed` protocol represents objects that have a Frame
///
public protocol Framed {
  
  /// The frame
  var frame : Frame { get }
  
  /// The base frame of frame
  var base : Frame { get }
  
  /// The frame that is common to `self` and `that`
  func common (_ that: Self) -> Frame

  /// Check if `frame` is `self`'s frame
  func has (frame : Frame) -> Bool
  
  /// Check if `ancestor` is one of `self`'s ancestor frames
  func has (ancestor: Frame) -> Bool
}

///
///
///
extension Framed {
  
  public var base : Frame {
    // Really just Frame.root
    return self.frame.isBase
      ? self.frame
      : self.frame.base
  }
  
  public func common (_ that: Self) -> Frame {
    return self.has (ancestor: that.frame)
      ? that.frame
      : (that.has (ancestor: self.frame)
        ? self.frame
        : self.base)
  }
  
  public func has (frame : Frame) -> Bool {
    return self.frame === frame
  }
  
  public func has (ancestor: Frame) -> Bool {
    return self.frame === ancestor ||
      (!self.frame.isBase && self.frame.has (ancestor: ancestor))
  }
}

// MARK: Invertable Protocol

///
/// The `IntertableFramed` protocol represents objects that are `Framed` and that are invertable.
///
public protocol Invertable : Framed {
  /// Introduces 'self' constraint
  var inverse : Self { get }
}

// MARK: Translatable Protocol

public protocol Translatable : Framed {
  func translate (_ offset: Position) -> Self
  mutating func translated (_ offset: Position)
}

extension Translatable {
  public mutating func translated (_ offset: Position) {
    self = translate (offset)
  }
}

// MARK: Rotatable Protocol

public protocol Rotatable : Framed {
  func rotate (_ offset: Orientation) -> Self
  mutating func rotated (_ offset: Orientation)
}

extension Rotatable {
  public mutating func rotated (_ offset: Orientation) {
    self = rotate (offset)
  }
}

// MARK: Transformable Protocol

///
///
///
public protocol Transformable : Framed {

  /// Transform 'self' to frame.  Once transformed `self` will represent the *same* physical
  /// position and orientation; it will just be represented in the provided frame.
  mutating func transformed (to frame: Frame)
  
  /// Transform `self` to `frame`
  func transform (to frame: Frame) -> Self
  
  /// Transform `self` by frame to produce a new `framed` that will have a *different* physical
  /// position and orientation.
  func transform (by frame: Frame) -> Self
}

extension Transformable {
  public mutating func transformed (to frame: Frame) {
    self = transform(to: frame)
  }
}

// MARK: Composable Protocol

public protocol Composable {
  func compose  (_ offset: Self) -> Self
}

// ==============================================================================================
//
// MARK: Frame
//
//

/// A Frame represents a 3d spatial position and orientation in a cartesian coordinate system.
///
/// We desperately avoid defining `var position : Position?` with `Optional`.  Clearly the `base`
/// frame has no position nor orientation and thus a recursive `Frame` definition demands use of
/// `Optional` for postion and orientation.  Yet, we find that unsettling.  Another possibility is
/// to use an `ImplicitlyUnwrappedOptional` which we also avoid.  Instead, well, see below.
///
public final class Frame : Framed  {
  
  /// The 'parent' frame
  public internal(set) lazy var frame : Frame = {
    [unowned self] in
    return self
  }()

  /// The unit
  public internal(set) var unit : UnitX<Length> = meter
  
  /// The dual, a DualQuaternion
  public internal(set) var dual : DualQuaternion = DualQuaternion.identity
  
  /// The position in `frame`
  var position : Position {
    return Position (frame: frame, unit: unit, quat: dual.asTranslation)
  }
  
  /// The orientation in `frame`
  var orientation : Orientation {
    return Orientation (frame: frame, quat: dual.asRotation)
  }

  /// Return `true` iff `self` is `base`
  var isBase : Bool {
    return frame === self
  }
  
  // MARK: Position and Orientation Factory
  
  ///
  ///
  ///
  func translation (unit: UnitX<Length>, x: Double, y: Double, z: Double) -> Position {
    return Position (frame: self, unit: unit, x: x, y: y, z: z)
  }
  
  ///
  ///
  ///
  func rotation (angle: Quantity<Angle>, direction: Direction) -> Orientation {
      return Orientation (frame: self, angle: angle, direction: direction)
  }
  
  
  //
  //
  //
  
  // MARK: Initialize
  
  private init () {}
  
  private init (frame: Frame, unit: UnitX<Length>, dual: DualQuaternion) {
    self.frame = frame
    self.unit = unit
    self.dual = dual
  }

  public convenience init (position : Position) {
    self.init (frame: position.frame,
               unit: position.unit,
               dual: DualQuaternion (translation: position.quat))
  }
  
  public convenience init (orientation : Orientation) {
    self.init (frame: orientation.frame,
               unit: meter,
               dual: DualQuaternion (rotation: orientation.quat))
  }
  
  public convenience init (position : Position, orientation : Orientation) {
    self.init (frame: position.frame,
               position: position,
               orientation: orientation)
  }
  
  public convenience init (frame: Frame, position : Position, orientation : Orientation) {
    // self.position = position.transform (to: frame)
    // self.orientation = orientation.transform(to: frame)
    self.init (frame: frame,
               unit: position.unit,
               dual: DualQuaternion (rotation: orientation.transform(to: frame).quat,
                                     translation: position.transform(to: frame).quat))
  }

  // MARK: Root Frame
  
  ///
  /// The `root` frame is the base for all frames.  There is one and only one base frame; you'll
  /// define the semantics of this frame and, importantly, you never need to descend to this depth
  /// if you instead define all our frames under one other frame (which will be a subframe of
  /// base.
  ///
  static let root = Frame()

  internal typealias Projection = (x: Double, y: Double, z:Double)
  

  // MARK: Axis
  
  public enum Axis : Int, CustomStringConvertible {
    case x = 0
    case y = 1
    case z = 2
    
    static var names = ["X", "Y", "Z"]
    
    var name : String { return Axis.names[self.rawValue] }
    
    public var description : String { return name }
  }
  
  public let NUMBER_OF_AXES = 1 + Axis.z.rawValue
}

// MARK: Equatable

extension Frame : Equatable {}
public func == (lhs: Frame, rhs: Frame) -> Bool {
  return lhs === rhs
}

// MARK: Invertable

extension Frame : Invertable {
  ///
  ///
  ///
  public var inverse : Frame {
    return Frame (frame: frame,
                  unit: unit,
                  dual: dual.inverse)
  }
}

// MARK: Rotatable

extension Frame : Rotatable {
  public func rotate (_ offset: Orientation) -> Frame {
    return transform(by: Frame (orientation: offset))
  }
}

// MARK: Translatable

extension Frame : Translatable {
  public func translate (_ offset: Position) -> Frame {
    return transform(by: Frame (position: offset))
  }
}

// MARK: Transformable

extension Frame : Transformable {
  ///
  /// Transform 'self' to frame.  Once transformed `self` will represent the *same* physical
  /// position and orientation; it will just be represented in the provided frame.
  public func transformed (to frame: Frame) {
    let target = transform (to: frame)
    
    self.frame = target.frame
    self.unit = target.frame.unit
    self.dual = target.frame.dual
  }
  
  ///
  ///
  ///
  public func transform (to that: Frame) -> Frame {
    let parent = self.frame
    
    //    guard self !== Frame.root else {
    //      preconditionFailure("transform root")
    //    }
    
    // `that` is `self`'s parent - done, return `self`
    if parent === that {
      return Frame (frame: self.frame, unit: self.unit, dual:  self.dual)
    }
      
      // `frame` is the parent of `self.frame` - convert to `parent`
    else if parent.has (frame: that) {
      return Frame (frame: that,
                    unit: that.unit,
                    dual: parent.dual * self.dual)
    }
      
      // `frame` is an ancestor (beyond parent) of `self.
    else if parent.has (ancestor: that) {
      return self.transform (to: parent.frame)
        .transform (to: that)
      //
    }
      
      // `self is the parent of `frame`
    else if that.has (frame: self) {
      return Frame (frame: that,
                    unit: that.unit,
                    dual: that.dual.inverse)
    }
      
      // `self` is an ancestor (beyond parent) of `frame`
    else if that.has (ancestor: self) {
      let x = that.transform (to: self)
      return Frame (frame: that,
                    unit: that.unit,
                    dual: x.dual.inverse)
    }
      
    else {
      let common = self.common (that)
      
      let self_to_common = self.transform (to: common)
      let common_to_that = common.transform (to: that)
      
      return Frame (frame: that,
                    unit: that.unit,
                    dual:  common_to_that.dual * self_to_common.dual /* * self_to_common.dual */)
    }
  }
  
  ///
  /// Transform `self` by `frame` to produce a new framed that will have a *different* physical
  /// position and orientation.  The result will be in `self.frame`.
  ///
  public func transform (by frame: Frame) -> Frame {
    
    // Transform that into self's frame
    let that = frame.transform (to: self.frame)
    
    return Frame (frame: self.frame,
                  unit: self.unit,
                  dual: that.dual * self.dual)
  }
}

// MARK: Composable

extension Frame : Composable {
  public func compose(_ offset: Frame) -> Frame {
    let that = offset.transform(to: frame)
    return Frame (frame: frame,
                  unit: unit,
                  dual: that.dual * self.dual)
  }
}

/*
Frame C (transform from B) * Vector C = Vector B
1 0 0 1   0   1           1 0 0 1   9   10
0 1 0 0   0   0           0 1 0 0   0    0
0 0 1 0   0 = 0           0 0 1 0   0 =  0
0 0 0 1   1   1           0 0 0 1   1    1
(Frame C is translated from B by 1 unit along X)

Frame B (transform from A) * Vector B = Vector A
1 0 0 3   1   4           1 0 0 3  10   13
0 1 0 0   0   0           0 1 0 0   0    0
0 0 1 0   0 = 0           0 0 1 0   0 =  0
0 0 0 1   1   1           0 0 0 1   1    1
(Frame B is translated from A by 3 units along X)

Frame C (transform from A) * Vector C = Vector A
1 0 0 3   1 0 0 1   0       1 0 0 4   0   4
0 1 0 0   0 1 0 0   0       0 1 0 0   0   0
0 0 1 0   0 0 1 0   0   =>  0 0 1 0   0 = 0
0 0 0 1   0 0 0 1   1       0 0 0 1   1   1
(Frame C is translated from A by 4 units along X which is
FrameB-A * FrameC-B
*/

