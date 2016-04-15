Pod::Spec.new do |s|
  s.name      = 'FSQRoutes'
  s.version   = '1.0.0'
  s.platform  = :ios, '8.0'
  s.summary   = 'An easy to use and flexible URL routing framework for iOS.'
  s.homepage  = 'https://github.com/foursquare/FSQRoutes'
  s.license   = { :type => 'Apache', :file => 'LICENSE.txt' }
  s.authors   = { 'Brian Dorfman' => 'https://twitter.com/bdorfman' }
  s.source    = { :git => 'https://github.com/foursquare/FSQRoutes.git',
                  :tag => "v#{s.version}" }
  s.source_files  = 'FSQRoutes/*.{h,m}'
  s.requires_arc  = true
end
