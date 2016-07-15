//
//  QuaternionTest.swift
//  SBFrames
//
//  Created by Ed Gamble on 7/13/16.
//  Copyright © 2016 Opus Logica Inc. All rights reserved.
//

import XCTest
import SBUnits
import GLKit

@testable import SBFrames

class QuaternionTest: XCTestCase {
        
    let accuracy = Quaternion.epsilon
    
    override func setUp() {
      super.setUp()
    }
    
    override func tearDown() {
      super.tearDown()
    }
    
  func checkValues (_ q: Quaternion, q0: Double, q1: Double, q2: Double, q3: Double) {
    XCTAssertEqualWithAccuracy(q.q0, q0, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q.q1, q1, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q.q2, q2, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q.q3, q3, accuracy: accuracy)
    }
    
  func testInit() {
    let qz = Quaternion.zero;
    let qi = Quaternion.identity
    
    checkValues(qz, q0: 0.0, q1: 0.0, q2: 0.0, q3: 0.0)
    checkValues(qi, q0: 1.0, q1: 0.0, q2: 0.0, q3: 0.0)
    
    let q0 = Quaternion (q0: 1.0, q1: 2.0, q2: 3.0, q3: 4.0)
    checkValues(q0, q0: 1.0, q1: 2.0, q2: 3.0, q3: 4.0)

    let q1 = Quaternion.makeAsAngleDirection(angle: Double.pi/2.0, direction: (1.0, 1.0, 1.0))!
    
    let (angle:a, direction:d) = q1.asAngleDirection!
    XCTAssertEqual(a, Double.pi/2.0)
    
    let dm = 1/sqrt(3.0)
    XCTAssertEqual(d.0, dm)
    XCTAssertEqual(d.1, dm)
    XCTAssertEqual(d.2, dm)
  }
  
  func testQScale () {
    let qa = Quaternion.makeAsAngleDirection(angle: Double.pi/2.0, direction: (1.0, 1.0, 1.0))!
    let qb = 2.0 * qa
    checkValues(qb, q0: 2*qa.q0, q1: 2*qa.q1, q2: 2*qa.q2, q3: 2*qa.q3)
    
  }
  func testQCompose () {
    let q1 = Quaternion.makeAsAngleDirection(angle: Double.pi/2.0, direction: (1.0, 1.0, 1.0))!
    XCTAssertTrue(q1.isUnit)
    let q2 = q1 * q1
    let (angle:a, direction:_) = q2.asAngleDirection!
    XCTAssertEqualWithAccuracy(a, Double.pi, accuracy: accuracy)
    
    let q3 = q1.conjugate * q1
    let (angle:a3, direction:_) = q3.asAngleDirection!
    XCTAssertEqualWithAccuracy(a3, 0, accuracy: accuracy)
    
    let q4 = q1 * q1 * q1 * q1
    let (angle:a4, direction:_) = q4.asAngleDirection!
    XCTAssertEqualWithAccuracy(a4, 2*Double.pi, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q4.norm, 1.0, accuracy: accuracy)
    XCTAssertTrue(q4.isUnit(epsilon: accuracy))
  }
  
  func testQComposeToo () {
    let qA = Quaternion (q0: 1.0, q1: 0.5, q2: -3.0, q3: 4.0)
    let qB = Quaternion (q0: 6.0, q1: 2.0, q2:  1.0, q3: -9.0)
    let qR = qA * qB
    checkValues(qR, q0: 44.0, q1: 28.0, q2: -4.5, q3: 21.5)
  }

  func testQRotate () {
    let qr = Quaternion.makeAsAngleDirection(angle: Double.pi/2.0, direction: (0.0, 0.0, 1.0))!
    let qa = Quaternion (q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)
    
    let qb = qa.rotate(by: qr)
    
    checkValues (qb, q0: 0.0, q1: 0.0, q2: 1.0, q3: 0.0)

    let qc = qb.rotate(by: qr)
    checkValues (qc, q0: 0.0, q1: -1.0, q2: 0.0, q3: 0.0)

    let qd = qb.rotate(by: qr.conjugate)
    checkValues (qd, q0: 0.0, q1: 1.0, q2: 0.0, q3: 0.0)

  }
  
  func testQTranslate () {
    let qa = Quaternion (q0: 0.0, q1: 1.0, q2: 1.0, q3: 3.0)
    let qb = Quaternion (q0: 0.0, q1: 3.0, q2: 1.0, q3: 1.0)
    let qc = qa.translate(by: qb)
    
    XCTAssertEqual(qc, Quaternion (q0: 0.0, q1: 4.0, q2: 2.0, q3: 4.0))
  }
  
  func testQPredicate () {
    let qa = Quaternion.makeAsAngleDirection(angle: Double.pi/2.0, direction: (1.0, 1.0, 1.0))!
    XCTAssertEqualWithAccuracy(qa.norm, 1.0, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(qa.dot(qa), 1.0, accuracy: accuracy)
    
    XCTAssertTrue (qa.isUnit)
    XCTAssertFalse (qa.isPure)
    XCTAssertFalse (qa.isZero)
    
    var qb = Quaternion (q0: 0.0, q1: 1.0, q2: 1.0, q3: 3.0)
    XCTAssertTrue(qb.isPure)
    XCTAssertFalse(qb.isUnit(epsilon: accuracy))
    
    _ = qb.normalized()
    XCTAssertTrue(qb.isUnit(epsilon: accuracy))
  }
  
  func testPerformanceQuaternion() {
    let xq = Quaternion.makeAsAngleDirection(angle: Double.pi/2, direction: (0.0, 0.0, 1.0))!
    self.measure {
      var n = 1000000
      while n > 0 {
        let _ = xq * xq * xq * xq
        n -= 1
      }
    }
  }
  
  func testPerformanceGLK () {
    let gq = GLKQuaternionMakeWithAngleAndAxis(Float.pi/2, 0.0, 0.0, 1.0)
    self.measure {
      var n = 1000000
      while n > 0 {
        let _ = GLKQuaternionMultiply(gq, GLKQuaternionMultiply(gq, GLKQuaternionMultiply(gq, gq)))
        n -= 1
      }
    }
  }

}
