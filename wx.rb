require 'sinatra'
require "./xml.rb"
require "./spy/SpyHandler.rb"


handler = SpyHandler.new

get '/hi' do
	if(!check_weixin_legality) then return [403,{},"Forbidden"]; end
#  puts params
	params[:echostr]# + Time.now.to_s
end

post '/hi' do
  if(!check_weixin_legality) then return [403,{},"Forbidden"]; end

  tempfile=params[:datafile][:tempfile]
  content_type 'text/xml'
  if (tempfile) && doc=parseXMLFile(tempfile)
#puts doc.elements["xml"]
	@doc = handler.Handler(doc).to_s
    #puts "^"*11 ,@doc
    #erb :@doc, :format=>:xml
   else
    "wrong format!"
  end
end




WEIXIN_TOKEN = "123"
def check_weixin_legality

  array = [WEIXIN_TOKEN, params[:timestamp], params[:nonce]].sort
  #puts  Digest::SHA1.hexdigest(array.join)
  if (params[:signature] != Digest::SHA1.hexdigest(array.join)) then
    return false
  end
  return true
end

