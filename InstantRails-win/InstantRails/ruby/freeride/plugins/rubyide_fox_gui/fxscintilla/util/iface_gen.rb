# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License
#
# Updated 2003 for Scintilla 1.52

class ScintillaGenerator
  VALUE        = /val\s+([A-Z_]\w+)=/
  FUNCTION     = /fun\s([a-z]\w+)\s(\w+)=([0-9]\w+)\((\w+)?\s?(\w+)?,\s?(\w+)?\s?(\w+)?\)/
  SET          = /set\s([a-z]\w+)\s(\w+)=([0-9]\w+)\((\w+)?\s?(\w+)?,\s?(\w+)?\s?(\w+)?\)/
  GET          = /get\s([a-z]\w+)\s(\w+)=([0-9]\w+)\((\w+)?\s?(\w+)?,\s?(\w+)?\s?(\w+)?\)/
  EVENT        = /evt\s([a-z]\w+)\s(\w+)=([0-9]\w+)\((.*)\)/
  COMMENT      = /##/
  LINE_COMMENT = /#\s/
  
  INT = "int"
  VOID = "void"
  BOOL = "bool"
  POSITION = "position"
  COLOUR = "colour"
  STRING_RESULT = "stringresult"
  STRING = "string"
  
  if ARGV.size ==1
    DEBUG = eval(ARGV[0])
  else
    DEBUG=false
  end
  
