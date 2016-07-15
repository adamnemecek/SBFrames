//
//  Quaternion.swift
//  SBFrames
//
//  Created by Ed Gamble on 6/26/16.
//  Copyright © 2016 Opus Logica Inc. All rights reserved.
//

import Darwin.C.math

///
/// Note: We do not use Apple's GLKit GLKQuaternion because it is based on 'Float'.
///
/// https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
public struct Quaternion : Equatable {

  //
  // Representation is: q0 + q1 * i + q2 * j + q3 * k
  //

  var q0: Double = 0.0
  var q1: Double = 0.0
  var q2: Double = 0.0
  var q3: Double = 0.0
  
  /// Seriously?
  static let epsilon : Double = 1e-10
  
  //
  // MARK: Predicates
  //
  
  ///
  /// Return `true` if `self` has a norm of 1.0
  ///
  /// - parameter epsilon: the error allows
  ///
  /// - returns: `true` if the `norm` is 1.0 +- epsilon; `false` otherwise.
  ///
  public func isUnit (epsilon : Double = Quaternion.epsilon) -> Bool {
    let norm = self.norm
    return 1.0 - epsilon <= norm && norm <= 1.0 + epsilon
  }

  ///
  /// Return `true` if `self` has a norm of 1.0
  ///
  /// - returns: `true` if the `norm` is 1.0; `false` otherwise.
  ///
  public var isUnit : Bool {
    return self.norm.isEqual(to: 1.0)
  }

  ///
  /// Return `true` if `self` has a norm of 0.0
  ///
  /// - parameter epsilon: the error allows
  ///
  /// - returns: `true` if the `norm` is 0.0 +- epsilon; `false` otherwise.
  ///
  public func isZero (epsilon : Double = Quaternion.epsilon) -> Bool {
    let norm = self.norm
    return -epsilon <= norm && norm <= epsilon
  }

  ///
  /// Return `true` if `self` has a norm of 0.0
  ///
  /// - returns: `true` if the `norm` is 0.0; `false` otherwise.
  ///
  public var isZero : Bool {
    return self.norm.isZero
  }
  
  ///
  /// Return `true` if `self` his a pure quaternion (has `q0` of 0.0)
  ///
  /// - returns: `true` if `q0` is 0.0 +- epsilon; `false` otherwise.
  ///
  public func isPure (epsilon : Double = Quaternion.epsilon) -> Bool {
    return -epsilon <= q0 && q0 <= epsilon
  }
  
  ///
  /// Return `true` if `self` his a pure quaternion (has `q0` of 0.0)
  ///
  /// - returns: `true` if `q0` is 0.0; `false` otherwise.
  ///
  public var isPure : Bool {
    return q0.isZero
  }
  
  //
  // MARK: Norm
  //
  
  ///
  /// The quaternion's norm
  ///
  /// - returns: the norm
  ///
  public var norm : Double {
    return sqrt (q0*q0 + q1*q1 + q2*q2 + q3*q3) // sqrt (dot (self))
  }

  ///
  /// Return the normalized quaterion for `self`.  If the norm is zero, then the result is nil
  ///
  public var normalize : Quaternion? {
    let norm = self.norm
    
    return norm.isZero
      ? nil
      : Quaternion (q0: q0/norm, q1: q1/norm, q2: q2/norm, q3: q3/norm)
  }

  ///
  /// Normalize `self` if the norm is not zero
  ///
  public mutating func normalized () -> Bool {
    let norm = self.norm

    if !norm.isZero {
      q0 /= norm
      q1 /= norm
      q2 /= norm
      q3 /= norm
      return true
    }
    return false
  }
  
  //
  // MARK: Basic Operators
  //
  
  ///
  /// The dot product of `self` by `that`
  ///
  /// - parameter that:
  ///
  /// - returns: the norm
  ///
  public func dot (_ that: Quaternion) -> Double {
    return self.q0 * that.q0 +
      self.q1 * that.q1 +
      self.q2 * that.q2 +
      self.q3 * that.q3
  }

  ///
  /// The quaternion's conjugate
  ///
  /// - returns: the conjugate
  ///
  public var conjugate : Quaternion {
    return Quaternion(q0: q0, q1: -q1, q2: -q2, q3: -q3)
  }

