require 'yaml'
require 'cfndsl/jsonable'
require 'cfndsl/plurals'
require 'cfndsl/names'

module CfnDsl
  module AWSTypes
    aws_types = YAML.load(File.open("#{File.dirname(__FILE__)}/aws_types.yaml"))
    AWSTypes.const_set('AWS_Types', aws_types)

    # Do a little sanity checking - all of the types referenced in Resources
    # should be represented in Types
    aws_types['Resources'].keys.each do |resource_name|
      resource = aws_types['Resources'][resource_name]
      resource.values.each do |thing|
        thing.values.each do |type|
          if type.is_a?(Array)
            type.each do |inner_type|
              puts "unknown type #{inner_type}" unless aws_types['Types'].key?(inner_type)
            end
          else
            puts "unknown type #{type}" unless aws_types['Types'].key?(type)
          end
        end
      end
    end

    # All of the type values should also be references
    aws_types['Types'].values do |type|
      if type.respond_to?(:values)
        type.values.each do |tv|
          puts "unknown type #{tv}" unless aws_types['Types'].key?(tv)
        end
      end
    end

    # declare classes for all of the types with named methods for setting the values
    class AWSType < JSONable
    end

    classes = {}

    # Go through and declare all of the types first
    aws_types['Types'].each_key do |typename|
      if !AWSTypes.const_defined?(typename)
        klass = AWSTypes.const_set(typename, Class.new(AWSType))
        classes[typename] = klass
      else
        classes[typename] = AWSTypes.const_get(typename)
      end
    end

    # Now go through them again and define attribute setter methods
    classes.each_pair do |typename, type|
      typeval = aws_types['Types'][typename]
      next unless typeval.respond_to?(:each_pair)
      typeval.each_pair do |attr_name, attr_type|
        if attr_type.is_a?(Array)
          klass = CfnDsl::AWSTypes.const_get(attr_type[0])
          variable = "@#{attr_name}".to_sym

          method = CfnDsl::Plurals.singularize(attr_name)
          methods = attr_name
          all_methods = CfnDsl.method_names(method) + CfnDsl.method_names(methods)
          type.class_eval do
            all_methods.each do |method_name|
              define_method(method_name) do |value = nil, *rest, &block|
                existing = instance_variable_get(variable)
                # For no-op invocations, get out now
                return existing if value.nil? && rest.empty? && !block

                # We are going to modify the value in some
                # way, make sure that we have an array to mess
                # with if we start with nothing
                existing = instance_variable_set(variable, []) unless existing

                # special case for just a block, no args
                if value.nil? && rest.empty? && block
                  val = klass.new
                  existing.push val
                  value.instance_eval(&block(val))
                  return existing
                end

                # Glue all of our parameters together into
                # a giant array - flattening one level deep, if needed
                array_params = []
                if value.is_a?(Array)
                  value.each { |x| array_params.push x }
                else
                  array_params.push value
                end
                unless rest.empty?
                  rest.each do |v|
                    if v.is_a?(Array)
                      array_params += rest
                    else
                      array_params.push v
                    end
                  end
                end

                # Here, if we were given multiple arguments either
                # as method [a,b,c], method(a,b,c), or even
                # method( a, [b], c) we end up with
                # array_params = [a,b,c]
                #
                # array_params will have at least one item
                # unless the user did something like pass in
                # a bunch of empty arrays.
                if block
                  array_params.each do |val|
                    value = klass.new
                    existing.push value
                    value.instance_eval(&block(val)) if block
                  end
                else
                  # List of parameters with no block -
                  # hope that the user knows what he is
                  # doing and stuff them into our existing
                  # array
                  array_params.each do |val|
                    existing.push value
                  end
                end
                return existing
              end
            end
          end
        else
          klass = CfnDsl::AWSTypes.const_get(attr_type)
          variable = "@#{attr_name}".to_sym

          type.class_eval do
            CfnDsl.method_names(attr_name) do |inner_method|
              define_method(inner_method) do |value = nil, *_rest, &block|
                value ||= klass.new
                instance_variable_set(variable, value)
                value.instance_eval(&block) if block
                value
              end
            end
          end
        end
      end
    end
  end

  module OSTypes
    os_types = YAML.load(File.open("#{File.dirname(__FILE__)}/os_types.yaml"))
    OSTypes.const_set('OS_Types', os_types)

    # Do a little sanity checking - all of the types referenced in Resources
    # should be represented in Types
    os_types['Resources'].keys.each do |resource_name|
      resource = os_types['Resources'][resource_name]
      resource.values.each do |thing|
        thing.values.each do |type|
          if type.is_a?(Array)
            type.each do |inner_type|
              puts "unknown type #{inner_type}" unless os_types['Types'].key?(inner_type)
            end
          else
            puts "unknown type #{type}" unless os_types['Types'].key?(type)
          end
        end
      end
    end

    # All of the type values should also be references

    os_types['Types'].values do |type|
      if type.respond_to?(:values)
        type.values.each do |tv|
          puts "unknown type #{tv}" unless os_types['Types'].key?(tv)
        end
      end
    end

    # declare classes for all of the types with named methods for setting the values
    class OSType < JSONable
    end

    classes = {}

    # Go through and declare all of the types first
    os_types['Types'].each_key do |typename|
      if !OSTypes.const_defined?(typename)
        klass = OSTypes.const_set(typename, Class.new(OSType))
        classes[typename] = klass
      else
        classes[typename] = OSTypes.const_get(typename)
      end
    end

    # Now go through them again and define attribute setter methods
    classes.each_pair do |typename, type|
      typeval = os_types['Types'][typename]
      next unless typeval.respond_to?(:each_pair)
      typeval.each_pair do |attr_name, attr_type|
        if attr_type.is_a?(Array)
          klass = CfnDsl::OSTypes.const_get(attr_type[0])
          variable = "@#{attr_name}".to_sym

          method = CfnDsl::Plurals.singularize(attr_name)
          methods = attr_name
          all_methods = CfnDsl.method_names(method) + CfnDsl.method_names(methods)
          type.class_eval do
            all_methods.each do |method_name|
              define_method(method_name) do |value = nil, *rest, &block|
                existing = instance_variable_get(variable)
                # For no-op invocations, get out now
                return existing if value.nil? && rest.empty? && !block

                # We are going to modify the value in some
                # way, make sure that we have an array to mess
                # with if we start with nothing
                existing = instance_variable_set(variable, []) unless existing

                # special case for just a block, no args
                if value.nil? && rest.empty? && block
                  val = klass.new
                  existing.push val
                  value.instance_eval(&block(val))
                  return existin
                end

                # Glue all of our parameters together into
                # a giant array - flattening one level deep, if needed
                array_params = []
                if value.is_a?(Array)
                  value.each { |x| array_params.push x }
                else
                  array_params.push value
                end
                unless rest.empty?
                  rest.each do |v|
                    if v.is_a?(Array)
                      array_params += rest
                    else
                      array_params.push v
                    end
                  end
                end

                # Here, if we were given multiple arguments either
                # as method [a,b,c], method(a,b,c), or even
                # method( a, [b], c) we end up with
                # array_params = [a,b,c]
                #
                # array_params will have at least one item
                # unless the user did something like pass in
                # a bunch of empty arrays.
                if block
                  array_params.each do |val|
                    value = klass.new
                    existing.push value
                    value.instance_eval(&block(val)) if block
                  end
                else
                  # List of parameters with no block -
                  # hope that the user knows what he is
                  # doing and stuff them into our existing
                  # array
                  array_params.each do |val|
                    existing.push value
                  end
                end
                return existing
              end
            end
          end
        else
          klass = CfnDsl::OSTypes.const_get(attr_type)
          variable = "@#{attr_name}".to_sym

          type.class_eval do
            CfnDsl.method_names(attr_name) do |inner_method|
              define_method(inner_method) do |value = nil, *_rest, &block|
                value ||= klass.new
                instance_variable_set(variable, value)
                value.instance_eval(&block) if block
                value
              end
            end
          end
        end
      end
    end
  end
end