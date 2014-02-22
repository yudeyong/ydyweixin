require "redis"
require File.dirname(__FILE__) +"/spydataloader"
require File.dirname(__FILE__) +"/Constance"
#require 'singleton'

#spy game core logic
# all public function is static
# all data saved into redis
# more data structure reference Constance.rb
class Spygroup
    # include Singleton
    DENSITY = 6 #60%密度 数据密度共10成
    #静态初始化redis
    #载入题库
    def self.initialize
        r = Redis.new
        #r.flushdb
        loadSpyDb(r)

        r
    end
    @@r = self.initialize
    @@count = 0 #当前游戏数量
    # str : 词语数组,如果数组长度2,str[0]人的词,str[1]白痴的词,鬼的内容只有人的词的字数,
    #	如果长3,str[2]=>鬼的描述.
    #	如果长0,题库中随机获取
    # ownerid : 创建者id，此人不任游戏角色，裁判
    # human :人的数,包含n个白痴，n=详见initGroup
    # spy :鬼的数
    def self.getNewGroup( ownerid, human, spy, str=[], isKiller=false)
        self.releaseGroupbyUsr(ownerid)
        self.releaseExpiration(Constance::CHECK_EXPIRATION_COUNT)#每新局,检查部分过期数据并释放
        self.createGroup(str, ownerid, human, spy, isKiller)
    end
	#release expired group
	#count: check count, 0 for all
	#	expiration time reference Constance::EXPIRE_TERM
    def self.releaseExpiration(count)
t = Time.now.to_i() *0#for debug
        g = @@r.zrevrange( Constance::KEY_Z_GROUPS,0,count-1)
        g.each{|x|releaseGroupbyGid(x)if @@r.zscore(Constance::KEY_Z_GROUPS,x)<t }
    end
    
	#it's clear, no more comments
    def self.addUsr(gid,uid)
#print "add g#{gid},#{uid} "
#p File.basename(caller[1])
        return "不存在的局id" if (t=@@r.zscore(Constance::KEY_Z_GROUPS, gid))==nil
        gid = gid.to_s #implicit type as string
        if ((usr =@@r.lrange(Constance::KEY_L_USR+uid,0,-1))!=nil && usr.length>0)#用户已经在了
        #p  usr
            if usr [0]==gid	
                 return usr[1] + self.getText( @@r[Constance::KEY_GRP_COUNT+gid].to_i ,usr[3],false)#是当前局用户
            else
                releaseGroupbyUsr(uid)#用户所在游戏局已过期
            end
        end
        #p @@r.lrange(Constance::KEY_L_USR+uid,0,-1)
        return "已满" if (@@r[Constance::KEY_GRP_COUNT+gid].to_i<=0)
        if ((s=@@r.lindex(Constance::KEY_L_USR + gid, 1).to_s)==nil || s.length==0)
            
            @@r.rpush(Constance::KEY_L_USR+uid,gid)#增加用户, 必须立即增加用户key,防快速请求重复加入
            c = @@r.decr(Constance::KEY_GRP_COUNT+gid)#减等待人数
            no = @@r.rpush(Constance::KEY_L_G_U+gid, uid )-2# 组增加用户
            #p "1.s=#{s}; ord=#{ord}"
            ord = @@r.lindex(Constance::KEY_L_G_S+gid,no)#获取身份
            no += 1 #用户编号从1开始
            #p "2.s=#{s}; ord=#{ord}"
            s   = @@r.lindex(Constance::KEY_L_G_Q+gid,ord)#获取提示
            #p "3.s=#{s}; ord=#{ord}"
            s = ("卧底:"+s ) if ord==Constance::S_SPY
            @@r.rpush(Constance::KEY_L_USR+uid,[s,ord,no])#完善用户数据
            
            #update expiration time
            l = Time.now.to_i - t + Constance::EXPIRE_TERM
            @@r.zincrby(Constance::KEY_Z_GROUPS, l, gid ).to_s 
            s += self.getText(c,no,true)
        end
        s
    end

    def self.getResult(gid,result)
        a = Array.new(result.length+1,0)
        max = 1
        #统计得票,并得到最大值
        result.each do |x|
            if (x=x.to_i)>0
                a[x]+=1
                max = a[x] if max<a[x]
            end
        end
        
        round=-1
        count=0
        (result.length-1).downto(0) do |x|
            if a[x+1]<max
                result[x]= VOTE_INIT_S if result[x].to_i>0#(result[x].to_i>0 ? -1 : (round=result[x].to_i - 1))
                else
                result[x]=max
                count += 1
            end
            @@r.lset(Constance::KEY_L_G_VT+gid,x,result[x])
        end
        count
    end
