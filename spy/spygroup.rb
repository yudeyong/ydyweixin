require "redis"
require "./spydataloader"
require "./Constance"
#require 'singleton'

class Spygroup
    # include Singleton
    DENSITY = 7 #60%密度
    #
    def self.initialize
        r = Redis.new
        r.flushdb
        loadSpyDb(r)

        r
    end
    @@r = self.initialize
    @@count = 0
    # str : 词语数组,如果数组长度2,str[0]人的词,str[1]白痴的词,鬼的内容只有人的词的字数,如果长3,str[2],鬼的描述
    # ownerid : 创建者id
    # human :人的数,包含1个白痴
    # ghost :鬼的数
    def self.getNewGroup(str, ownerid, human, ghost)
        self.releaseLast(ownerid)
        self.createGroup(str, ownerid, human, ghost)
    end
#
    private
    def initialize
        p "deprecated method, instance should be creat by getNewGroup"
    end
#
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
#
    def self.createGroup(str, ownerid, human, ghost)
        if (s = self.getWord(str))==nil
            return nil
        end
        gid = getNewGroupID(ownerid)
        initGroup(gid, ownerid,human,ghost,s )
    end
#
    def self.initGroup(g, ownerid, human,ghost,s )
        gid = g.to_s
        @@r.sadd(Constance::KEY_S_GROUPS, gid)

        total = human+ghost
        @@r.rpush(Constance::KEY_L_USR+ownerid, [gid,(total), Constance::STATUS_[Constance::S_OWN]])

        w = s.split(',')
        @@r.rpush(Constance::KEY_L_G_Q+gid,w)

        l = []
        l[0]=Constance::S_IDT
        (human-1).downto(1){|x|l[x]=Constance::S_HUM}
        (total-1).downto(human){|x|l[x]=Constance::S_GOS}
        Constance::shuffle(l)
#p l
        @@r.rpush(Constance::KEY_L_G_S+gid, l )

        @@r.rpush(Constance::KEY_L_G_U+gid, ownerid )

        @@r[Constance::KEY_GRP_COUNT+gid] = total
    end
#
    def self.releaseLast(id)
    end
#
    def self.getNewGroupID(id)
        i = 10
        d = DENSITY
        while @@count > d do
            i *= 10
            d *= 10
        end
        gid = generateID(id, i)
    end
#
    def self.generateID(id, range)
        i = rand(range)
        while !@@r.sadd(Constance::KEY_S_GROUPS, i) do
            i += 1
        end

        @@count+=1
        #p @@count.to_s + ","+i.to_s + ","+ range.to_s
        i
    end

end

s =["a","b阿","dd"]
10.downto(0){Spygroup.getNewGroup(s, "own1", 3, 2)}

