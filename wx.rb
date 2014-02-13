require 'sinatra'
require "./xml.rb"
#require "./wxcontroller.rb"
require "erb"

get '/hi' do
  if(!check_weixin_legality) then return [403,{},"Forbidden"]; end
#  puts "my######{33}"
#  puts params
    params[:echostr]# + Time.now.to_s
end

post '/hi' do
  if(!check_weixin_legality) then return [403,{},"Forbidden"]; end

  tempfile=params[:datafile][:tempfile]
  content_type 'text/xml'
  if (tempfile) && doc=parseXML(tempfile)
      @doc=doc.elements["xml"]
      p @doc
      @result = 'echo: '+ @doc.elements["Content"].text
      erb :response, :format=>:xml
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

