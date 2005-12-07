#!/bin/env ruby

# Load FXRuby: try gem, then Fox 1.2, then Fox 1.0
begin
	# try fxruby gem
	require 'rubygems'
	require_gem 'fxruby', '>= 1.1.0'
	require 'fox12'
	require 'fox12/colors'
	FOXVERSION="1.2"
	include Fox
rescue LoadError
	# no gem? try fox12 direct.
	begin
		require "fox12"
		require "fox12/colors"
		FOXVERSION="1.2"
		include Fox
	rescue LoadError
		# no gem, no fox12? try fox 1.0
		require "fox"
		require "fox/colors"
		# grep for FOXVERSION to find all code that depends on this
		FOXVERSION="1.0"
		include Fox
		FXMenuBar = FXMenubar
		FXToolTip = FXTooltip
		FXStatusBar = FXStatusbar
	end
end

require 'thread'

require 'lib/RiManager'
require 'lib/Recursive_Open_Struct'
require 'lib/Globals'
require 'lib/Packet_List'
require 'lib/Packet_Item'
require 'lib/Empty_Text_Field_Handler'
require 'lib/Icon_Loader'
require 'lib/Search_Engine'
require 'lib/FoxDisplayer'
require 'lib/FoxTextFormatter'
require 'lib/fxirb'

