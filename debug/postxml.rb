require "net/http"
require "uri"
require "erb"
require "../xml.rb"

class Debugwx
BOUNDARY = "AaB03x"

def req(uid, content)
    uri = URI.parse('http://localhost/hi?timestamp=df&nonce=3&signature=ab25b59a6311e46a4da23644995b858d2f8bdae8&echostr=f')
    file = "wx.xml"

	s = File.read("require.erb")
	account = "ac"
	b = binding

    ERB.new(s, 0, "", "s").result b
 
#puts s
    # Token used to terminate the file in the post body. Make sure it is not
    # present in the file you're uploading.
    
    post_body = []
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=datafile; filename='#{File.basename(file)}'\r\n"
    post_body << "Content-Type: text/xml\r\n"
    post_body << "\r\n"
    post_body << s
    post_body << "\r\n--#{BOUNDARY}--\r\n"

#puts post_body


    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth "user", "pass"
    request.body = post_body.join
    request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

#return
    resp = http.request(request)
    #    p resp['content-type']
    #puts resp.body

#tempfile=params[:datafile][:tempfile]
#content_type 'text/xml'
    if doc=parseXML(resp.body)
        d =doc.elements["xml"]
        result = d.elements["Content"].text
    end
end
end
if __FILE__ == $0
    require "../spy/SpyHandler"
=begin
    require "../WeChatHandler"
class DbgDebugwx
    include WeChatHandler
    def WeChattextHandler(xml)
        p xml
    end
    def method_missing(name,*args)
        p "wrong function called: #{name}"
    end

end
=end
Hh = SpyHandler.new
    def create(msgtype)
        #        dd = DbgDebugwx.new
        Hh.Handler('x')
        Hh.send("WeChat#{msgtype}Handler", "tt")
    end
#create("text");return
    s = Debugwx.new.req("u1", "new")
    i = s.index(' ')
    s = s[0..(i-1)] if ((i)!=nil && i>0)
    p s
end