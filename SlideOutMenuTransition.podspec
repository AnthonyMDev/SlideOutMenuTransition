Pod::Spec.new do |s|
    s.name              = 'SlideOutMenuTransition'
    s.version           = '1.0.0'
    s.summary           = ''

    s.homepage          = 'https://github.com/AnthonyMDev/SlideOutMenuTransition'
    s.license           = { :type => 'MIT', :file => 'LICENSE' }
    s.author            = { 'Anthony Miller' => 'AnthonyMDev@gmail.com' }
    s.social_media_url  = 'https://twitter.com/AnthonyMDev'
    
    s.source            = { :git => 'https://github.com/AnthonyMDev/SlideOutMenuTransition.git', :tag => s.version.to_s }
    s.requires_arc      = true
    
    s.ios.deployment_target     = '8.0'

    s.source_files = 'SlideOutMenuTransition/*.swift'

end
