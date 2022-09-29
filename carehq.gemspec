Gem::Specification.new do |s|
  s.name        = "carehq"
  s.version     = "0.0.1"
  s.summary     = "CareHQ API client"
  s.description = "CareHQ API client for Ruby."
  s.authors     = ["Anthony Blackshaw"]
  s.email       = "ant@crmhq.co.uk"
  s.files       = ["lib/carehq.rb", "lib/carehq/exceptions.rb"]
  a.add_dependency 'httparty', '~> 0.20.0'
  s.homepage    = "https://github.com/CareHQ/carehq-ruby"
  s.license     = "MIT"
end
