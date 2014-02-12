
class Constance
    KEY_QUES = "QUES:"
    KEY_QUES_COUNT = KEY_QUES+"COUNT"
    KEY_S_GROUPS = "GROUP" #set[groupid1,groupid2]
    KEY_L_G_Q = "G:Q:" #list[S_HUM,S_IDT,S_GOS], 组,问题
    KEY_L_G_S = "G:S:" #list, 组,身份, #当局用户数个元素
    KEY_L_G_U = "G:U:" #组,用户, #当局用户数+1个元素
    KEY_GRP_COUNT = "G:U:COUNT" #该组当前未获取问题用户数
    KEY_L_USR = "USR:"
    #= list[groupid,答案,身份] #身份{人,鬼,白痴,owner}
    #= list[groupid,当前局人数(不算owner),owner] #if 身份=owner
    S_HUM=0
    S_IDT=1
    S_GOS=2
    S_OWN=3
    STATUS_ = ["人", "白痴", "鬼", "own"]
    
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