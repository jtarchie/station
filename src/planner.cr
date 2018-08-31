module Station
  class Planner
    def initialize
      @tasks = [] of Symbol
    end

    def next
      @tasks
    end

    def task(name : Symbol)
      @tasks.push name
    end

    module DSL
      def serial(&block)
        planner = Planner.new
        with planner yield
        planner
      end
    end
  end
end
