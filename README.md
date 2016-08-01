# Frame, Orientation, Position, Direction, Quaternion, DualQuaternion

Frames is a collection of ...

![License](https://img.shields.io/cocoapods/l/SBFrames.svg)
[![Language](https://img.shields.io/badge/lang-Swift-orange.svg?style=flat)](https://developer.apple.com/swift/)
![Platform](https://img.shields.io/cocoapods/p/SBFrames.svg)
![](https://img.shields.io/badge/Package%20Maker-compatible-orange.svg)
[![Version](https://img.shields.io/cocoapods/v/SBFrames.svg)](http://cocoapods.org)

## Features

### Frame

A Frame represents a 3D spatial position and orientation in a cartesian coordinate system.

### Orientation

An Orientation represents the axes in a 3D cartesian coordinate system defined by a `frame.`  An
Orientation adhers to the `Framed` protocol and can be rotated, inverted and transformed.

### Position

A Position represents a 3d spatial position in a certesian coordinate system defined by a
`frame`.  A Position adhers to the `Framed` protocol and can be scaled, translated, rotated, 
inverted and transformed.  A Position can be converted into a `Direction`.  With two Positions
a can computate the distance and angle between the two postions; of the two positions are in
a different frame, then they are converted to the same frame before the desired computation.

### Direction

A Direction represents a direction to a postion defined in a `Frame`.  A Direction can be
inverted, rotated and transformed.  The angle between a direction and another direction or an
axis can be computed.  A Direction can produce a Position (given a `unit`) and an Orientation
(given an `angle` about the direction).

### Quaternion

A Quaternion is a convenient, efficient and numerically stable representation for orientations
and for positions.  For an orientation, a quaternion uses a direction and a rotation about that
direction.  Such a quaternion is normalized (norm/magnitude is 1).  For a position, a quaternion
uses the three position coordianates.  Such a quaternion is 'pure'.

### DualQuaternion

A DualQuaternion represents a rotation followed by a translation in a computationally
convenient form.  A DualQuaternion has 'real' and 'dual' Quaternion parts which are derived 
from the specified rotation (R) and translation (T).  [The 'real' part is 'R'; the 'dual' part
is'T * R / 2'].  Multiplication of DualQuaternions composes frame transforamations. Q * P
implies 'transform by P, then by Q'

A DualQuaternion can be built from a rotation and/or a translation.  Given a DualQuaternion
the rotation and translations can be extracted.

Equality of a DualQuaternion is based on equality of its constituent 'real' and 'dual'
Quaternions.

A DualQuaternion has three types of conjugates; they are used depending on the need.

## Usage

Access the framework with

```swift
import SBFrames
```

## Installation

Three easy installation options:

### Apple Package Manager

In your Package.swift file, add a dependency on SBFrames:

```swift
import PackageDescription

let package = Package (
  name: "<your package>",
  dependencies: [
    // ...
    .Package (url: "https://github.com/EBGToo/SBFrames.git",  majorVersion: 0),
    // ...
  ]
)
```

### Cocoa Pods

```ruby
pod 'SBFrames', '~> 0.1'
```

### XCode

```bash
$ git clone https://github.com/EBGToo/SBFrames.git SBFrames
```

Add the SBFrames Xcode Project to your Xcode Workspace; you'll also need the [SBUnits](https://github.com/EBGToo/SBUnits) package
as well