VOTE_INIT_S = 0 #投票者初始状态
VOTE_BLOCK = -1 #暂时不能被投票的人,比如某轮有>1个人获得票数相同,需要进一步讨论,其他低票数用户在再投票环节暂时不能被投
VOTE_DEAD = -2 #死者,不能投也不能被投
    #vote
    # v:被投票人编号
    def self.vote(uid, v)
        usr = @@r.lrange(Constance::KEY_L_USR+uid,0,-1)
        return :"不存在你的数据" if ! (gid = usr && usr[0])
p         a = @@r.get(Constance::KEY_VOTE+gid)
        result = @@r.lrange(Constance::KEY_L_G_VT+gid,0,-1)#注意用户编号从1开始
        if (a.to_i()>0)
            return :"参数不正确,请输入1-#{result.length}的数字" if SpyHandler::isI(v) || result.length<(v =v.to_i) || v<=0
            #usr[3].to_i() - 1 ==>No. 投票人编号
            return "此人不能投票" if usr.length<=3
            self.votework(gid,v,result,usr[3].to_i() - 1).to_s + self.getVoteResult(gid,result)
        else
            self.getVoteResult(gid,result)
        end
    end

    def self.killbyno(uid, v )#v - killedno
        usr = @@r.lrange(Constance::KEY_L_USR+uid,0,-1)
        return :"不存在你的数据" if ! (gid = usr && usr[0])
        result = @@r.lrange(Constance::KEY_L_G_VT+gid,0,-1)#注意用户编号从1开始
        return :"参数不正确,请输入1-#{result.length}的数字" if SpyHandler::isI(v) || result.length<(v =v.to_i) || v<=0
#当KEY_VOTE>0游戏中,任意人非死人可被杀
#当KEY_VOTE==0投票结束,此时KEY_L_G_VT[n]=0代表此人投票不是最高票,不能被杀
        v-=1#用户编号从1开始,VT从0开始
        return "此人不能被杀,手下留情." if result[v].to_i<=(VOTE_INIT_S+(((i=@@r.get(Constance::KEY_VOTE+gid).to_i)>0) ? -1 : 0 ))
#kill killedno guy
        @@r.lset(Constance::KEY_L_G_VT+gid,v,VOTE_DEAD)
        result[v] = VOTE_DEAD
#p result,v,i
        i>0 ? @@r.decr(Constance::KEY_VOTE+gid) : self.nextTurn(gid,result)
        "#{v+1}号被杀,请继续"
    end
#
    def self.finishVote(uid,isforce)
        usr = @@r.lrange(Constance::KEY_L_USR+uid,0,-1)
        return :"不存在你的数据" if ! (gid = usr && usr[0])
        return "还有人未投票,强行进入下一轮,请用nextf指令" if !isforce && (@@r.get(Constance::KEY_VOTE+gid).to_i)>0
        result = @@r.lrange(Constance::KEY_L_G_VT+gid,0,-1)#注意用户编号从1开始
        if isforce
            count = getResult(gid, result)
        else
            count = 0
            result.each{|x| count+=1 if x.to_i>0 }
        end
        s = self.getVoteResult(gid,result,isforce)