  ///
  /// The quaternion's inverse
  ///
  /// - returns: the inverse
  ///
  public var inverse : Quaternion? {
    let dot = self.dot(self)
    
    return dot.isZero
      ? nil
      : Quaternion (q0: q0/dot, q1: -q1/dot, q2: -q2/dot, q3: -q3/dot)
  }
  
  //
  // MARK: Rotate and Translate
  // 
  
  /// Return a quaternion of `self` rotated by `that`.  This *only* makes sense when `self` is a
  /// pure quaternion.  This is  that * self * that^
  func rotate (by that: Quaternion) -> Quaternion {
    return that * self * that.conjugate
  }
  
  /// Return a quaternion of `self` translated (added to) `that`.  This *only* makes sense when
  /// `self` and `that` are both pure quaternions
  func translate (by that: Quaternion) -> Quaternion {
    return self + that
  }
  
  //
  // MARK: Angle + Direction
  //
  
  ///
  /// Extract the (angle, direction) from `self`.
  ///
  /// - returns: A tuple of `angle` and `direction` where `direction` is a triple.
  ///
  public var asAngleDirection : (angle: Double, direction: (Double, Double, Double))? {
    //    guard let that = normalize else { return nil }
    if let that = normalize {
      
      let angle = 2 * atan2 (sqrt (q1*q1 + q2*q2 + q3*q3), q0)
      //let angle = 2 * acos(that.q0)
      
      guard !angle.isZero else {
        return (angle: angle, direction: (0.0, 0.0, 0.0))
      }
      
      let df = sin (angle / 2)  // direction factor

      return (angle: angle,
              direction: (that.q1/df, that.q2/df, that.q3/df))
    }
      
    else { return nil }
  }

  ///
  /// Make from (angle, direction)
  ///
  /// - parameter angle:
  /// - parameter direction:
  ///
  /// - returns:
  public static func makeAsAngleDirection (angle: Double, direction: (Double, Double, Double)) -> Quaternion? {
    let d = direction
    let n = sqrt (d.0 * d.0 + d.1 * d.1 + d.2 * d.2)
    
    if n.isZero { return Quaternion.identity }
    
    let ca2 = cos (angle / 2)
    let sa2 = sin (angle / 2)
    
    return Quaternion (q0: ca2,
                       q1: sa2 * d.0/n,
                       q2: sa2 * d.1/n,
                       q3: sa2 * d.2/n)
  }
  
  //
  // MARK: Fixed/Euler Angles
  //
  
  public var asFixedXYZAngles : (phi: Double, theta: Double, psi: Double) {
    return (phi:   atan2 (2 * (q0*q1 + q2*q3), 1 - 2 * (q1*q1 + q2*q2)),
            theta: asin  (2 * (q0*q2 - q3*q1)),
            psi:   atan2 (2 * (q0*q3 + q1*q2), 1 - 2 * (q2*q2 + q3*q3)))
  }

  // MARK: See Above
  
  public static func makeAsYawPitchRoll (yaw: Double, pitch: Double, roll: Double) -> Quaternion {
    let ys = sin (yaw / 2.0)
    let yc = cos (yaw / 2.0)
    
    let ps = sin (pitch / 2.0)
    let pc = cos (pitch / 2.0)
    
    let rs = sin (roll / 2.0)
    let rc = cos (roll / 2.0)
    
    // Perhaps.
    return Quaternion (q0: yc * ps * rc + ys * pc * rs,
                       q1: ys * pc * rc - yc * ps * rs,
                       q2: yc * pc * rs - ys * ps * rc,
                       q3: yc * ps * rc + ys * ps * rs)
  }
  // var asEulerXXXAngles :
  
  //
  // MARK: Constants
  //
  public static let identity = Quaternion (q0: 1.0, q1: 0.0, q2: 0.0, q3: 0.0)
  public static let zero     = Quaternion (q0: 0.0, q1: 0.0, q2: 0.0, q3: 0.0)
}

public func == (lhs:Quaternion, rhs:Quaternion) -> Bool {
  return lhs.q0 == rhs.q0 &&
    lhs.q1 == rhs.q1 &&
    lhs.q2 == rhs.q2 &&
    lhs.q3 == rhs.q3
}

