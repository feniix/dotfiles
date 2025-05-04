# ~/.pryrc - Pry Ruby REPL Configuration
# For best results, install additional gems:
#   gem install awesome_print pry-clipboard interactive_editor pry-byebug

# === REQUIRED LIBRARIES ===
require 'date'
require 'bigdecimal'

# === BETTER OBJECT FORMATTING ===
# Make Date output more readable
class Date
  def inspect
    "#<Date: #{self}>"
  end
end

# Make BigDecimal output cleaner (without scientific notation)
class BigDecimal
  def inspect
    "#{to_s('F')}bd"
  end
end

# === UTILITY METHODS ===
# Calculate memory size of an object and its references
def sizeof(target, seen = nil)
  require 'objspace'
  require 'set'

  seen    ||= Set.new
  reachable = ObjectSpace.reachable_objects_from(target)

  reachable.reduce(ObjectSpace.memsize_of(target)) do |sum, obj|
    next sum if obj.is_a?(Module)
    next sum if seen.member?(obj.object_id)
    seen.add(obj.object_id)
    sum += sizeof(obj, seen)
  end
end

# === EDITOR CONFIGURATION ===
# Set editor for 'edit' command
Pry.config.editor = ENV['EDITOR'] || 'vim'

# === COMMAND ALIASES ===
# Make debugging workflow easier with single-letter commands
# These aliases work with pry-byebug or pry-nav
Pry.commands.alias_command 'c', 'continue' rescue nil
Pry.commands.alias_command 's', 'step' rescue nil
Pry.commands.alias_command 'n', 'next' rescue nil
Pry.commands.alias_command 'r!', 'reload!' rescue nil

# === COLOR CONFIGURATION ===
# Enable colorized output
begin
Pry.config.color = true
rescue NoMethodError
  # For newer Pry versions
  Pry.config.color_enabled = true rescue nil
end

# Use Solarized theme if possible
begin
Pry.config.theme = 'solarized'
rescue NoMethodError
  # Theme setting changed in newer Pry versions
  puts "Note: Theme setting is not available in this Pry version"
end

# === CUSTOM PROMPT ===
# This prompt shows Ruby version and context
Pry.prompt = [
  proc { |obj, nest_level, _| 
    ruby_info = RUBY_VERSION
    ruby_info += " (#{RUBY_ENGINE})" if defined?(RUBY_ENGINE)
    "#{ruby_info} [#{obj}]:#{nest_level} > " 
  }, 
  proc { |obj, nest_level, _| 
    ruby_info = RUBY_VERSION
    ruby_info += " (#{RUBY_ENGINE})" if defined?(RUBY_ENGINE)
    "#{ruby_info} [#{obj}]:#{nest_level} * " 
  }
]

# === LISTING CONFIGURATION ===
# Better colors for method listings
# Colors optimized for Solarized scheme
begin
  Pry.config.ls.separator = "\n" # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black
rescue NoMethodError, StandardError
  # Handle changes in newer Pry versions
  puts "Note: Some ls configurations are not available in this Pry version"
end

# === PLUGINS ===
# Load useful plugins with error handling

# Interactive editor
begin
  require 'interactive_editor'
rescue LoadError => e
  puts "Note: Interactive editor not available. Install with 'gem install interactive_editor'"
end

# Awesome Print for better output formatting
begin
  require 'awesome_print'
  
  # Enable awesome_print for all output, with paging
  Pry.config.print = proc do |output, value| 
    Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)
  end
rescue LoadError => e
  puts "Note: awesome_print not available. Install with 'gem install awesome_print'"
end

# Clipboard integration
begin
  require 'pry-clipboard'
  
  # Add clipboard shortcuts
  Pry.config.commands.alias_command 'ch', 'copy-history'
  Pry.config.commands.alias_command 'cr', 'copy-result'
rescue LoadError => e
  puts "Note: pry-clipboard not available. Install with 'gem install pry-clipboard'"
end

# Try to load pry-byebug for debugging if available
begin
  require 'pry-byebug'
  puts "pry-byebug loaded for debugging commands"
rescue LoadError
  # Try to load the lighter pry-nav as fallback
  begin
    require 'pry-nav'
    puts "pry-nav loaded for debugging commands"
  rescue LoadError
    puts "Note: No debugger available. Install with 'gem install pry-byebug'"
end
end