puts "before"+result.to_s

        if flag = (!isforce && count==1)
            i=result.length-1
            while i>=0
                if result[i].to_i>0
                    @@r.lset(Constance::KEY_L_G_VT+gid,i,VOTE_DEAD)
                    result[i] = VOTE_DEAD
                    break;
                end
                i-=1
            end
        end
        self.nextTurn(gid,result)
p result
        s += flag ? "\n得票最高者已经被清除,游戏继续." : "\n请通过kill no.手动清除需要清除的玩家"
    end
##########################
private
    def self.nextTurn(gid,result)
        count = 0
        (result.length-1).downto(0)do |x|
            if result[x].to_i>=0
                count += 1 ;
                @@r.lset(Constance::KEY_L_G_VT+gid,x,VOTE_INIT_S)
                else
                p x
            end
        end
        @@r.set(Constance::KEY_VOTE+gid, count)
    end
    def self.votework(gid, v,result,u)
        return "您已经投过票了." if result[u].to_i>VOTE_INIT_S
        return "死人消停一下." if result[u].to_i==VOTE_DEAD
        return "此人不能被投,手下留情." if result[v-1].to_i<VOTE_INIT_S
#p Constance::KEY_L_G_VT+gid, u,v
        result[u] = v
        @@r.lset(Constance::KEY_L_G_VT+gid, u, v )
        if @@r.decr(Constance::KEY_VOTE+gid)==0 #投票结束,计算结果
            self.getResult(gid,result)
        end
#@@r.lindex(Constance::KEY_L_G_VT+gid,u)
    end
    #optimized prompt
    def self.getText(c,no,flag)
		"\n你的编号为: #{no}"+(c>0 ? "\n还有#{c}人未加入" : (flag ? "\n人齐，游戏开始" : ""))
    end
    def self.getVoteResult(gid,result,isforce=false)
       if ( (a = @@r.get(Constance::KEY_VOTE+gid).to_i)>0) && !isforce
           "\n还有#{a}人未投票"
           else
            s = "\n投票结果:"
            #p result
           (result.length-1).downto(0){|x| s+="\n编号#{x+1}获最高票" if result[x].to_i>VOTE_INIT_S}
           s
        end
    end
    
    #deprecated, instance should NOT be new
    def initialize
        p "deprecated method, instance should be creat by getNewGroup"
    end
	#获取问题词组
    # str : 词语数组,如果数组长度2,str[0]人的词,str[1]白痴的词,鬼的内容只有人的词的字数,
    #	如果长3,str[2]=>鬼的描述.
    #	如果长0,题库中随机获取
    def self.getWord(str)
        if str.length==0
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
	#创建组相关数据
	#--词组内容
	#--用户身份
	#--返回组id
    def self.createGroup(str, ownerid, human, spy,isKiller)
        str = ["平民", "警", "匪"]   if isKiller #killer game
        if (s = self.getWord(str))==nil
            return nil
        end
        gid = getNewGroupID(ownerid)
        initGroup(gid, ownerid,human,spy,s , str.length==0, isKiller).to_s+"游戏编号:#{gid}\n其他人可输入此编号，开始游戏。"
    end
	#创建redis中组相应的数据
    #isAutoWords
    #   true: 自动获取,开局者也参与游戏,总人数包括开局者,否则不包括
    def self.initGroup(g, ownerid, human,spy,s, isAutoWords, isKiller)
        gid = g.to_s

        total = human+spy
        #owner[ gid, total, "owner"]
        w = s.split(',')

        l = []
        if isKiller
            @@r.rpush(Constance::KEY_L_USR+ownerid, [gid,"总人数：#{total}", Constance::STATUS_[Constance::S_OWN]])
            i = spy
        else
            w[Constance::S_SPY] = "你是卧底,提示:"+w[Constance::S_SPY]
            if isAutoWords then
                i = spy
                human = total
            else
                @@r.rpush(Constance::KEY_L_USR+ownerid, [gid,"总人数：#{total}", Constance::STATUS_[Constance::S_OWN]])
            
                #白痴生成算法
                #3人：2人，0白，1卧
                #4-10人：1白
                #11-20人：2白
                #>20人：人太多了
                i = (total+3)/7
            end
        end
        @@r.rpush(Constance::KEY_L_G_Q+gid,w)

        (i-1).downto(0){|x|l[x]=Constance::S_IDT}
        (human-1).downto(i){|x|l[x]=Constance::S_HUM}
        (total-1).downto(human){|x|l[x]=Constance::S_SPY}
        #洗牌身份
        Constance::shuffle(l)