///
/// Return a quaternion representing the ofsset (aka addition) for `self` with `that`.
///
/// - parameter lhs:
/// - parameter rhs:
///
/// - returns: 
///
public func + (lhs:Quaternion, rhs:Quaternion) -> Quaternion {
  return Quaternion (q0: lhs.q0 + rhs.q0,
                     q1: lhs.q1 + rhs.q1,
                     q2: lhs.q2 + rhs.q2,
                     q3: lhs.q3 + rhs.q3)
}

///
/// Return a quaternion representing the composition (aka product) as `that` * `self`.  The
/// composition is not commutative - self.compose(that) => that * self => perform `self` then
/// perform `that`
///
/// - parameter lhs:
/// - parameter rhs:
///
/// - returns:
///
public func * (lhs:Quaternion, rhs:Quaternion) -> Quaternion {
  return Quaternion (q0: lhs.q0 * rhs.q0 - lhs.q1 * rhs.q1 - lhs.q2 * rhs.q2 - lhs.q3 * rhs.q3,
                     q1: lhs.q0 * rhs.q1 + lhs.q1 * rhs.q0 + lhs.q2 * rhs.q3 - lhs.q3 * rhs.q2,
                     q2: lhs.q0 * rhs.q2 - lhs.q1 * rhs.q3 + lhs.q2 * rhs.q0 + lhs.q3 * rhs.q1,
                     q3: lhs.q0 * rhs.q3 + lhs.q1 * rhs.q2 - lhs.q2 * rhs.q1 + lhs.q3 * rhs.q0)
}

/// Return a quaternion of `self` scaled bu `factor`.  The *only* makes sense when `self` is a
/// pure quaternion (or if one is normalizing a rotation).
///
/// - parameter lhs:
/// - parameter rhs:
///
/// - returns:
///
public func * (lhs:Double, rhs:Quaternion) -> Quaternion {
  return Quaternion (q0: lhs * rhs.q0,
                     q1: lhs * rhs.q1,
                     q2: lhs * rhs.q2,
                     q3: lhs * rhs.q3)
}

/// Return a quaternion of `self` scaled bu `factor`.  The *only* makes sense when `self` is a
/// pure quaternion (or if one is normalizing a rotation).
///
/// - parameter lhs:
/// - parameter rhs:
///
/// - returns:
///
public func * (lhs:Quaternion, rhs:Double) -> Quaternion {
  return rhs * lhs
}

// ===============================================================================================
//
// MARK: Dual Quaternion
//
//

///
/// A DualQuaternion represents a rotation followed by a translation
///
public struct DualQuaternion : Equatable {

  let real : Quaternion
  let dual : Quaternion

  ///
  /// The norm of `self`
  ///
  public var norm : Double {
    return self.real.norm
  }
  
  ///
  /// The normalized `self` or nil.  If the `norm` is 0.0, then normalization is undefined and thus
  /// nil is returned.
  ///
  /// - returns: `self` normalized
  public var normalize : DualQuaternion? {
    let norm = self.norm
    
    return norm.isZero
    ? nil
    : DualQuaternion (real: self.real * (1/norm),
                      dual: self.dual * (1/norm))
  }

  ///
  /// Normalize `self`.  If the `norm` is 0.0, then `self` is unchanged and `false` is returned.
  ///
  /// - returns: `true` if `self` was normalized; `false` otherwise
  public mutating func normalized () -> Bool {
    if let that = self.normalize {
      self = that
      return true
    }
    return false
  }
  
  /// The `ConjugateType` defines the options when computing the `DualQuaternion`'s conjugate
  ///   QUATERNION:
  ///   DUAL:
  ///   DUAL_AND_QUATERNION:
  public enum ConjugateType {
    case QUATERNION
    case DUAL
    case DUAL_AND_QUATERNION
  }
  
