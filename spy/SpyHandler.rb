require File.dirname(__FILE__) +"/../WeChatHandler.rb"

class SpyHandler
    include WeChatHandler
    def WeChattextHandler( xml )
        p "#"*11,xml
    end
end