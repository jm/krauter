module ActionController
  module Routing
    class RouteSet
      attr_accessor :routes, :recognizers

      def initialize
        @routes = []
        @route_structure = {}
      end
    
      def add_named_route(name, path, options = {})
        # TODO: Setup named routes hash so we can Merb-style url() calls
        add_route(path, options)
      end

      def add_route(route_string, *args)
        # TODO: blah* parameters
        @route_structure ||= {}
        @routes ||= []
        params = []
        args = (args.pop || {})
        
        # Set the request method; default to GET
        request_method = args[:conditions] && args[:conditions][:method] ? args[:conditions].delete(:method) : :get
      
        # Grab the requirements from the :requirements param or from any arg that's a regex
        requirements = args.delete(:requirements) || {}
        args.each do |k, v|
          requirements[k.to_sym] = args[k] if v.is_a?(Regexp)
        end

        # Create segment collection for local analysis of a route (i.e., parameter interpolation)
        local_segments = []
        
        # Split the route string into segments
        segments = route_string.split("/").map! do |segment|
          next if segment.blank?
          
          # Escape the segments so we can push them to a regex later on
          segment = local_segment = Regexp.escape(segment)
        
          # If there's a dynamic symbol...
          if segment =~ /:\w+/
            # Grab all the symbols
            segment_symbols = segment.scan(/:(\w+)/).flatten
          
            segment_symbols.each do |segment_symbol|
              # Make a note of the parameter name
              params << segment_symbol.to_sym
              
              # This regex will be used to interpolate the parameters; the captures are finer grained
              local_segment = segment.gsub(/:#{segment_symbol}/, "((#{requirements[segment_symbol.to_sym] || '.*'}))")
              # This regex will be used to match the route to a path
              segment.gsub!(/:#{segment_symbol}/, "#{requirements[segment_symbol.to_sym] || '.*'}")
            end
          elsif segment =~ /^\*w+/
            # Route globbing
            params << segment.to_sym
            local_segment = segment.gsub(/:#{segment_symbol}/, "((#{requirements[segment_symbol.to_sym] || '.*'}))")
            segment.gsub!(/:#{segment_symbol}/, "#{requirements[segment_symbol.to_sym] || '.*'}")
          end
        
          local_segments << local_segment
          segment
        end.compact
        
        raise "Invalid route: Controller not specified" unless (params.include?(:controller) || args.keys.include?(:controller))

        # Create the Route instance and add it to the route collection
        new_route = MyRoute.new(segments, local_segments, params, request_method, args)
        @routes << new_route

        new_route.arguments[:controller] ||= :controller
        new_route.arguments[:action] ||= :action

        # Create a tree structure for route generation
        @route_structure[request_method] ||= {}
        @route_structure[request_method][new_route.arguments[:controller]] ||= {}
        @route_structure[request_method][new_route.arguments[:controller]][new_route.arguments[:action]] ||= [] 
        @route_structure[request_method][new_route.arguments[:controller]][new_route.arguments[:action]] << new_route
        
        new_route
      end

      def recognize(request)
        # Normalize path
        path = (request.path.slice(0,1) == "/" ? request.path : "/#{request.path}")

        # Default to GET for request method
        request_method = (request.request_method || :get)

        target = "#{request_method} #{path}"

        matched = {}
        route = matches = captures = nil
        routeset = []
        
        # Populate recognizer sets
        @recognizers ||= build_recognizers

        # Iterate each set of recognizers
        @recognizers.each do |recognizer, routes|
          # Match path to recognizer
          if target =~ recognizer
            matches = Regexp.last_match
            # Grab set of routes + matched path
            if capture = matches.captures.compact.first
              route = routes[matches.captures.index(capture)]
              break
            end
          end
        end

        raise "No route matches that path" unless route

        # Match indexes of matched path and route
        # Get parameter values
        params = route.params.clone
        param_matches = path.scan(/#{route.local_recognizer}/).flatten

        param_list = {}
        route.params.each_with_index {|p,i| param_list[p] = param_matches[i]}
        matched = route.arguments.merge(matched).merge(param_list)

        # Default action to index
        matched[:action] = 'index' if matched[:action] == :action

        # Populate request's parameters with arguments from request + static values
        request.path_parameters = matched
        
        # We cache the controller now, but if it's not defined (e.g., it's a param)
        # we need to generate it
        if route.controller
          route.controller
        else
          "#{matched[:controller].camelize}Controller".constantize
        end
      end
      
      # TODO: I forgot what epic_fail does.  Look that up.
      def generate(params, recall = {}, epic_fail = nil)
        # Default request method to GET
        request_method = params[:method] ? params[:method].to_sym : :get

        # If we're given a controller...
        if params.keys.include?(:controller)
          # Grab controller routes
          controller_routes = @route_structure[request_method][params[:controller]]

          unless controller_routes 
            controller_routes = @route_structure[request_method][:controller]
          end

          # ...then map action
          action_routes = controller_routes[(params[:action] || 'index')] || controller_routes[:action]

          # Find route we're looking for with the right params
          action_routes.each do |route|
            if (route.params - params.keys).empty?
              return generate_url(route, params)
            else
              raise "No route to match that"
            end
          end
        else
          raise "No controller provided"
        end
      end

      def generate_url(route, params)
        route_string = route.segments.join("/")
        return route_string unless route_string.include?("(.*)")

        index = -1
        route_string.gsub!(/\(\.\*\)/) do |match|
          index += 1 
          params[route.params[index]].to_param
        end
      end

      def build_recognizers
        recognizers = []
        current_route_set = []
        current_segment = ""
        
        @routes.each do |route|
          route.controller = route.controller.constantize if route.controller
          
          segment = "(^#{route.request_method} #{route.recognizer}$)"
          
          # If our recognizer is getting too big, break it up and start a new one
          # At most, 65417 characters or 253 captures.  
          # TODO: Make these constants that vary depending on Ruby version; 1.9 probably doesn't have these constraints?
          if (("#{current_segment}|#{segment}").length > 65417) || current_route_set.length >= 253
            recognizers << [/#{current_segment}/, current_route_set]
            current_segment = segment
            current_route_set = [route]
          else
            # ...otherwise keep adding to the current recognizer
            current_segment = [current_segment, segment].reject{|s| s.blank?}.compact.join("|")
            current_route_set << route
          end
        end
        
        # Clean up any left over segments and routes
        unless current_segment.blank?
          recognizers << [/#{current_segment}/, current_route_set]
        end
        
        @recognizers = recognizers
      end
    end

    class MyRoute
      # TODO: Add dynamic attribute so we can skip parameter interpolation if there aren't any
      attr_accessor :params, :segments, :arguments, :controller
      attr_reader :recognizer, :request_method, :local_recognizer

      def initialize(segment_list, local_segments, param_list, request_method, argument_list = {})
        @segments = segment_list
        @params = param_list
        @arguments = argument_list || {}
        @recognizer = "/#{@segments.join("\/")}"
        @local_recognizer = "/#{local_segments.join("\/")}"
        @request_method = request_method
        
        # If we have the controller, cache it!!
        if argument_list[:controller]
          @controller = "#{argument_list.delete(:controller).camelize}Controller"
        end
      end
    end
  end
end