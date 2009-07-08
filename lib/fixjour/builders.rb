module Fixjour
  def counter(key=nil)
    Counter.counter(key)
  end

  class << self
    include Definitions

    attr_accessor :allow_redundancy

    # The list of classes that have builders defined.
    def builders
      @builders ||= Set.new
    end

    # This method should always return a valid instance of
    # a model object.
    def define_builder(klass, options={}, &block)
      builder = Builder.new(klass, :as => options.delete(:as))
      add_builder(builder)

      if block_given?
        define_new(builder, &block)
      else
        define_new(builder) do |proxy, overrides|
          proxy.new(options.merge(overrides))
        end
      end

      define_create(builder)
      define_valid_attributes(builder)
    end

    # Adds builders to Fixjour.
    def evaluate(&block)
      begin
        module_eval(&block)
      rescue NameError => e
        if e.name && evaluator.respond_to?(e.name)
          raise NonBlockBuilderReference.new("You must use a builder block in order to reference other Fixjour creation methods.")
        else
          raise e
        end
      end
    end

    # Checks to see whether or not a builder is defined. Duh.
    def builder_defined?(builder)
      case builder
      when Class  then builders.map(&:klass).include?(builders)
      when String then builders.map(&:name).include?(builder)
      when Symbol then builders.map(&:name).include?(builder.to_s)
      end
    end

    def remove(builder)
      builders.delete(Builder.new(builder))
    end

    private

    # Registers a class' builder. This allows us to make sure
    # redundant builders aren't defined, which can lead to confusion
    # when trying to figure out where objects are being created.
    def add_builder(builder)
      unless builders.add?(builder) or Fixjour.allow_redundancy
        raise RedundantBuilder.new("You already defined a builder for #{builder.klass.inspect}")
      end
    end

    # Anonymous class used for reflecting on current Fixjour state.
    def evaluator
      @evaluator ||= begin
        klass = Class.new
        klass.send :include, self
        klass.new
      end
    end
  end
end