##     void
##     int
##     bool -> integer, 1=true, 0=false
##     position -> integer position in a document
##     colour -> colour integer containing red, green and blue bytes.
##     string -> pointer to const character
##     stringresult -> pointer to character
##     cells -> pointer to array of cells, each cell containing a style byte and character byte
##     textrange -> charrange + output string
##     findtext -> searchrange, text -> foundposition
##     keymod -> integer containing key in low half and modifiers in high half
##     formatrange


  def initialize(input, output)
    @input = input
    @output = output
    @event_stubs = []
    @event_cases = []
  end
  
  def generate
    o = File.new(@output, "w")
    o.puts "## ***** WARNING...THIS FILE IS GENERATED BY FROM SCINTILLA.IFACE"
    o.puts "## *****           DO NOT MODIFY...MODIFY SCINTILLA.RB INSTEAD\n\n"
    o.puts "module Scintilla"
    
    i = File.new(@input)
    i.each_line do |line| 
      parse_line(line) { |text| o.puts text }
    end
    i.close
    
    o.puts "  module ScintillaEvents"
    o.puts "    def handle_notification(from, id, scn)"
    o.puts "      case id"
    @event_cases.each {|ecase| o.puts ecase}
    o.puts "      end"
    o.puts "    end"
    @event_stubs.each {|event| o.puts event}
    o.puts "  end"
    
    o.puts "end"
    o.close
  end
  
  def parse_line(line)
    if line.length==1
      yield ""
      return
    end
    case line
    when VALUE
      @in_line_comment = false
      yield "  #{$1} = #{$'}"
    when LINE_COMMENT
      unless @in_line_comment
        yield "  ##\n"
        @in_line_comment = true
      end
      yield "  #{line}"
    when EVENT
      @in_line_comment = false
      returnType = $1
      function = $2
      function = "on_"+un_camelcase(function)
      id = $3
      params = $4.split(",").collect {|p| p.strip}
      params = nil if params == ['void']
      event =  "    def #{function}"
      if params
        event << "("
        event << (params.collect {|param| un_camelcase(param.split(' ')[1])}).join(", ")
        event << ")\n"
      else
        event << "\n"
      end
      event << "    end\n"
      @event_stubs << event
      
      event_case =  "      when #{id}\n"
      event_case += "        #{function}"
      if params
        event_case << "("
        event_case << (params.collect {|param| "scn."+param.split(' ')[1]}).join(", ")
        event_case << ")\n"
      else
        event_case << "\n"
      end
      @event_cases << event_case
    when GET, SET, FUNCTION
      @in_line_comment = false
      returnType = $1
      function = $2
      function = (line[1,2]=='et' ? line[0,3] : '') + function unless function[0,3].downcase==line[0,3]
      function = un_camelcase(function)
      id = $3
      param1Type = $4
      param1 = $5
      param2Type = $6
      param2 = $7
      
      param1 = "finish" if param1=="end"
      param2 = "finish" if param2=="end"
      
      if param1Type==INT && param1=="length" && param2Type==STRING && param2=="text"
        str =  "  def #{function}( text )\n"
        str << "    send_message(#{id}, text.length, text)\n"
        str << "  end\n\n"
      elsif param2Type==STRING_RESULT
        str =  "  def #{function}"
        str << "( " if param1
        str << param1 if param1
        str << " )" if param1
        str << "\n"
        if param1 && param1=="length"
          str << "    buffer = ' '*#{param1}\n"
          str << "    send_message(#{id}, #{param1}, buffer)\n"
        else
          if param1
            str << "    len = send_message(#{id}, #{param1}, '')\n"
            str << "    buffer = ' '*len\n"
            str << "    send_message(#{id}, #{param1}, buffer)\n"
          else
            str << "    len = send_message(#{id}, 0, '')\n"
            str << "    buffer = ' '*len\n"
            str << "    send_message(#{id}, len, buffer)\n"
          end
        end
        str << "    return buffer\n"
        str << "  end\n"
        if line[0,3]=='get'
          str << "  alias :#{function[4..-1]} :#{function}\n"
        elsif line[0,3]=='set'
          str << "  alias :#{function[4..-1]}= :#{function}\n"
        end
      else 
        str =  "  def #{function}"
        #str << "?" if returnType==BOOL
        str << "( " if param1 || param2
        str << param1 if param1
        str << " , " if param1 && param2
        str << param2 if param2
        str << " )" if param1 || param2
        str << "\n"
        if DEBUG
          str << ("    puts "+'"'+"called #{function} ")
          str << "( " if param1 || param2
          str << ('#{'+param1+'}') if param1
          str << " , " if param1 && param2
          str << ('#{'+param2+'}') if param2
          str << " )" if param1 || param2
          str << ('"'+"\n")
        end
        str << "    return (send_message(#{id}, #{caste_param(param1, param1Type)}, #{caste_param(param2, param2Type)})"
        str << (returnType==BOOL ? "==1 ? true : false)\n" : ")\n")
        str << "  end\n"
        if line[0,3]=='get'
          str << "  alias :#{function[4..-1] + (returnType==BOOL ? '?' : '')} :#{function}\n"
        elsif line[0,3]=='set' && !param2 && param1
          str << "  alias :#{function[4..-1]}= :#{function}\n"
        end
      end
      yield str
    when COMMENT
      @in_line_comment = false
    else
    end # case line

  end # def parseLine(line)
  
  def caste_param(param, type)
    return "0" unless param
    case type
    when COLOUR
      result = "#{param}.to_i"
    when BOOL
      result = "( #{param} ? 1 : 0 )"
    else
      result = param
    end
    return result
  end
  
  def un_camelcase(func)
    result = ""
    scratch = ""
    func.each_byte do |byte|
      if (?A..?Z).include? byte
        scratch << byte.chr
      else
        if scratch.size==1
          result += "_"+scratch
          scratch = ""
        elsif scratch.size>1
          result += "_"+scratch[0..-2]+"_"+scratch[-1,1]
          scratch = ""
        end
        result += byte.chr
      end
    end
    result += "_"+scratch if scratch!=""
    result = result[1..-1] if result[0,1]=='_'
    result.downcase
  end

end # class ScintillaParser

if __FILE__ == $0
  ScintillaGenerator.new("Scintilla.iface", "scintilla_wrapper.rb").generate
end
