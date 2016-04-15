require 'yaml'
require 'shellwords'

class TravisYmlScript
  def initialize(attrs = {})
    @cmds = []
    @file = attrs[:file]
  end

  def build
    reset

    conf = YAML.load(@file.read)

    build_env(conf)
    build_proc(conf)
    build_post_proc(conf)
  end

  def to_s
    [ header, @cmds, footer ].flatten.join("\n")
  end

  private

  def header
    return <<__HEADER__
#!/usr/bin/env bash

capture_result() {
  local result=$1
  export TRAVIS_JENKINS_RESULT=$(( ${TRAVIS_JENKINS_RESULT:-0} | $(($result != 0)) ))
}

export CI=1
export CONTINUOUS_INTEGRATION=1
export TRAVIS_JENKINS_RESULT=0

__HEADER__
  end

  def footer
    return <<__FOOTER__
exit $TRAVIS_JENKINS_RESULT
__FOOTER__
  end

  def reset
    @cmds = []
  end

  def build_env(conf)
    values(conf, "env").each do |env|
      export(env)
    end
  end

  def build_proc(conf)
    %w[ before_install install before_script script after_script ].each do |k|
      values(conf, k).each do |cmd|
        run_if("$TRAVIS_JENKINS_RESULT -eq 0") do
          echo(cmd)
          run(cmd)
          capture_result
        end
      end
    end
  end

  def build_post_proc(conf)
    values(conf, "after_success").each do |cmd|
      run_if("$TRAVIS_JENKINS_RESULT -eq 0") do
        echo(cmd)
        run(cmd)
      end
    end

    values(conf, "after_failure").each do |cmd|
      run_if("$TRAVIS_JENKINS_RESULT -ne 0") do
        echo(cmd)
        run(cmd)
      end
    end
  end

  def values(conf, key)
    [ conf[key] || [] ].flatten.map(&:to_s)
  end

  def export(cmd)
    run("export #{cmd}")
  end

  def echo(cmd)
    cmd_e = Shellwords.shellescape(cmd)
    run("echo $ "+cmd_e)
  end

  def capture_result
    run("capture_result $?")
  end

  def run(cmd)
    @cmds.push(cmd)
  end

  def run_if(cond)
    if block_given?
      run("if [ #{cond} ]; then")
      yield
      run("fi")
    end
  end
end
