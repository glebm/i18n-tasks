module I18n::Tasks::FileStructure
  def identify(routes = data.config.read)

  end


  class NonLeafVisitor
    def visit(node)
      puts "non-leaf: #{node}"
    end
  end

  class LeafVisitor
    def visit(node)
      puts "leaf: #{node}"
    end
  end
end
