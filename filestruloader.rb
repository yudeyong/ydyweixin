require 'csv'
require "../source/keynode.rb"


class FilestruLoader
    def initialize( name = "mp3 list")
        @root = KeyTreeNode.new("ROOT", name)
        
    end
    def load

        #root << KeyTreeNode.new("c", "mp3 list")
        #st = Stack.new()
        l=0

        CSV.foreach('../source/mp3.csv','r') do |row|
            #    i = 0;    row.each {|x|i+=1;p x }
            i = 0
            node = root
            l+=1
            if row!=nil
                # p row.inspect
                row.each{|x|
                #st.push(node)
                i += 1
                #        p "x=#{x};" + (node[x]==nil).to_s
                if (node[x]==nil)
                    #node = KeyTreeNode.new(x, st.count)
                    n = KeyTreeNode.new(x, i )
                    begin
                    node << n
                    rescue
                    #           p "name:#{n.name},x=#{x}"
                    end
                    node = n;
                else
                    node = node[x]
                end
                }
            end
        end
        root[0].listcurrent
        #root.print_tree
    end

    def get(order)
        order.bytes.each{|x|
            p x
        }
    end
end

FilestruLoader.new.get("dsfdf")
