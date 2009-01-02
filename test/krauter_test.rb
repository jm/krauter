require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require File.expand_path(File.dirname(__FILE__) + "/../lib/krauter")
require 'context'

class KrauterTest < Test::Unit::TestCase
  context "When adding routes" do
    before do
      @router = ActionController::Routing::RouteSet.new
    end
    
    it "should add a route" do
      @router.add_route("/hello", :controller => "my_controller", :action => "index")
      assert @router.routes.length == 1
      assert @router.routes.first.is_a?(ActionController::Routing::MyRoute)
    end
    
    it "should maintain a route set" do
      5.times do |i|
        @router.add_route("/hello#{i}", :controller => "my_controller", :action => "index")
      end
      
      assert @router.routes.length == 5
    end
    
    it "should set the controller" do
      @router.add_route("/hello", :controller => "my_controller", :action => "do_it")
      assert @router.routes.first.arguments[:controller] == "my_controller"
    end
    
    it "should set the action" do
      @router.add_route("/hello", :controller => "my_controller", :action => "do_it")
      assert @router.routes.first.arguments[:action] == "do_it"
    end
    
    context "with parameters" do
      it "should add the wildcard parameter" do
        @router.add_route("/hello/:person", :controller => "my_controller", :action => "do_it")
        assert @router.routes.first.params.first == :person
      end
      
      it "should add the wildcard parameter for multiple parameters" do
        @router.add_route("/hello/:person/:dude/:man", :controller => "my_controller", :action => "do_it")
        assert @router.routes.first.params == [:person, :dude, :man]
      end
      
      it "should allow static values for parameters" do
        @router.add_route("/hello/owner", :controller => "my_controller", :action => "do_it", :person => 'David')
        assert @router.routes.first.arguments[:person] == 'David'
      end
      
      it "should allow requirements" do
        @router.add_route("/hello/:person", :controller => "my_controller", :action => "do_it", :requirements => {:person => /[A-Za-z]/})
        assert @router.routes.first.recognizer == "/hello/#{/[A-Za-z]/}"
      end
      
      context "and building the recognizers" do
        it "should build a recognizer from the route set" do
          @router.add_route("/hello", :controller => "my_controller", :action => "do_it")
          
          @router.build_recognizers

          # hrm comparison of regex didn't work here.  bug?
          assert_equal /(^get \/hello$)/.to_s, @router.recognizers.first[0].to_s
        end
        
        it "should add a local recognizer to each route" do
          @router.add_route("/hello", :controller => "my_controller", :action => "do_it")
          
          assert_equal "/hello", @router.routes.first.local_recognizer
        end
        
        it "should add a local recognizer to each route that has finer grained captures" do
          @router.add_route("/hello/:id", :controller => "my_controller", :action => "do_it")
          
          assert_equal "/hello\/((.*))", @router.routes.first.local_recognizer
        end
        
        context "should build multiple recognizers if the size gets close to the boundary" do
          test "of captures" do
            
          end
          
          test "of characters" do
            
          end
        end
      end
    end
    
    context "allow wildcards for" do
      test "controller name" do
        @router.add_route("/:controller/hello", :action => "hello")
        assert @router.routes.first.arguments[:controller] == :controller
      end
      
      test "action" do
        @router.add_route("/hello/:action", :controller => "my_controller")
        assert @router.routes.first.arguments[:action] == :action
      end
    end
  end
  
  context "When generating" do
    it "should generate from a given Route instance" do
    end
    
    context "for normal routes" do
      it "should generate a URL" do
      end
    end
    
    context "for routes with wildcards" do
      it "should interpolate the parameter values properly" do
      end
      
      it "should generate a URL with one param" do
      end
      
      it "should generate a URL with multiple params" do
      end
    end
    
    context "for routes with requirements" do
      it "should require the param meet the requirements" do
      end
      
      it "should generate a URL" do
      end
    end
  end
  
  context "When recognizing" do
    def test_truth
      assert "KRAUTER IS TRUTH."
    end
  end
  
  context "The Route class" do
    # TODO: Test all our attributes / transformations
  end
end
