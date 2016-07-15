Pod::Spec.new do |s|
  s.name     = 'SBFrames'
  s.version  = '0.1.0'
  s.license  = 'MIT'
  s.summary  = 'Position, Direction, Orientation, Frame'
  s.description = <<-DESC
  
  DESC
  
  s.homepage = 'https://github.com/EBGToo/SBFrames'
  s.authors = { 'Ed Gamble' => 'ebg@opuslogica.com' }
  s.source  = { :git => 'https://github.com/EBGToo/SBFrames.git',
  	        :tag => s.version }

  s.source_files = 'Sources/*.swift'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.dependency "SBUnits",  "~> 0.1"
end
