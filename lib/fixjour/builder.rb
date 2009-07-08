module Fixjour
  class Builder
    attr_reader :klass

    def initialize(klass, options={})
      @klass, @options = klass, options
    end

    def name
      @name ||= (@options[:as] || @klass.table_name.singularize).to_s
    end

    def eql?(other)
      @klass == other.klass
    end

    def hash
      @klass.hash
    end
  end
end
