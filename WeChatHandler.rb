
module WeChatHandler
    def WeChattextHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def WeChatimageHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def WeChatvoiceHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def WeChatvideoHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def WeChatlocationHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def WeChatlinkHandler( xml )
        raise :"#{__callee__} 需要被实现. "
    end
    def Handler(xml)
        xml = xml.elements["xml"]
        send("WeChat#{xml.elements['MsgType'].text}Handler", xml)
    end
=begin
= end    
    def method_missing(name,*args)
        p "wrong function called: #{name}"
        #    super name
    end
=begin
=end    
    
end
