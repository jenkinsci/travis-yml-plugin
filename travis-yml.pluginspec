Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = "travis-yml"
  plugin.display_name = "Travis YML Plugin"
  plugin.version = '0.1.1'
  plugin.description = 'Run Jenkins builds using .travis.yml in your project'

  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Travis+YML+Plugin'
  plugin.developed_by "ikasam_a", "masaki.nakagawa@gmail.com"
  plugin.uses_repository :github => "travis-yml-plugin"

  plugin.depends_on 'ruby-runtime', '0.10'
  plugin.depends_on 'git', '1.1.11'
end
