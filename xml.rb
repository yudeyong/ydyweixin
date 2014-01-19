require "rexml/document"  
include REXML  
def parseXML(filename) 
  doc = Document.new(File.new(filename))  
#  root = doc.root  
#  puts "*" * 8
  #puts doc.elements["xml"].count
#  doc.elements.each("xml/*") { |e|   
#  print ":"
#  puts  e.name
  #e.elements.each { |child| puts "\t\t"+child.text}  
#  }
  #puts doc.elements["xml/ToUserName"].text
#  return doc
end