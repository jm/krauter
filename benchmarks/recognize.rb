require 'rubygems'
require 'action_controller'

require File.expand_path(File.dirname(__FILE__) + "/../lib/krauter")

# Setup dummy controllers
module Admin; end

('A'..'Z').each do |l|
  Object.const_set("#{l}Controller", Class.new)
  Admin.const_set("#{l}Controller", Class.new)
end

class MockRequest
  attr_reader :path, :request_method
  attr_accessor :path_parameters

  def initialize(request_method, path)
    @path, @request_method = path, request_method
    @path_parameters = {}
  end
end

small_set = ActionController::Routing::RouteSet.new
# BUG: Need to initialize a dummy named route collection
small_set.named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
small_set.draw do |map|
  map.resources :a, :b, :c, :d, :z
end

large_set = ActionController::Routing::RouteSet.new
# BUG: Need to initialize a dummy named route collection
large_set.named_routes = ActionController::Routing::RouteSet::NamedRouteCollection.new
large_set.draw do |map|
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

best_case_match = MockRequest.new(:get, "/a")
worst_case_match = MockRequest.new(:get, "/z/1/edit.xml")

require 'benchmark'

TIMES = 1000

Benchmark.bmbm do |x|
  x.report("small set (best):")  { TIMES.times { small_set.recognize(best_case_match) } }
  x.report("small set (worst):") { TIMES.times { small_set.recognize(worst_case_match) } }

  x.report("large set (best):")  { TIMES.times { large_set.recognize(best_case_match) } }
  x.report("large set (worst):") { TIMES.times { large_set.recognize(worst_case_match) } }
end
