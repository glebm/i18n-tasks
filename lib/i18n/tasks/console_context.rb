module I18n::Tasks
  class ConsoleContext < BaseTask
    def to_s
      @to_s ||= "i18n-tasks-#{I18n::Tasks::VERSION}"
    end

    def banner
      puts Messages.banner
    end

    def guide
      puts Messages.guide
    end

    class << self
      def start
        require 'irb'
        IRB.setup nil
        ctx = IRB::Irb.new.context
        IRB.conf[:MAIN_CONTEXT] = ctx
        STDERR.puts Messages.banner
        require 'irb/ext/multi-irb'
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
        green(bold "i18n-tasks IRB Quick Start guide") + "\n" + <<-TEXT
#{yellow 'Data as trees'}
  tree(locale)
  missing_tree(locale, compared_to = base_locale)
  used_tree(source_locations: false, key_filter: nil)
  unused_tree(locale)
  build_tree('es' => {'hello' => 'Hola'})

#{yellow 'Traversal'}
  tree = missing_tree(base_locale)
  tree.nodes { |node| }
  tree.nodes.to_a
  tree.leaves { |node| }
  tree.each { |root_node| }
  # also levels, depth_first, and breadth_first

#{yellow 'Select nodes'}
  tree.select_nodes { |node| } # new tree with only selected nodes

#{yellow 'Match by full key'}
  tree.select_keys { |key, leaf| } # new tree with only selected keys
  tree.grep_keys(/hello/)          # grep, using ===
  tree.keys { |key, leaf| }        # enumerate over [full_key, leaf_node]
  # Pass {root: true} to include root node in full_key (usually locale)

#{yellow 'Nodes'}
  node = node(key, locale)
  node.key      # only the part after the last dot
  node.full_key # full key. Includes root key, pass {root: false} to override.
  # also: value, value_or_children_hash, data, walk_to_root, walk_from_root
  Tree::Node.new(key: 'en')

#{yellow 'Keys'}
  t(key, locale)
  key_value?(key, locale)
  depluralize_key(key, locale) # convert 'hat.one' to 'hat'
  absolutize_key(key, path)    # '.title' to 'users.index.title'
        TEXT
      end
    end
  end
end
