require 'csv'
require 'redis'
require File.dirname(__FILE__) +'/Constance'

def loadSpyDb(r)
    l=0
    CSV.foreach(File.dirname(__FILE__) +'/spy.csv','r') do |row|
        i = 0
        if row!=nil
            st = makewords(row)
            r[Constance::KEY_QUES+l.to_s] = st
            l+=1
        end
    end
    r[Constance::KEY_QUES_COUNT] = l
    #(l-1).downto(0){|x|p r[Constance.KEY_QUES+x.to_s]}
end

def makewords(row)
    row[0] + "," + row[1] + ",字数:" + row[0].length.to_s
end
