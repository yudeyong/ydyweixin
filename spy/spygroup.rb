require "redis"
require "./spydataloader"
require "./Constance"
#require 'singleton'

class Spygroup
    # include Singleton
    
    def self.initialize
        r = Redis.new
        loadSpyDb(r)
        
        r
    end
    @@r = self.initialize

    # str : 词语数组,如果数组长度2,str[0]人的词,str[1]白痴的词,鬼的内容只有人的词的字数,如果长3,str[2],鬼的描述
    # ownerid : 创建者id
    # human :人的数,包含1个白痴
    # ghost :鬼的数
    def self.getNewGroup(str, ownerid, human, ghost)
        self.releaseLast(ownerid)
        self.createGroup(str, ownerid, human, ghost)
    end

    private
    def initialize
        p "deprecated method, instance should be creat by getNewGroup"
    end

    def self.getWord(str)
        if str==nil
            return @@r[Constance::KEY_QUES+rand(@@r[Constance::KEY_QUES_COUNT].to_i).to_s]
        end
        case ( str.length )
            when 2
                makewords(str)
            when 3
                str[0]+","+str[1]+","+str[2]
            else
                nil
        end
    end
    def self.createGroup(str, ownerid, human, ghost)
        if (s = self.getWord(str))==nil
            return nil
        end
        id = getNewGroupID(ownerid)
p s
    end
    def self.releaseLast(id)
    end
    def self.getNewGroupID(id)
        
    end
end

s =["a","b","dd"]
Spygroup.getNewGroup(s, 1, 1, 1)

