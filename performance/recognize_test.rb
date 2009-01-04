require 'rubygems'
require 'test/unit'
require 'action_controller'
require 'action_controller/performance_test'

require 'krauter'


# Setup dummy controllers
module Admin; end

('A'..'Z').each do |l|
  controller = "#{l}Controller"
  Object.const_set(controller, Class.new)
  Admin.const_set(controller, Class.new)
end

SmallRouteSet = ActionController::Routing::RouteSet.new
# BUG: Need to initialize a dummy named route collection
SmallRouteSet.named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
SmallRouteSet.draw do |map|
  map.resources :a, :b, :c, :d, :z
end

LargeRouteSet = ActionController::Routing::RouteSet.new
# BUG: Need to initialize a dummy named route collection
LargeRouteSet.named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
LargeRouteSet.draw do |map|
  map.resources :a

  map.with_options :member => { :foo => :get, :bar => :put, :baz => :delete } do |m|
    m.resources :b, :c, :d, :e, :f, :g

    m.namespace(:admin) do |admin|
      admin.resources :h, :i, :j, :k, :l, :m, :n
    end

    m.with_options :has_many => [:b, :c, :d, :e, :f, :g] do |n|
      n.resources :h, :i, :j, :k, :l, :m, :n

      n.with_options :collection => { :foo => :get, :bar => :put, :baz => :delete } do |o|
        o.resources :o, :p, :q, :r, :t, :u, :v
      end
    end

    m.resources :w, :x, :y
  end

  map.resources :z
end


class RecognizeTest < ActionController::PerformanceTest
  class MockRequest
    attr_reader :path, :request_method
    attr_accessor :path_parameters

    def initialize(request_method, path)
      @path, @request_method = path, request_method
      @path_parameters = {}
    end
  end

  BestCaseMatch = MockRequest.new(:get, "/a")
  WorstCaseMatch = MockRequest.new(:get, "/z/1/edit.xml")

  test "with a small set of routes to recognize the best case" do
    SmallRouteSet.recognize(BestCaseMatch)
  end

  test "with a small set of routes to recognize the worst case" do
    SmallRouteSet.recognize(WorstCaseMatch)
  end

  test "with a large set of routes to recognize the best case" do
    LargeRouteSet.recognize(BestCaseMatch)
  end

  test "with a large set of routes to recognize the worst case" do
    LargeRouteSet.recognize(WorstCaseMatch)
  end
end
