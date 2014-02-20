require "net/http"
require "uri"
require "erb"
require "../xml.rb"
require "../spy/SpyHandler.rb"

class Debugwx
	BOUNDARY = "AaB03x"
	REQUEST_OFFLINE = !false #debug switch
	Hh = SpyHandler.new
	
	#debug for send xml to server
	# offline switch to on, works
	# req() also works in irb individual invoke,require ".rb" is needed
	def self.req(uid, content)
		uri = URI.parse('http://localhost/hi?timestamp=df&nonce=3&signature=ab25b59a6311e46a4da23644995b858d2f8bdae8&echostr=f')
		file = "wx.xml"

		s = File.read("require.erb")
		account = "ac"
		b = binding

		ERB.new(s, 0, "", "s").result b
	 #puts s
		if !REQUEST_OFFLINE
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
			doc = resp.body

		#tempfile=params[:datafile][:tempfile]
		#content_type 'text/xml'
		else
			doc = parseXML(s)
			doc = Hh.Handler(doc)
		end
		if doc=parseXML(doc.to_s)
			d =doc.elements["xml"]
			result = d.elements["Content"].text
		end
	end
	
	def self.findGid(s)
		i = s.index("游戏编号:")+5
		j = s.index("其")-2
		s[i..j]
	end
end

if __FILE__ == $0
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
    def create(msgtype)
        #        dd = DbgDebugwx.new
        Hh.Handler('x')
        Hh.send("WeChat#{msgtype}Handler", "tt")
    end
#create("text");return
=end
if $*[0]
    s = $*[1]
    s = (SpyHandler::isI(s) ? "" : "!")+s
    puts Debugwx::req($*[0],s )
    return
end
p "@"*11
	total = 4
    puts s = Debugwx::req("o"+rand(3).to_s, "！new #{total} 1 ")
    s = Debugwx::findGid(s).to_i
    total.downto(1){|x| u = "u"+rand(44).to_s;puts "x=#{x},u=#{u},#{Debugwx::req(u.to_s,s)}"} if s.is_a?Integer
    
    i = s.to_s.index(' ')
    s = s[0..(i-1)] if ((i)!=nil && i>0)
=begin
= end
    
 require 'redis'
 r = Redis.new
 r.rpush("a", 3)
 p r.lrange("a",0,-1)
 
	p r.keys "G*"
	p r.keys "U*"
#    p s
=begin
=end

end
