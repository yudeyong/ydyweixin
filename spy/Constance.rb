
class Constance
    KEY_QUES = "QUES:"
    KEY_QUES_COUNT = KEY_QUES+"COUNT"
    KEY_Z_GROUPS = "GRP" #set[groupid1,groupid2]
    KEY_L_G_Q = "G:Q:" #list[S_HUM,S_IDT,S_SPY], 组,问题
    KEY_L_G_S = "G:S:" #list, 组,身份, #当局用户数个元素
    KEY_L_G_U = "G:U:" #组,用户, #当局用户数+1个元素
    KEY_GRP_COUNT = "G:U:COUNT:" #该组当前未获取问题用户数
    KEY_VOTE = "G:V:" #投票人数 当前未投票人数
    KEY_L_G_VT = "G:VT:"
    #投票过程中KEY_VOTE>0
    #
    #投票临时结果 结构同KEY_L_G_S,每个值存储当前这轮投票该用户被投票结果
    #>VOTE_INIT_S-- 已投,值为投票对象id
    #=VOTE_INIT_S-- 尚未投票
    #=VOTE_BLOCK--  pk中,暂时不能投
    #=VOTE_DEAD--   已死,不能投
    #
    #投票结束计算结果时KEY_VOTE==0
    #>VOTE_INIT_S-- 被投最多数的人,可能有多个
    
    KEY_L_USR = "U:"
    #= list[groupid,答案,身份,id] 身份#{STATUS_}
    #= list[groupid,当前局人数(有法官时,不算法官),owner,N/A] #if 身份=owner && 3种角色玩法
    S_HUM=0
    S_IDT=1
    S_SPY=2
    S_OWN=3
    STATUS_ = ["人", "白痴", "卧底", "own"]
    
    EXPIRE_TERM = 60#*60 #1 hour
    
    CHECK_EXPIRATION_COUNT = 5 #每次检查过期项目数>1
    #shuffle array[]
    def self.shuffle(list)
        l = list.length
        cur = 0
        l.downto(1){|i|
            j = rand(i);
            k = i-1
            list[k],list[j] = list[j],list[k];
        }
    end
end

#l = [1,2,3,4]
#Constance::shuffle(l)
#p l
