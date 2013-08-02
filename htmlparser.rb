#!/usr/bin/ruby -w
# encoding:utf-8

module KHtmlParser
class Node
  def initialize(name)
    @name = name
    @attributes = Hash.new
  end
  
  def new_attribute(name, value)
    @attributes[name.to_sym] = value if name and not name.empty?
  end
  
  def match(conditions)
    return self if conditions.nil?
    return nil if conditions[:label_name].nil? or conditions[:label_name] != @name
    conditions.each_pair { |key, value|
      next if key.to_s == 'label_name'
      return nil if @attributes[key] != value
    }
    
    return self
  end
  
  def each
    nil
  end

  def text_content
    nil
  end

  attr_reader :name
  attr_reader :attributes
end

class OnlyContentNode < Node
  def initialize
    super('pure_content')
    @content = ''
  end
  
  def analyse(content, all_nodes_supported = nil)
    return nil if content.class == ContentStack
    content.strip!
    return nil if content.empty?
    new_node = OnlyContentNode.new
    new_node.content = content.dup
    new_node
  end

  def text_content
    @content
  end

  attr_writer :content
end

class CommentNode < Node
  def initialize(comment = nil)
    @comment = comment
    super('comment')
  end
  
  def analyse(content, all_nodes_supported = nil)
    return nil if content.class == ContentStack

    if content =~ /(^<!--)(.*)-->$/m
      comment = $2.strip
      CommentNode.new(comment)
    else
      nil
    end
  end

  def text_content
    @comment
  end

  attr_writer :comment
  
  private
  
  def stack_content(stack)
    content = ''
    stack.content_stack.each { |in_stack|
      if in_stack.class == ContentStack
        content += stack_content(in_stack)
      else
        content += in_stack
      end
    }
    
    content
  end
end

