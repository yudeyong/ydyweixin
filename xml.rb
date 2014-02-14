require "rexml/document"  
include REXML  

def parseXMLFile(filename)
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

def parseXML(str)
    doc = Document.new(str)
end
