#! /usr/bin/env ruby

# TODO
# - handle user input redirection
# - readline
# - multiline commands

# Credits:
# - Initial linux version:  Gilles Filippini
# - Initial windows port : Marco Fraillis
# - Currently maintained and developed by 
#     Martin DeMello <martindemello@gmail.com>

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

require "irb"
require "singleton"
require "English"

include Fox

STDOUT.sync = true

class FXIRBInputMethod < IRB::StdioInputMethod

  def initialize
    super 
    @history = 1
		@begin = nil
		@end = nil
  end

  def gets 
    print @prompt
		
		if @prompt =~ /(\d+)[>*]/
			print "  "*$1.to_i
		end
		
    str = FXIrb.instance.gets
    if /^exit/ =~ str
      exit
    end

		@line_no += 1
		@history = @line_no + 1
		@line[@line_no] = str
  end

	def compact
		print [@compact, @continued].inspect
		if false # @compact
			@compact = false
			a = @line_no - @continued
			@lines[a] = @lines[a..2].join
		end
	end

  def prevCmd
    if @line_no > 0
      @history -= 1 unless @history <= 1
      return line(@history)
    end
    return ""
  end

  def nextCmd
    if (@line_no > 0) && (@history < @line_no)
      @history += 1
      return line(@history)
    end
    return ""
  end

end

module IRB

  def IRB.start_in_fxirb(im)
    if RUBY_VERSION < "1.7.3"
      IRB.initialize(nil)
      IRB.parse_opts
      IRB.load_modules
    else
      IRB.setup(nil)
    end

    irb = Irb.new(nil, im)    

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context
    trap("SIGINT") do
      irb.signal_handle
    end
    
    catch(:IRB_EXIT) do
      irb.eval_input
    end
    print "\n"
  end

end

class FXIrb < FXText
	include Singleton
	include Responder

	attr_reader :input

	def FXIrb.init(p, tgt, sel, opts)
		unless @__instance__
			Thread.critical = true
			begin
				@__instance__ ||= new(p, tgt, sel, opts)
			ensure
				Thread.critical = false
			end
		end
		return @__instance__
	end

	def initialize(p, tgt, sel, opts)
		FXMAPFUNC(SEL_KEYRELEASE, 0, "onKeyRelease")
		FXMAPFUNC(SEL_KEYPRESS, 0, "onKeyPress")
		FXMAPFUNC(SEL_LEFTBUTTONPRESS,0,"onLeftBtnPress")
		FXMAPFUNC(SEL_MIDDLEBUTTONPRESS,0,"onMiddleBtnPress")
		FXMAPFUNC(SEL_LEFTBUTTONRELEASE,0,"onLeftBtnRelease")

		super
		setFont(FXFont.new(FXApp.instance, "lucida console", 9))
	end

	def create
		super
		setFocus
		# IRB initialization
		@inputAdded = false
		@input = IO.pipe
		$DEFAULT_OUTPUT = self

		@im = FXIRBInputMethod.new
		@irb = Thread.new {
			IRB.start_in_fxirb(@im)
		}
	end

	def onKeyRelease(sender, sel, event)
		case event.code
		when Fox::KEY_Return, Fox::KEY_KP_Enter
			newLineEntered
		end
		return 1
	end

	def onKeyPress(sender,sel,event)
		case event.code
		when Fox::KEY_Return, Fox::KEY_KP_Enter
			setCursorPos(getLength)
			super
		when Fox::KEY_Up,Fox::KEY_KP_Up
			str = @im.prevCmd.chop
			if str != ""
				removeText(@anchor, getLength-@anchor)
				write(str)
			end
		when Fox::KEY_Down,Fox::KEY_KP_Down
			str = @im.nextCmd.chop
			if str != ""
				removeText(@anchor, getLength-@anchor)
				write(str)
			end
		when Fox::KEY_Left,Fox::KEY_KP_Left
			if getCursorPos > @anchor
				super
			end
		when Fox::KEY_Delete,Fox::KEY_KP_Delete,Fox::KEY_BackSpace
			if getCursorPos > @anchor
				super
			end
		when Fox::KEY_Home, Fox::KEY_KP_Home
			setCursorPos(@anchor)
		when Fox::KEY_End, Fox::KEY_KP_End
			setCursorPos(getLength)
		when Fox::KEY_Page_Up, Fox::KEY_KP_Page_Up,
			Fox::KEY_Page_Down, Fox::KEY_KP_Page_Down
		when Fox::KEY_bracketright
			#auto-dedent if the } or ] is on a line by itself
			if (emptyline? or (getline == "en")) and indented?
				str = getline
				@anchor -= 2
				rmline
				appendText(str)
				setCursorPos(getLength)
			end
			super
		when Fox::KEY_u
			if (event.state & CONTROLMASK) != 0 
				str = extractText(getCursorPos, getLength - getCursorPos)
				rmline
				appendText(str)
				setCursorPos(@anchor)
			end
			super
		when Fox::KEY_k
			if (event.state & CONTROLMASK) != 0
				str = extractText(@anchor, getCursorPos-@anchor)
				rmline
				appendText(str)
				setCursorPos(getLength)
			end
			super
		when Fox::KEY_d
			if (event.state & CONTROLMASK) != 0
				#Ctrl - D
			  rmline
				appendText("exit")
				sendCommand("exit")
				newLineEntered
			else
				# test for 'end' so we can dedent
				if (getline == "en") and indented?
					str = getline
					@anchor -= 2
					rmline
					appendText(str)
					setCursorPos(getLength)
				end
			end
			super
		else
			super
		end
	end

	def getline
		extractText(@anchor, getLength-@anchor)
	end

	def rmline
		str = getline
		removeText(@anchor, getLength-@anchor)
		str
	end

	def emptyline?
		getline == ""
	end

	def indented?
		extractText(@anchor-2, 2) == "  "
	end

	def onLeftBtnPress(sender,sel,event)
		@store_anchor = @anchor
		setFocus
		super
	end

	def onLeftBtnRelease(sender,sel,event)
		super
		@anchor = @store_anchor
		setCursorPos(@anchor)
		setCursorPos(getLength)
	end

	def onMiddleBtnPress(sender,sel,event)
		pos=getPosAt(event.win_x,event.win_y)
		if pos >= @anchor
			super
		end
	end

	def newLineEntered
		processCommandLine(extractText(@anchor, getLength-@anchor))
	end

	def processCommandLine(cmd)
		#write("[#{cmd}]")
		@input[1].puts cmd
		@inputAdded = true
		@irb.run
	end

	def sendCommand(cmd)
		setCursorPos(getLength)
		makePositionVisible(getLength) unless isPosVisible(getLength)
		cmd += "\n"
		appendText(cmd)
		processCommandLine(cmd)
	end

	def write(obj)
		str = obj.to_s
		appendText(str)
		setCursorPos(getLength)
		makePositionVisible(getLength) unless isPosVisible(getLength)
		return str.length
	end

	def gets
		@anchor = getLength
		if !@inputAdded
			Thread.stop
		end
		@inputAdded = false
		return @input[0].gets
	end
end

# Stand alone run
if __FILE__ == $0
	application = FXApp.new("FXIrb", "ruby")
	application.threadsEnabled = true
	Thread.abort_on_exception = true
	application.init(ARGV)
	window = FXMainWindow.new(application, "FXIrb", nil, nil, DECOR_ALL, 0, 0, 580, 500)
	FXIrb.init(window, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP|TEXT_SHOWACTIVE)
	application.create
	window.show(PLACEMENT_SCREEN)
	application.run
end

