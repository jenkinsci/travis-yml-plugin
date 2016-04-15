require_relative 'travis_yml_script'

class TravisYmlBuilder < Jenkins::Tasks::Builder
  display_name "Build using .travis.yml"

  def initialize(attrs = {})
  end

  ##
  # Runs before the build begins
  #
  # @param [Jenkins::Model::Build] build the build which will begin
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def prebuild(build, listener)
  end

  ##
  # Runs the step over the given build and reports the progress to the listener.
  #
  # @param [Jenkins::Model::Build] build on which to run this step
  # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def perform(build, launcher, listener)
    ws = build.workspace
    envvars = build.native.getEnvironment()

    script = TravisYmlScript.new(:file => ws.join(".travis.yml"))
    script.build

    now = Time.now.instance_eval { '%s.%03d' % [ strftime('%Y%m%d%H%M%S'), (usec/1000.0).round ] }
    runner = ws.join("hudson.#{now}.sh")
    runner.native.write(script.to_s, nil) # XXX: need Jenkins::FilePath#write

    ret = execute_script!(launcher, runner, { :chdir => ws, :out => listener })
    build.abort unless ret == 0
  end

  private

  def execute_script!(launcher, envvars, script, opts)
    if script && script.exist?
      ret = execute_script(launcher, envvars, script, opts)
      script.delete
      ret
    end
  end

  def execute_script(launcher, envvars, script, opts)
    if script && script.exist?
      launcher.execute(envvars, "bash", script.to_s, opts)
    end
  end
end