# Responsible for application initialization
class FXri < FXHorizontalFrame
	
	# Initializes the XDCC-application.
	def initialize(p, opts=0, x=0 ,y=0 ,w=0 ,h=0 , pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING)
		super(p, opts, x ,y ,w ,h , pl, pr, pt, pb, hs, vs)
		set_default_font
		# load icons
		icon_loader = Icon_Loader.new(FXApp::instance)
		icon_loader.cfg_to_icons($cfg.icons)
		
		@gui = Recursive_Open_Struct.new
		@gui.main = self
		@data = Recursive_Open_Struct.new
		@data.gui_mutex = Mutex.new
		
		build(self)
		FXToolTip.new(FXApp::instance, TOOLTIP_NORMAL)
		
		@gui.close
		create_data
		
		@data.close
		
		@search_engine = Search_Engine.new(@gui, @data)
		
		# show init message
		@data.displayer.display_information($cfg.text.help)
	end
	
	# Automatically called when the Fox application is created
	def create
		super
		show
		# load items
		load_items
	end
	
	def create_data
		@data.displayer = FoxDisplayer.new(@gui.text)
		@data.ri_manager = RiManager.new(@data.displayer)
		@data.items = Array.new
		@desc = nil
	end
	
	
	# Set the default font to the first font of $cfg.app.font.name that is available on this system.
	def set_default_font
		@font = load_font($cfg.app.font.name)
		FXApp::instance.normalFont = @font if @font
	end
	
	# Returns the first font of the given array of font names that can be loaded, or nil.
	def load_font(font_array)
		# load default font
		font = nil
		font_array.detect do |name|
			next if FXFont.listFonts(name).empty?
			font = FXFont.new(FXApp::instance, name, $cfg.app.font.size)
		end
		font
	end
	
	# build gui
	def build(parent)
		FXSplitter.new(parent, SPLITTER_TRACKING|LAYOUT_FILL_X|LAYOUT_FILL_Y) do |base|
			FXVerticalFrame.new(base, LAYOUT_FILL_X|LAYOUT_FILL_Y, 0,0,$cfg.packet_list_width,0, 0,0,0,0,0,0) do |search_frame|

				@gui.search_field = FXTextField.new(search_frame, 1, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X|FRAME_SUNKEN)
				@gui.search_field.connect(SEL_CHANGED) do |*args|
					on_search
				end
				

				FXVerticalFrame.new(search_frame, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0,0,0,0, 0,0,0,0,0,0) do |list_frame|
					@gui.packet_list = Packet_List.new(@data, list_frame, nil, 0, ICONLIST_COLUMNS|ICONLIST_MINI_ICONS|HSCROLLER_NEVER|VSCROLLER_ALWAYS|TREELIST_BROWSESELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y) do |packet_list|
						packet_list.add_header($cfg.text.method_name, $cfg.packet_list_width) { |x| make_sortable(x) }
					end
				end
				
				@gui.search_label = FXLabel.new(search_frame, "", nil, LAYOUT_FILL_X|LABEL_NORMAL|JUSTIFY_RIGHT, 0,0,0,0, 0,0,0,0)
				
				@gui.packet_list.connect(SEL_SELECTED) do |sender, sel, data|
					item = sender.getItem(data).packet_item
					show_info(item.data)
				end
			end
			
			split = FXSplitter.new(base, SPLITTER_TRACKING|LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL) if $cfg.launch_irb
                        right = FXHorizontalFrame.new(($cfg.launch_irb ? split : base), FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0,0,0,0, 0,0,0,0,0,0)
	                @gui.text = FXText.new(right, nil, 0, TEXT_READONLY|TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	    if $cfg.launch_irb
	      irb_frame = FXHorizontalFrame.new(split, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0,0,0,0, 0,0,0,0,0,0)
	      @irb_frame = irb_frame
	      @gui.irb = FXIrb.init(irb_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP|TEXT_SHOWACTIVE)
	      @gui.irb.setFont(@font) if @font
	      split.setSplit(0, $cfg.irb_height)
	    end
			font = load_font($cfg.ri_font)
			@gui.text.font = font if font
			font.create 
			@gui.text_width = font.fontWidth
			
			@gui.text.connect(SEL_CONFIGURE) do 
				on_show if @desc
			end
			
			# construct hilite styles
			@gui.text.styled = true
			@gui.text.hiliteStyles = create_styles
			
		end
	end
		
	def create_empty_style
		hs = FXHiliteStyle.new
		hs.activeBackColor = FXColor::White
		hs.hiliteBackColor = FXColor::DarkBlue
		hs.normalBackColor = FXColor::White
		hs.normalForeColor = FXColor::Black
		hs.selectBackColor = FXColor::DarkBlue
		hs.selectForeColor = FXColor::White
		hs.style = 0
		hs
	end
	
	def create_styles
		styles = Array.new

		#normal
		styles.push create_empty_style
		
		# bold
		hs = create_empty_style
		hs.style = FXText::STYLE_BOLD
		styles.push hs
		
		# H1
		hs = create_empty_style
		hs.style = FXText::STYLE_UNDERLINE|FXText::STYLE_BOLD
		hs.normalForeColor = FXColor::ForestGreen
		styles.push hs
		
		# H2
		hs = create_empty_style
		hs.style = FXText::STYLE_UNDERLINE
		hs.normalForeColor = FXColor::ForestGreen
		styles.push hs
		
		# H3
		hs = create_empty_style
		hs.normalForeColor = FXColor::ForestGreen
		styles.push hs
		
		# teletype
		hs = create_empty_style
		hs.normalForeColor = FXColor::DarkCyan
		styles.push hs

		# code
		hs = create_empty_style
		hs.activeBackColor = FXColor::LightGrey
		hs.normalForeColor = FXColor::DarkGreen
		hs.style = FXText::STYLE_UNDERLINE|FXText::STYLE_BOLD
		styles.push hs
		
		# emphasis
		hs = create_empty_style
		hs.normalForeColor = FXColor::DarkCyan
		styles.push hs

		# class
		hs = create_empty_style
		hs.style = FXText::STYLE_BOLD
		hs.normalForeColor = FXColor::Blue
		styles.push hs

		styles		
	end
	
	
	# loads all ri items
	def load_items
		@data.ri_manager.all_names.each do |name|
			icon = case name.type
				when NameDescriptor::CLASS
					$cfg.icons.klass
				when NameDescriptor::INSTANCE_METHOD
					$cfg.icons.instance_method
				when NameDescriptor::CLASS_METHOD
					$cfg.icons.class_method
				end
			item = Packet_Item.new(@gui.packet_list, icon, name.to_s)
			item.data = name
			@data.items.push item
		end
		# quick hack to sort in right order :-)
		@gui.packet_list.on_cmd_header(0)
		@gui.packet_list.on_cmd_header(0)
		@gui.packet_list.update_header_width
		recalc
	end

	def go_search(string)
	  @gui.search_field.text = string
	  on_search
	end
	
	def on_search
		@search_engine.on_search
	end
	
	def on_show
		begin
			w = @gui.text.width / @gui.text_width - 3
			w = [w, $cfg.minimum_letters_per_line].max
			@data.ri_manager.show(@desc, w)
		rescue RiError => e
			#puts desc
		end
	end
		
	def show_info(desc)
		@desc = desc
		on_show
	end
	
	
	# x beeing the name of the ri doc, like "Set#delete"
	# This creates a sortable representation. First class, then class methods, then instance.
	def make_sortable(x)
		[ x.downcase.gsub("::", " 1 ").gsub("#", " 2 "),
		x.downcase,
		x]
	end
	
end

if __FILE__ == $0
  Thread.abort_on_exception= true

  # move to directory of this file, so that icons can load correctly.
  Dir.chdir(File.dirname(File.expand_path(__FILE__)))

  application = FXApp.new($cfg.app.name, $cfg.app.name)
  application.threadsEnabled = true
  #application.init(ARGV)
  window =  FXMainWindow.new(application, $cfg.app.name, nil, nil, DECOR_ALL, 0, 0, $cfg.app.width, $cfg.app.height)
  FXri.new(window,FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0,0,0)
  application.create
  window.show(PLACEMENT_SCREEN)
  application.run
end
