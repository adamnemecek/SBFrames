//
//  Vector.swift
//  SBFrames
//
//  Created by Ed Gamble on 1/20/16.
//  Copyright © 2016 Opus Logica Inc. All rights reserved.
//
import Accelerate
//import GLKit

// Vector

public protocol VectorProtocol {
  associatedtype Value : FloatingPoint
  
  func withBaseAddress<R> (_ body: @noescape (UnsafePointer<Value>) throws -> R) rethrows -> R

  var count : Int { get }
  func sum () ->  Value
  func norm () -> Value
}

//
//
//
extension VectorProtocol where Value == Double {
  public func sum () -> Double {
    return withBaseAddress {
      var result = Double()
      vDSP_sveD($0, 1, &result, vDSP_Length(count))
      return result
    }
  }
  
  public func norm () -> Double {
    return withBaseAddress {
      var result = Double()
      vDSP_svesqD($0, 1, &result, vDSP_Length(count))
      return result
    }
  }

}

extension VectorProtocol where Value == Float {
  public func sum () -> Float {
    return withBaseAddress {
      var result = Float()
      vDSP_sve($0, 1, &result, vDSP_Length(count))
      return result
    }
  }
  
  public func norm () -> Float {
    return withBaseAddress {
      var result = Float()
      vDSP_svesq($0, 1, &result, vDSP_Length(count))
      return result
    }
  }
}


public struct Vector<Value : FloatingPoint> : VectorProtocol {
  
  var ca : ContiguousArray<Value>
  
  public var count : Int {
    return ca.count
  }

  public subscript (index : Int) -> Value {
    get { return ca[index] }
    set (newValue) { ca[index] = newValue }
  }
  

  public func withBaseAddress<R> (_ body: @noescape (UnsafePointer<Value>) throws -> R) rethrows -> R {
    return try ca.withUnsafeBufferPointer {  return try body ($0.baseAddress!) }
  }

  public init (count : Int) {
    self.ca = ContiguousArray<Value>(repeating: Value(), count: count)
  }
  
  public func sum () -> Value {
    return ca.reduce (Value(), +)
  }
  
  public func norm () -> Value {
    return ca.reduce (Value()) { $0 + $1 * $1 }
  }
}

extension Vector {
}

