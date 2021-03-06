require File.dirname(__FILE__) +"/../WeChatHandler.rb"
require File.dirname(__FILE__) +"/spygroup.rb"

class SpyHandler
    include WeChatHandler
    
    AUTOREPLY = "指令错误:\n输入：!new 总游戏人数 卧底人数 平民词汇 白痴词汇 卧底词汇\n--新开局， 最后一个卧底词可以不输入，3个词也可都不输入，自动获取游戏词,此时创建者也作为游戏成员计数。\n例：\n!new 6 2 香蕉 菠萝 水果\n\n输入:局代码，获取角色  \n\n输入:!v 人员编号(投票谁为卧底)\n例:\n!v 2 \n\n输入: !next 结束当前轮投票,返回投票结果"
    PARAM_WRONG1 = "需要总人数和卧底数， 例：\n！new 8 2"
    PARAM_WRONG2 = "参数个数不对，如果指定词汇至少需要2个词汇，也可以是3个，例：\n!new 9 3 香蕉 芭蕉 水果"
    PARAM_WRONG_KILLER = "需要总人数,,例:\n !killer 8 \n或 \n!killer 9 2\n9个人,2警2匪5平民"
    PARAM_WRONG_KILLERNo = "杀手比例错误."
    PARAM_WRONG_KTOTALNo = "游戏人数错误.(6-19)"
    TOOMUCHSPY = "卧底太多了吧"
    TOOMUCHPERSON = "人也太多了吧"
    TOOLESSPERSON = "人也太少了吧"
    
	#字符串是否为数字
	def self.isI(str)
		(str=~/^\d+?$/)!=nil
	end
	#
    def WeChattextHandler( xml )
		return formatResponse( xml, textHandler(xml))        
    end
    
    #指令，函数映射表
    COMMAND = {
		'new'=>'newGame', #新建卧底游戏
        'v'=>'vote',    #投票
        'nextf'=>'finishVoteForce',   #强制完成投票,进入下一轮
        'next'=>'finishVote',   #完成投票,进入下一轮
        'kill'=>'killbyno', #杀一人
        'killer'=>'killGame',   #新建杀手游戏
        'revote'=>'revote', #重新投票
		}
	
    private
    #根据输入返回content
    def textHandler(xml)
        cmd = xml.elements["Content"].text
        return AUTOREPLY if cmd[0]!='!' && cmd[0]!='！' && (!self.class.isI(cmd))
        return parseCMD(cmd[1..cmd.length],xml.elements["FromUserName"].text) if(cmd[0]=='!' || cmd[0]=='！')
#p "%"*11
        return addUser(cmd,xml.elements["FromUserName"].text)
	end
	
    #
    def createGame(uid, data)
        return PARAM_WRONG1 if  !self.class.isI(data[0]) || !self.class.isI(data[1])
        total = data.shift.to_i
        spy = data.shift.to_i
        return TOOLESSPERSON if total<4
        return TOOMUCHPERSON if total>20
        return TOOMUCHSPY if total<(spy<<1)
        Spygroup::getNewGroup(uid, total-spy,spy,data )
        
    end
	#格式化content返回值=>xml
    def formatResponse( xml, content)
		xml.elements["FromUserName"].text , xml.elements["ToUserName"].text = xml.elements["ToUserName"].text , xml.elements["FromUserName"].text  
		xml.elements["Content"].text = content
		xml.elements["CreateTime"].text = Time.now.to_i.to_s
		xml
    end
    #
    def addUser( gid, uid)
		Spygroup::addUsr( gid, uid)
    end
    #指令处理
    def parseCMD(cmd, uid)
		i = cmd.index(' ')
        i = cmd.length if i==nil
		str = ((i) && i>0)?cmd[0..(i-1)] : (i=0,cmd)
        str.downcase!()
		return AUTOREPLY if (COMMAND[str]==nil)
		send(COMMAND[str],uid,cmd[i,cmd.length])
    end
    #完成本轮投票
    def finishVote(uid, deprecated)
        Spygroup::finishVote(uid,false)
    end
    def finishVoteForce(uid, deprecated)
        Spygroup::finishVote(uid,true)
    end
    # result, 怀疑对象userid
    def vote(uid,result="")
        Spygroup::vote(uid, result)
    end
    #
    def newGame(uid, cmd='')
		data = cmd.split(' ')
		case data.length
		when 0,1 then PARAM_WRONG1
		when 3 then PARAM_WRONG2
		when 2,4,5 then createGame(uid,data)
		else PARAM_WRONG2
		end
    end
#
    def killbyno(uid, killedno)
        Spygroup::killbyno(uid,killedno)
    end
#
    def killGame(uid, cmd)
		data = cmd.split(' ')
        return PARAM_WRONG_KILLER if data.length<=0 || data.length>2
        data.each{|x| return PARAM_WRONG_KILLER unless self.class.isI(x)}
        total = data[0].to_i
        if data.length>1
            spy = data[1].to_i
            return PARAM_WRONG_KILLERNo if (spy *3+1) >=total
        else
            case total
            when 6..8 then spy = 1
            when 9..11 then spy = 2
            when 12..15 then spy = 3
            when 16..19 then spy = 4
            else return PARAM_WRONG_KTOTALNo
            end
        end
        Spygroup::getNewGroup(uid, total-spy,spy,nil, true )
    end
end
