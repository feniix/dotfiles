require 'date'
require 'bigdecimal'

class Date
  def inspect
    "#<Date: #{self}>"
  end
end

class BigDecimal
  def inspect
    "#{to_s('F')}bd"
  end
end

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

# === EDITOR ===
Pry.editor = 'vim'

# == Pry-Nav - Using pry as a debugger ==
Pry.commands.alias_command 'c', 'continue' rescue nil
Pry.commands.alias_command 's', 'step' rescue nil
Pry.commands.alias_command 'n', 'next' rescue nil
Pry.commands.alias_command 'r!', 'reload!' rescue nil

Pry.config.color = true
Pry.config.theme = 'solarized'

# === CUSTOM PROMPT ===
# This prompt shows the ruby version (useful for RVM)
Pry.prompt = [proc { |obj, nest_level, _| "#{RUBY_VERSION} (#{obj}):#{nest_level} > " }, proc { |obj, nest_level, _| "#{RUBY_VERSION} (#{obj}):#{nest_level} * " }]

# === Listing config ===
# Better colors - by default the headings for methods are too
# similar to method name colors leading to a "soup"
# These colors are optimized for use with Solarized scheme
# for your terminal
Pry.config.ls.separator = '\n' # new lines between methods
Pry.config.ls.heading_color = :magenta
Pry.config.ls.public_method_color = :green
Pry.config.ls.protected_method_color = :yellow
Pry.config.ls.private_method_color = :bright_black

# == PLUGINS ===
# awesome_print gem: great syntax colorized printing
# look at ~/.aprc for more settings for awesome_print
begin
  require 'interactive_editor'
rescue LoadError
  warn 'can\'t load gem "gem install interactive_editor"'
end

begin
  require 'rubygems'
  require 'awesome_print'
#  require 'awesome_print_colors'

rescue LoadError
  warn 'can\'t load gem "gem install awesome_print"'
end

begin
  require 'pry-clipboard'
  # aliases
  Pry.config.commands.alias_command 'ch', 'copy-history'
  Pry.config.commands.alias_command 'cr', 'copy-result'
rescue LoadError
  warn 'can\'t load gem "gem install pry-clipboard"'
end

# The following line enables awesome_print for all pry output,
# and it also enables paging
Pry.config.print = proc { |output, value| Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output) }

