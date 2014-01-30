require 'tree'                 # Load the library

class KeyTreeNode < Tree::TreeNode
    attr_accessor :no
    
    def initialize( name,content=nil )
        @number = '0'.ord
        @no = ' '.ord
        super
    end
    
    def <<(child)
        add(child)
    end

    def add(child, at_index=-1)
        if child.instance_variable_defined?( :@no )
            child.no = @number
            @number += 1
        end
        super(child, at_index)
    end

    def getname
        @no.chr.to_s + "." + @name
    end

    def listcurrent
        children.each{|x|
            s = ((x.is_leaf?) ?"=":"+") + "-"*3 + x.getname
            p s
        }
    end
end

if false

# ..... Create the root node first.  Note that every node has a name and an optional content payload.
root_node = KeyTreeNode.new("ROOT", "Root Content")
#root_node.print_tree

# ..... Now insert the child nodes.  Note that you can "chain" the child insertions for a given path to any depth.
 root_node << KeyTreeNode.new("CHILD1", "Child1 Content") << KeyTreeNode.new("GRANDCHILD1", "GrandChild1 Content")
# root_node << KeyTreeNode.new("CHILD2", "Child2 Content")


# ..... Lets directly access children and grandchildren of the root.  The can be "chained" for a given path to any depth.
child1       = root_node["CHILD1"]
child1 <<  KeyTreeNode.new("GC"+3.to_s,"GC2")
#child1 <<  KeyTreeNode.new("GC"+1.to_s,"GC2")

10.downto(0){|x|
    begin #开始
        child1 <<  KeyTreeNode.new("GC"+x.to_s,"GC2")
rescue  RuntimeError => e
#do nothing
end
}
grand_child1 = root_node["CHILD1"]["GRANDCHILD1"]
#p child1.getname#,grand_child1.Content
child1.each{|x| p x.getname}


# ..... Lets print the representation to stdout.  This is primarily used for debugging purposes.
#root_node.print_tree

# ..... Now lets retrieve siblings of the current node as an array.
siblings_of_child1 = child1.siblings

# ..... Lets retrieve immediate children of the root node as an array.
children_of_root = root_node.children

# ..... This is a depth-first and L-to-R pre-ordered traversal.
root_node.each { |node| node.content.reverse }

# ..... Lets remove a child node from the root node.
root_node.remove!(child1)
# ..... Lets print the representation to stdout.  This is primarily used for debugging purposes.
end