#p l
        @@r.rpush(Constance::KEY_L_G_S+gid, l )

        @@r.rpush(Constance::KEY_L_G_U+gid, ownerid )

        @@r[Constance::KEY_GRP_COUNT+gid] = total

        a = Array.new(total, VOTE_INIT_S)
        @@r.rpush(Constance::KEY_L_G_VT+gid, a)
        @@r.set(Constance::KEY_VOTE+gid, a.length)

        isAutoWords ? self.addUsr(gid,ownerid).to_s+"\n" : ""

    end
    #release 调试开关
DBG_RELEASE = false
	#no more comments
    def self.releaseGroupbyGid(gid)
p "R"*11+"  release #{gid},#{File.basename(caller[0])}"
if DBG_RELEASE
    p @@r.keys("U*"),@@r.zrange("GROUP",0,-1)
    p @@r.keys("G*"),@@count.to_s+";"+gid.to_s
end
        usrs = @@r.lrange(Constance::KEY_L_G_U+gid,0,-1)
        @@r.del(Constance::KEY_L_G_Q+gid)
        @@r.del(Constance::KEY_L_G_S+gid)
        @@r.del(Constance::KEY_GRP_COUNT+gid)
        @@r.del(Constance::KEY_L_G_VT+gid)
        @@r.del(Constance::KEY_VOTE+gid)
        usrs.each{|x|@@r.del(Constance::KEY_L_USR+x)}
        @@r.del(Constance::KEY_L_G_U+gid)
        @@count -= 1 if (@@r.zrem(Constance::KEY_Z_GROUPS, gid))
if DBG_RELEASE
    p @@r.keys("U*"),@@r.zrange("GROUP",0,-1)
    p @@r.keys("G*"),@@count.to_s+";"+gid.to_s
end
    end
	#no more comments
    def self.releaseGroupbyUsr(ownerid)
        uinfo = @@r.lrange(Constance::KEY_L_USR + ownerid, 0, -1)
#p uinfo
        return nil if uinfo==nil || uinfo.length==0
        releaseGroupbyGid( uinfo[0] )
    end
	#根据@@count获取id位数
	#自动升位
    def self.getNewGroupID(id)
        i = 10
        d = DENSITY
        while @@count > d do
            i *= 10
            d *= 10
        end
        gid = generateID(id, i)
    end
	#根据现有库生成尽量短的uuid
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
if __FILE__ == $0
=begin
=end
DEBUG_COUNT = 1
def dbg_group(human,spy)
    s =["aren","b白","dd鬼"]
    s1 = []
    i = rand(100).to_s
    (s.length-1).downto(0) {|x| s1[x] = s[x]+i}
    gid = Spygroup.getNewGroup( "own"+rand(DEBUG_COUNT+1).to_s, human, spy,s1)
    require "../debug/postxml.rb"
    gid = Debugwx::findGid(gid)
    (human+spy+1).downto(1){|x| p "##"+Spygroup.addUsr(gid,"u"+x.to_s+gid.to_s).to_s}
end
#DEBUG_COUNT.downto(0){|x|dbg_group(8,3);p '*'*10}
#Spygroup::releaseExpiration(1)

Spygroup::getResult("3",["2","4",'4','2'])
p
=begin
=end
end
