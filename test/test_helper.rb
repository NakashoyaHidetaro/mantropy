ENV['RAILS_ENV'] = 'test'
ENV['DIGEST_USER'] ||= 'test'
ENV['DIGEST_PASS'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'rake'

# Rack::Attackはテスト全体では無効にしておく。
# テストスイート全体が同一IP(127.0.0.1)から大量にリクエストするため、
# 有効なままだとthrottleが誤発火して無関係なテストを壊してしまう。
# 検証したいテスト(test/integration/rack_attack_test.rb)側でsetup時に有効化する。
Rack::Attack.enabled = false

class ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def rake_load_tasks
    Rake::Task.clear
    Rails.application.load_tasks
  end
end

# minitest 6 では minitest/mock(Object#stub)が同梱されないため、
# クラスメソッド(特異メソッド)を一時的に差し替える簡易ヘルパを用意する。
# value_or_callable に Proc を渡すと呼び出し時の引数をそのまま渡して実行し、それ以外は値をそのまま返す。
module SingletonMethodStubHelper
  def stub_singleton_method(obj, name, value_or_callable)
    singleton = obj.singleton_class
    own_method = singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
    original = singleton.instance_method(name) if own_method
    singleton.send(:define_method, name) do |*args, **kwargs, &block|
      value_or_callable.respond_to?(:call) ? value_or_callable.call(*args, **kwargs, &block) : value_or_callable
    end
    yield
  ensure
    if own_method
      singleton.send(:define_method, name, original)
    else
      singleton.send(:remove_method, name)
    end
  end
end

class ActiveSupport::TestCase
  include SingletonMethodStubHelper
end