  ///
  /// The conjugate
  ///
  /// - parameter type: The conjugate type desired.
  ///
  /// - returns: the conjugate of `self`
  ///
  public func conjugate (_ type: ConjugateType) -> DualQuaternion {
    switch type {
    case .QUATERNION:
      return DualQuaternion (real: self.real.conjugate,
                             dual: self.dual.conjugate)
    case .DUAL:
      return DualQuaternion (real: self.real,
                             dual: -1 * self.dual)
      
    case .DUAL_AND_QUATERNION:
      return DualQuaternion (real: self.real.conjugate,
                             dual: -1 * self.dual.conjugate)
    }
  }
  
  ///
  /// The inverse.  This is defined such that self * self.inverse == identity
  ///
  /// - returns: the inverse
  ///
  public var inverse : DualQuaternion {
    return conjugate(.QUATERNION)
  }
  
  // Maybe
  public func transform (translation: Quaternion) -> Quaternion {
    let translationAsDQ = DualQuaternion (real: Quaternion.identity, dual: translation)
    return (self * translationAsDQ  * self.conjugate(.DUAL_AND_QUATERNION)).dual
  }

  // Maybe
  public func transform (rotation: Quaternion) -> Quaternion {
    let rotationAsDQ = DualQuaternion (real: rotation, dual: Quaternion.zero)
    return (self * rotationAsDQ * self.conjugate(.DUAL_AND_QUATERNION)).real
  }
  
  var composer : (DualQuaternion) -> DualQuaternion {
    return { (that: DualQuaternion) -> DualQuaternion in
      return that * self
    }
  }
  
  //
  //
  //
  
  /// 
  /// Extract the rotation quaternion
  ///
  /// - returns: the rotation quaternion encoded by `self`
  ///
  public var asRotation : Quaternion {
    return self.real
  }

  ///
  /// Extract the translation quaternion
  ///
  /// - returns: the translation quaternion encoded by `self`
  ///
  public var asTranslation : Quaternion {
    return 2.0 * (self.dual * self.real.conjugate)
  }

  ///
  /// Extract the rotation and translation quaternions
  ///
  /// - returns: a tuple with the rotation and translation quaternions encoded by `self`
  ///
  public var asRotationAndTranslation : (rotation: Quaternion, translation: Quaternion) {
    return (rotation: asRotation,
            translation: asTranslation)
  }
  
  // MARK: Initialization
  
  ///
  /// Initialize given proper `real` and `qual` quaternions.  The `real` part must be normalized.
  ///
  /// - parameter real:
  /// - parameter dual:
  ///
  init (real: Quaternion, dual: Quaternion) {
    self.real = real
    self.dual = dual
  }

  ///
  /// Initialize given a `rotation` and `translation`
  ///
  /// - parameter rotation:
  /// - parameter translation:
  ///
  public init (rotation: Quaternion, translation: Quaternion) {
    self.init (real: rotation,
               dual: 0.5 * (translation * rotation))
  }

  ///
  /// Initialize given a `rotation` and using a translation as Quaternion.zero
  ///
  /// - parameter rotation:
  ///
  public init (rotation: Quaternion) {
    self.init (real: rotation,
               dual: Quaternion.zero)
  }

  ///
  /// Initialize given a `translation` and using a rotation as Quaternion.identity
  ///
  /// - parameter translation:
  ///
  public init (translation: Quaternion) {
    self.init (real: Quaternion.identity,
               dual: 0.5 * translation)
  }
  
  ///
  public var unitCondition : Quaternion {
    return self.real.conjugate * self.dual + self.dual.conjugate * self.real
  }

  ///
  /// The itentity using a zero translation and an identity rotation.
  ///
  public static var identity = DualQuaternion (real: Quaternion.identity,
                                        dual: Quaternion.zero)
}

public func == (lhs:DualQuaternion, rhs:DualQuaternion) -> Bool {
  return lhs.real == rhs.real &&
    lhs.dual == rhs.dual
}

public func + (lhs:DualQuaternion, rhs:DualQuaternion) -> DualQuaternion {
  return DualQuaternion (real: lhs.real + rhs.real,
                         dual: lhs.dual + rhs.dual)
}

public func * (lhs:DualQuaternion, rhs:DualQuaternion) -> DualQuaternion {
  return DualQuaternion (real: lhs.real * rhs.real,
                         dual: lhs.real * rhs.dual + lhs.dual * rhs.real)
}

