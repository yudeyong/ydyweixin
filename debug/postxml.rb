require "net/http"
require "uri"
require "erb"

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

puts post_body


    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth "user", "pass"
    request.body = post_body.join
    request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

#return
    resp = http.request(request)
    p resp['content-type']
    puts resp.body
end
end
if __FILE__ == $0
	Debugwx.new.req("u1", "new")
end
