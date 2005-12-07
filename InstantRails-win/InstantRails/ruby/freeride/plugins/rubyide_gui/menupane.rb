# Purpose: Setup and initialize the core gui interfaces
#
# $Id: menupane.rb,v 1.3 2004/12/03 21:24:02 ljulliar Exp $
#
# Authors:  Curt Hibbs <curt@hibbs.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2001 Curt Hibbs. All rights reserved.
#

require 'rubyide_gui/component_manager'
require 'rubyide_gui/component'

module FreeRIDE
  module GUI

    ##
    # This is the manager class for menupane components. A menupane
    # contains a list of commands. Each command specified as the
    # databus path to a command component.
    #
    class MenuPane < Component
      extend FreeBASE::StandardPlugin
      
      def MenuPane.start(plugin)
        base_slot = plugin["/system/ui/components/MenuPane"]
        ComponentManager.new(plugin, base_slot, MenuPane)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      ##
      # Constructs a menupane
      #
      def initialize(plugin, base_slot)
        @count = 0
        setup(plugin, base_slot)
        @cmd_mgr = plugin["/system/ui/commands"].manager
        @key_mgr = plugin["/system/ui/keys"].manager
      end
      
      ##
      # Replaces this menupane's current command list with a new one.
      #
      def commands=(command_list)
        @base_slot.propagate_notifications = false;
        # remove any existing menuitems
        @base_slot.each_slot {|slot| slot.prune}
        @count = 0
        command_list.each do |command_path|
          add_command(command_path)
        end
        @base_slot.propagate_notifications = true;
        @base_slot.notify(:refresh) if @base_slot.attr_visible
      end
      
      def each_command
        @base_slot.each_slot do |slot|
          next if slot.name=="actions"
          if slot.data=="SEPARATOR"
            yield slot, "SEPARATOR", nil, true, nil
          else
            command = @cmd_mgr.command(slot.data)
            keys = @key_mgr.get_binding(slot.data)
            accelerator = ""
            if keys
              accelerator += "Ctl-" if keys.delete(:ctrl)
              accelerator += "Shift-" if keys.delete(:shift)
              if keys.size==1
                accelerator += keys[0].to_s
              else
                accelerator = ""
              end
            end
            yield slot, command.text, command.description, command.available?, accelerator
          end
        end
      end
      
      def enable(command_path)
        @base_slot.each_slot do |slot| 
          if slot.data == command_path
            slot.attr_enable = true unless slot.attr_enable==true
            break
          end
        end
      end
      
      def disable(command_path)
        @base_slot.each_slot do |slot| 
          if slot.data == command_path
            slot.attr_enable = false unless slot.attr_enable==false
            break
          end
        end
      end
      
      def check(command_path)
        @base_slot.each_slot do |slot| 
          if slot.data == command_path
            slot.attr_check = true unless slot.attr_check==true
            break
          end
        end
      end
      
      def uncheck(command_path)
        @base_slot.each_slot do |slot| 
          if slot.data == command_path
            slot.attr_check = false unless slot.attr_check==false
            break
          end
        end
      end
      
      ##
      # Add an new item at the end of the menupane's current command list
      #
      def add_command(command_path)
        begin
          slot = @base_slot[@count.to_s]
          slot.data = command_path
          @count += 1
          unless command_path=="SEPARATOR"
            cmd = @cmd_mgr.command(command_path)
            slot['actions/select'].set_proc {cmd.invoke}
            
            if cmd.availability_managed?
              cmd.monitor_availability do |command|
                if command.available?
                  enable(command_path) 
                else
                  disable(command_path)
                end
		# if checked is nil then don't do anything
                if command.checked? == true
                  check(command_path)
                elsif command.checked? == false
                  uncheck(command_path)
                end
              end
            end
            check(command_path) if cmd.checked?
          end
        rescue => error
          # if any exceptions, stop here!
          @plugin.log_error << "Exception in MenuPane: #{error}"
          puts $!.to_s + "\n" + $!.backtrace.join("\n")  
        ensure
          @base_slot.notify(:refresh) if @base_slot.attr_visible
        end
      end
      
    end  # class MenuPane
    
  end
end # module FreeRIDE
