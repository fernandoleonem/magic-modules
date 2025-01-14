# Copyright 2018 Google Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/yaml_validator'

module Overrides
  # All overrides act as a Hash under-the-hood.
  # This class allows them to get access to
  # Hash functions + lets the YAML parser import them.
  class OverrideResource < Google::YamlValidator
    # This is the list of additional attributes that a provider
    # can add through overrides
    def self.attributes
      []
    end

    attr_accessor(*attributes)

    # Used for testing.
    def initialize(hash = {})
      super()

      hash.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    # All keys in this "hash" are actually instance_variables with
    # the @name notation.
    # We're abstracting away the @name notation and allowing
    # for @name or `name` to be valid.
    def [](key)
      if key.to_s[0] == '@'
        instance_variable_get(key.to_sym)
      else
        instance_variable_get("@#{key}")
      end
    end

    def empty?
      instance_variables.empty?
    end

    # This allows OverrideResource to take advantage of
    # the YAMLValidator's validation without being tied down
    # to it.
    def validate
      instance_variables.each do |var_name|
        var = instance_variable_get(var_name)
        var.validate if var.respond_to?(:validate)
      end
    end
  end

  # A hash of Provider::ResourceOverride objects where the key is the api name
  # for that object.
  #
  # Example usage in a provider.yaml file where you want to extend a resource
  # description:
  #
  # overrides: !ruby/object:Provider::ResourceOverrides
  #   SomeResource: !ruby/object:Provider::MyProvider::ResourceOverride
  #     description: '{{description}} A tool-specific description complement'
  #     parameters:
  #       someParameter: !ruby/object:Provider::MyProvider::PropertyOverride
  #         description: 'foobar' # replaces description
  #     properties:
  #       someProperty: !ruby/object:Provider::MyProvider::PropertyOverride
  #         description: 'foobar' # replaces description
  #       anotherProperty.someNestedProperty:
  #         !ruby/object:Provider::MyProvider::PropertyOverride
  #         description: 'baz'
  #   ...
  class ResourceOverrides < OverrideResource
  end

  # Override to an Api::Resource in api.yaml
  class ResourceOverride < OverrideResource
    def apply(_resource)
      self
    end
  end

  # Override to a Api::Type in api.yaml
  class PropertyOverride < OverrideResource
    def apply(_resource)
      self
    end
  end
end
