module I18n::Tasks
  class IrbContext < BaseTask
    def banner
      puts Messages.banner
    end

    def guide
      puts Messages.guide
    end

    class << self
      def irb
        require 'irb'
        IRB.setup nil
        ctx = IRB::Irb.new.context
        ctx.main.singleton_class.send(:remove_method, :help)
        IRB.conf[:MAIN_CONTEXT] = ctx
        require 'irb/ext/multi-irb'
        STDERR.puts Messages.banner
        IRB.irb nil, new
      end
    end

    module Messages
      include Term::ANSIColor
      extend self

      def banner
        bold("i18n-tasks v#{I18n::Tasks::VERSION} IRB") + "\nType #{green 'guide'} to learn more"
      end

      def guide
        green(bold "i18n-tasks IRB Quick Start guide") + "\n" + <<-TEXT + "\n"

  #{yellow 'Data and analysis results are available as trees.'}

    data[base_locale]
    missing_tree(locale, compared_to = base_locale)
    used_tree(source_locations: false, key_filter: nil)
    unused_tree(locale)

  #{yellow 'Trees can be traversed and transformed. Root node key is always either a locale or a tree type.'}

    tree = missing_tree(base_locale)
    tree.nodes { |node| ... }
    tree.leaves { |node| ... }
    tree.levels { |nodes| ... }
    tree.walk_depth_first { |node| puts node.full_key }
    tree.walk_breadth_first { |node| puts node.full_key }
    tree.select_nodes { |node| true if node.children > 5 }
    tree.to_json

  #{yellow 'Some operations also exclude root from key name by default. Pass root: true to override.'}

    tree.keys { |full_key, node| ... }
    tree.select_keys { |full_key| true if full_key.length > 10 }
    tree.grep_keys(/hello/)

  #{yellow 'Nodes support all of the traversal operations above, and more.'}

    node = missing_tree(base_locale).nodes.first
    node.key
    node.full_key(root: false) # default root: true
    node.value
    node.data

  #{yellow 'Working with keys directly.'}

    t(key, locale)
    key_value?(key, locale)
    depluralize_key(key, locale)
    absolutize_key(relative_key, path)
        TEXT
      end
    end
  end
end
