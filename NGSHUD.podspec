Pod::Spec.new do |s|
  s.name         = "NGSHUD"
  s.version      = "1.0.1"
  s.summary      = "A short description of MyFramework."
  s.description  = <<-DESC
  A much much longer description of MyFramework.
                   DESC
  s.homepage     = "https://github.com/League2EB/NGSHUD.git"
  s.license      = "Copyleft"
  s.author       = { "Junda" => "a@a.a" }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '9.0'
  s.source_files  = "Source/**/*.swift"
  s.dependency "PKHUD"
  s.dependency "ReachabilitySwift"
  s.dependency "SnapKit"
  s.dependency 'Kingfisher','~> 4.0'
end