class NoContentNode < Node
  def initialize(name)
    super
  end
  
  def analyse(content, all_nodes_supported = nil)
    return nil if content.class == ContentStack

    content.strip!
    if content =~ /(^<#{@name})([^>]*)(\/?>$)/i
      new_node = NoContentNode.new(@name)
      attributes = $2
      
      if attributes
        position = 1
        while true do
          each_attribute = attributes.match(/([^=]+)=\"([^\"]*)\"/, position)
          if each_attribute.nil?
            break
          end

          position += each_attribute[0].size
          attr_pair = each_attribute[0].dup
          attr_pair.strip!
          if attr_pair =~ /([^=]+)=\"([^\"]*)\"/
            new_node.new_attribute($1, $2)
          else
            # The forward slash front of > will be matched as a attribute
            STDERR << "WARNING:Invalid html content:#{content}\n" if attr_pair != '/'
          end
        end
      end
      new_node
    else
      nil
    end
  end
end

class CompositeNode < Node
  def initialize(name)
    super(name)
    @sub_nodes = []
    @content_stack = nil
  end
  
  def analyse(content_stack, all_nodes_supported)
    return nil if content_stack.class != ContentStack
    content = content_stack.content_stack[0]

    new_node = analyse_myself(content, all_nodes_supported)
    if new_node
      # push all contents
      @content_stack = content_stack.content_stack
      @content_stack[0..0] = []
      @content_stack[-1..-1] = []
      new_node.append_content(@content_stack)
      new_node
    else
      nil
    end
  end
  
  def append_content(content_stack)
    @content_stack = content_stack
  end
  
  def each
    @sub_nodes.each
  end
  
  def search_node(conditions)
    result = []
    analyse_content
    
    @sub_nodes.each do |node|
      result << node if node.match(conditions)
    end
    
    result
  end
  
  def debug_display_sub_nodes
    analyse_content
    puts "all nodes in #{name}"
    @sub_nodes.each do |node|
      puts "sub_node:#{node.name}, #{node.attributes[:id]}, #{node.attributes[:style]}"
    end
  end

  def text_content
    analyse_content
    all_text = ''
    @sub_nodes.each do |node|
      all_text += node.text_content
    end
    all_text
  end

  attr_writer :all_nodes_supported

  private

  def analyse_myself(label, all_nodes_supported)
    return nil if not label =~ /^<#{@name}/

    label.strip!
    if label =~ /(^<#{@name})([^>]*)(>)(.*)/i
      new_node = CompositeNode.new(@name)
      new_node.all_nodes_supported = all_nodes_supported
      attributes = $2
      if attributes
        position = 1
        while true do
          each_attribute = attributes.match(/([^=]+)=[\"\']([^\"\']*)[\"\']/, position)
          if each_attribute.nil?
            break
          end

          position += each_attribute[0].size
          attr_pair = each_attribute[0].dup
          attr_pair.strip!
          if attr_pair =~ /([^=]+)=[\"\']([^\"\']*)[\"\']/
            new_node.new_attribute($1, $2)
          else
            # The forward slash front of > will be matched as a attribute
            STDERR << "WARNING:Invalid html content:#{content}\n" if attr_pair != '/'
          end
        end
      end
      new_node
    else
      nil
    end
  end
  
  def add_sub_node(node)
    @sub_nodes << node if node
  end

  def analyse_content
    return if @content_stack.nil? or @content_stack.empty?
    
    @content_stack.each { |in_stack|
      @all_nodes_supported.each { |supported|
        sub_node = supported.analyse(in_stack, @all_nodes_supported)
        if sub_node
          add_sub_node(sub_node)
          break
        end
      }
    }

    @content_stack.clear
  end
end

class GlobalNode < CompositeNode
  def initialize
    super('global')
  end
  
  def analyse(content_stack, all_nodes_supported)
    all_nodes_supported.each { |supported|
      sub_node = supported.analyse(content_stack, all_nodes_supported)
      if sub_node
        @sub_nodes << sub_node
        break
      end
    }
  end
  
  def search_node(conditions)
    result = []
    
    @sub_nodes.each { |node|
      result << node if node.match(conditions)
    }
    
    result
  end
end

class ContentStack
  def initialize(content_stack = nil)
    @content_stack = []
    @content_stack = content_stack if content_stack
  end

  def analyse(char_iterator)
    label_stack = []
    stack = []
    loop do
      char = char_iterator.next
      if char == '<'
        build_label(stack, label_stack)
        stack.clear
        stack.push(char)
      elsif char == '>'
        stack.push(char)
        build_label(stack, label_stack)
        stack.clear
      else
        stack.push(char)
      end
    end
    build_label(stack, label_stack)
    build_stack(label_stack)
  end
  
  def each
    return @content_stack.each if not block_given?
    @content_stack.each { |content|
      yield content
    }
  end
  
  def empty?
    @content_stack.empty?
  end
  
  def clear
    @content_stack.clear
  end
  
  attr_reader :content_stack
  
  private
  def build_label(stack, label_stack)
    label = ''
    stack.each { |char|
      label += char
    }

    label.strip!
    return if label.empty?

    maybe_comment = label_stack[-1]
    if maybe_comment =~ /^<!--/
      if not maybe_comment =~ /-->$/
        maybe_comment += label
        label_stack[-1] = maybe_comment
        return
      end
    end

    label_stack.push(label)
  end
  
  def build_stack(label_stack)
    label_stack.each { |label|
      if label =~ /^<\/([^>]+)>$/
        label_name = $1
        stack_clone = @content_stack.dup
        @content_stack.push(label)
        inner_stack = []
        loop do
          in_stack = @content_stack.pop
          break if in_stack.nil?

          inner_stack[0, 0] = in_stack
          if in_stack =~ /^<#{label_name}/
            @content_stack.push(ContentStack.new(inner_stack))
            break
          end

          if @content_stack.empty?
            STDERR << 'Mismatched label:' << label
            @content_stack = stack_clone
            break
          end
        end
      else
        @content_stack.push(label)
      end
    }
  end
end

class HTMLParser
  def initialize
    @all_nodes_supported = []
    #<!DOCTYPE>
    @all_nodes_supported << NoContentNode.new('!DOCTYPE')
    #<!-->
    @all_nodes_supported << CommentNode.new
    #<abbr></abbr>
    @all_nodes_supported << CompositeNode.new('abbr')
    #<acronym></acronym>
    @all_nodes_supported << CompositeNode.new('acronym')
    #<address></address>
    @all_nodes_supported << CompositeNode.new('address')
    #<applet></applet>
    @all_nodes_supported << CompositeNode.new('applet')
    #<area />
    @all_nodes_supported << NoContentNode.new('area')
    #<a></a>
    @all_nodes_supported << CompositeNode.new('a')
    #<base />
    @all_nodes_supported << NoContentNode.new('base')
    #<basefont />
    @all_nodes_supported << NoContentNode.new('basefont')
    #<bdo></bdo>
    @all_nodes_supported << CompositeNode.new('bdo')
    #<big></big>
    @all_nodes_supported << CompositeNode.new('big')
    #<blockquote></blockquote>
    @all_nodes_supported << CompositeNode.new('blockquote')
    #<body></body>
    @all_nodes_supported << CompositeNode.new('body')
    #<br />
    @all_nodes_supported << NoContentNode.new('br')
    #<b></b>
    @all_nodes_supported << CompositeNode.new('b')
    #<button /> <button></button>
    @all_nodes_supported << CompositeNode.new('button')
    #<caption></caption>
    @all_nodes_supported << CompositeNode.new('caption')
    #<center></center>
    @all_nodes_supported << CompositeNode.new('center')
    #<cite></cite>
    @all_nodes_supported << CompositeNode.new('cite')
    #<code></code>
    @all_nodes_supported << CompositeNode.new('code')
    #<col />
    @all_nodes_supported << NoContentNode.new('col')
    #<colgroup></colgroup>
    @all_nodes_supported << CompositeNode.new('colgroup')
    #<dd></dd>
    @all_nodes_supported << CompositeNode.new('dd')
    #<del></del>
    @all_nodes_supported << CompositeNode.new('del')
    #<dfn></dfn>
    @all_nodes_supported << CompositeNode.new('dfn')
    #<dir></dir>
    @all_nodes_supported << CompositeNode.new('dir')
    #<div></div>
    @all_nodes_supported << CompositeNode.new('div')
    #<dl></dl>
    @all_nodes_supported << CompositeNode.new('dl')
    #<dt></dt>
    @all_nodes_supported << CompositeNode.new('dt')
    #<em></em>
    @all_nodes_supported << CompositeNode.new('em')
    #<fieldset></fieldset>
    @all_nodes_supported << CompositeNode.new('fieldset')
    #<font></font>
    @all_nodes_supported << CompositeNode.new('font')
    #<form></form>
    @all_nodes_supported << CompositeNode.new('form')
    #<frame />
    @all_nodes_supported << NoContentNode.new('frame')
    #<frameset></frameset>
    @all_nodes_supported << CompositeNode.new('frameset')
    #<head></head>
    @all_nodes_supported << CompositeNode.new('head')
    #<h1></h1>
    @all_nodes_supported << CompositeNode.new('h1')
    @all_nodes_supported << CompositeNode.new('h2')
    @all_nodes_supported << CompositeNode.new('h3')
    @all_nodes_supported << CompositeNode.new('h4')
    @all_nodes_supported << CompositeNode.new('h5')
    @all_nodes_supported << CompositeNode.new('h6')
    #<hr />
    @all_nodes_supported << NoContentNode.new('hr')
    #<html></html>
    @all_nodes_supported << CompositeNode.new('html')
    #<iframe></iframe>
    @all_nodes_supported << CompositeNode.new('iframe')
    #<img />
    @all_nodes_supported << NoContentNode.new('img')
    #<input />
    @all_nodes_supported << NoContentNode.new('input')
    #<ins></ins>
    @all_nodes_supported << CompositeNode.new('ins')
    #<i></i>
    @all_nodes_supported << CompositeNode.new('i')
    #<kbd></kbd>
    @all_nodes_supported << CompositeNode.new('kbd')
    #<label></label>
    @all_nodes_supported << CompositeNode.new('label')
    #<legend></legend>
    @all_nodes_supported << CompositeNode.new('legend')
    #<link />
    @all_nodes_supported << NoContentNode.new('link')
    #<li></li>
    @all_nodes_supported << CompositeNode.new('li')
    #<map></map>
    @all_nodes_supported << CompositeNode.new('map')
    #<menu></menu>
    @all_nodes_supported << CompositeNode.new('menu')
    #<meta />
    @all_nodes_supported << NoContentNode.new('meta')
    #<noframes />
    @all_nodes_supported << NoContentNode.new('noframes')
    #<noscript />
    @all_nodes_supported << NoContentNode.new('noscript')
    #<object></object>
    @all_nodes_supported << CompositeNode.new('object')
    #<ol></ol>
    @all_nodes_supported << CompositeNode.new('ol')
    #<optgroup></optgroup>
    @all_nodes_supported << CompositeNode.new('optgroup')
    #<option></option>
    @all_nodes_supported << CompositeNode.new('option')
    #<param />
    @all_nodes_supported << NoContentNode.new('param')
    #<pre> <pre></pre>
    @all_nodes_supported << CompositeNode.new('pre')
    #<p></p>
    @all_nodes_supported << CompositeNode.new('p')
    #<q></q>
    @all_nodes_supported << CompositeNode.new('q')
    #<samp></samp>
    @all_nodes_supported << CompositeNode.new('samp')
    #<script></script>
    @all_nodes_supported << CompositeNode.new('script')
    #<select></select>
    @all_nodes_supported << CompositeNode.new('select')
    #<small></small>
    @all_nodes_supported << CompositeNode.new('small')
    #<span></span>
    @all_nodes_supported << CompositeNode.new('span')
    #<strick></strick>
    @all_nodes_supported << CompositeNode.new('strick')
    #<strong></strong>
    @all_nodes_supported << CompositeNode.new('strong')
    #<style></style>
    @all_nodes_supported << CompositeNode.new('style')
    #<sub></sub>
    @all_nodes_supported << CompositeNode.new('sub')
    #<sup></sup>
    @all_nodes_supported << CompositeNode.new('sup')
    #<s></s>
    @all_nodes_supported << CompositeNode.new('s')
    #<table></table>
    @all_nodes_supported << CompositeNode.new('table')
    #<tbody></tbody>
    @all_nodes_supported << CompositeNode.new('tbody')
    #<td></td>
    @all_nodes_supported << CompositeNode.new('td')
    #<textarea></textarea>
    @all_nodes_supported << CompositeNode.new('textarea')
    #<tfoot></tfoot>
    @all_nodes_supported << CompositeNode.new('tfoot')
    #<thread></thead>
    @all_nodes_supported << CompositeNode.new('thead')
    #<th></th>
    @all_nodes_supported << CompositeNode.new('th')
    #<title></title>
    @all_nodes_supported << CompositeNode.new('title')
    #<tr></tr>
    @all_nodes_supported << CompositeNode.new('tr')
    #<tt></tt>
    @all_nodes_supported << CompositeNode.new('tt')
    #<ul></ul>
    @all_nodes_supported << CompositeNode.new('ul')
    #<u></u>
    @all_nodes_supported << CompositeNode.new('u')
    #<var></var>
    @all_nodes_supported << CompositeNode.new('var')
    #It must be pure string if nothing above matched
    @all_nodes_supported << OnlyContentNode.new
  end
  
  def parse(content)
    return nil if content.empty?
    stack = ContentStack.new
    stack.analyse(content.each_char)
    @root = GlobalNode.new
    stack.each { |in_stack|
      @root.analyse(in_stack, @all_nodes_supported)
    }

  end
  
  def search_node(conditions)
    @root.search_node(conditions)
  end
  
  attr_reader :all_nodes_supported, :root
end
end