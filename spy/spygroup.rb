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
        #loadSpyDb(r)

        r
    end
    @@r = self.initialize
    @@count = 0
    # str : 词语数组,如果数组长度2,str[0]人的词,str[1]白痴的词,鬼的内容只有人的词的字数,如果长3,str[2],鬼的描述
    # ownerid : 创建者id
    # human :人的数,包含1个白痴
    # ghost :鬼的数
    def self.getNewGroup(str, ownerid, human, ghost)
        self.releaseGroupbyUsr(ownerid)
        self.releaseExpiration(Constance::CHECK_EXPIRATION_COUNT)#每新局,检查部分过期数据并释放
        self.createGroup(str, ownerid, human, ghost)
    end
#count, check count, -1 for all
    def self.releaseExpiration(count)
        t = Time.now.to_i
        g = @@r.zrevrange( Constance::KEY_Z_GROUPS,0,count-1)
        g.each{|x|releaseGroupbyGid(x)if @@r.zscore(Constance::KEY_Z_GROUPS,x)<t }
    end
#
    def self.addUsr(gid,uid)
#print "add g#{gid},#{uid}\n"
        return "不存在的局id" if (t=@@r.zscore(Constance::KEY_Z_GROUPS, gid))==nil
        gid = gid.to_s #implicit type as string
        if ((usr =@@r.lrange(Constance::KEY_L_USR+uid,0,-1))!=nil && usr.length>0)#用户已经在了
            if usr [0]==gid
                return usr[1] #是当前局用户
            else
                releaseGroupbyUsr(uid)#用户所在游戏局已过期
            end
        end
        return "已满" if (@@r[Constance::KEY_GRP_COUNT+gid].to_i<=0)
        if ((s=@@r.lindex(Constance::KEY_L_USR + gid, 1).to_s)==nil || s.length==0)
            #p @@r.lindex(Constance::KEY_L_USR+uid,1)
            @@r.rpush(Constance::KEY_L_USR+uid,gid)#增加用户, 必须立即增加用户key,防快速请求重复加入
            @@r.decr(Constance::KEY_GRP_COUNT+gid)#减等待人数
            ord = @@r.rpush(Constance::KEY_L_G_U+gid, uid )-2# 组增加用户
            #p "1.s=#{s}; ord=#{ord}"
            ord = @@r.lindex(Constance::KEY_L_G_S+gid,ord)#获取身份
            #p "2.s=#{s}; ord=#{ord}"
            s   = @@r.lindex(Constance::KEY_L_G_Q+gid,ord)#获取提示
            #p "3.s=#{s}; ord=#{ord}"
            s = ("鬼:"+s ) if ord==Constance::S_GOS
            @@r.rpush(Constance::KEY_L_USR+uid,[s,ord])#完善用户数据
            
            #update expiration time
            l = Time.now.to_i - t + Constance::EXPIRE_TERM
            @@r.zincrby(Constance::KEY_Z_GROUPS, l, gid )
        end
        s
    end
##########################
    private
    def initialize
        p "deprecated method, instance should be creat by getNewGroup"
    end
#获取问题词组
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
#创建组相关数据,词组内容
#返回组id
    def self.createGroup(str, ownerid, human, ghost)
        if (s = self.getWord(str))==nil
            return nil
        end
        gid = getNewGroupID(ownerid)
        initGroup(gid, ownerid,human,ghost,s )
        gid
    end
#创建redis中组相应的数据
    def self.initGroup(g, ownerid, human,ghost,s )
        gid = g.to_s

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
DBG_RELEASE = false
#
    def self.releaseGroupbyGid(gid)
p "release #{gid}"
if DBG_RELEASE
    p @@r.keys("U*"),@@r.zrange("GROUP",0,-1)
    p @@r.keys("G*"),@@count.to_s+";"+gid.to_s
end
    usrs = @@r.lrange(Constance::KEY_L_G_U+gid,0,-1)
    @@r.del(Constance::KEY_L_G_Q+gid)
    @@r.del(Constance::KEY_L_G_S+gid)
    @@r.del(Constance::KEY_GRP_COUNT+gid)
    usrs.each{|x|@@r.del(Constance::KEY_L_USR+x)}
    @@r.del(Constance::KEY_L_G_U+gid)
    @@count -= 1 if (@@r.zrem(Constance::KEY_Z_GROUPS, gid))
if DBG_RELEASE
    p @@r.keys("U*"),@@r.zrange("GROUP",0,-1)
    p @@r.keys("G*"),@@count.to_s+";"+gid.to_s
end
    end
#释放
    def self.releaseGroupbyUsr(ownerid)
        uinfo = @@r.lrange(Constance::KEY_L_USR + ownerid, 0, -1)
#p uinfo
        return nil if uinfo==nil || uinfo.length==0
        releaseGroupbyGid( uinfo[0] )
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
        gid = rand(range)
        t = Time.now.to_i + Constance::EXPIRE_TERM
        while !@@r.zadd(Constance::KEY_Z_GROUPS, t, gid ) do
            gid += 1
        end

        @@count+=1
        #p @@count.to_s + ","+i.to_s + ","+ range.to_s
        gid
    end

end

############
#debug area
=begin
=end
DEBUG_COUNT = 1
def dbg_group(human,ghost)
    s =["aren","b白","dd鬼"]
    s1 = []
    i = rand(100).to_s
    (s.length-1).downto(0) {|x| s1[x] = s[x]+i}
    gid = Spygroup.getNewGroup(s1, "own"+rand(DEBUG_COUNT+1).to_s, human, ghost)
    (human+ghost+1).downto(1){|x| p "##"+Spygroup.addUsr(gid,"u"+x.to_s+gid.to_s).to_s}
end
DEBUG_COUNT.downto(0){|x|dbg_group(3+x,1+(x/5+1));p '*'*10}
#Spygroup::releaseExpiration(1)
=begin
=end
