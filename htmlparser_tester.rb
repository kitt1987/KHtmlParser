#!/usr/bin/ruby -w
# encoding:utf-8

require './htmlparser'
require 'test/unit'
include KHtmlParser

class NoContentNodeTester < Test::Unit::TestCase
  def test_multi_line_comment
    content = '<!--start
    this is comment
    end-->'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'comment'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('comment', new_node.name)
    assert_equal("start\n    this is comment\n    end", new_node.comment)
  end

  def test_analyse_a_node_without_attribute_in_html
    content = '<br>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'br'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('br', new_node.name)
    assert_equal(0, new_node.attributes.size)
  end

  def test_analyse_a_node_without_attribute_in_xhtml
    content = '<br />'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'br'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('br', new_node.name)
    assert_equal(0, new_node.attributes.size)
  end

  def test_analyse_a_node_with_an_attribute
    content = '<frame src="frame_a.htm" />'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'frame'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('frame', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('frame_a.htm', new_node.attributes[:src])
  end

  def test_analyse_a_node_with_2_attributes
    content = '<meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1" />'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'meta', :'http-equiv' => 'Content-Type', :content => 'text/html;charset=ISO-8859-1'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('meta', new_node.name)
    assert_equal(2, new_node.attributes.size)
    assert_equal('Content-Type', new_node.attributes[:"http-equiv"])
    assert_equal('text/html;charset=ISO-8859-1', new_node.attributes[:content])
  end

  def test_analyse_a_multi_line_node
    content = '<meta http-equiv="Content-Type" 
    content="text/html;
    charset=ISO-8859-1" />'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'meta', :'http-equiv' => 'Content-Type', :content => "text/html;\n    charset=ISO-8859-1"})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('meta', new_node.name)
    assert_equal(2, new_node.attributes.size)
    assert_equal('Content-Type', new_node.attributes[:"http-equiv"])
    assert_equal("text/html;\n    charset=ISO-8859-1", new_node.attributes[:content])
  end
end

class CompositeNodeTester < Test::Unit::TestCase
  def test_an_empty_composite_node
    content = '<table border="1"></table>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'table', :border => '1'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('table', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('1', new_node.attributes[:border])
  end

  def test_an_empty_composite_node_devided_into_two_lines
    content =
    '<table border="1">
    </table>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'table', :border => '1'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('table', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('1', new_node.attributes[:border])
  end
 
  def test_a_composite_node_with_a_sub_node_in_a_line
    content = '<table border="2"><table border="1"></table></table>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'table', :border => '2'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('table', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('2', new_node.attributes[:border])
    result = new_node.search_node({:label_name => 'table', :border => '1'})
    assert_equal(1, result.size)
    sub_node = result[0]
    assert_equal('table', sub_node.name)
    assert_equal(1, sub_node.attributes.size)
    assert_equal('1', sub_node.attributes[:border])
  end

  def test_a_composite_node_with_a_sub_node_in_multiple_lines
    content =
    '<table border="2">
      <table border="1"></table>
    </table>'

    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'table', :border => '2'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('table', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('2', new_node.attributes[:border])
    result = new_node.search_node({:label_name => 'table', :border => '1'})
    assert_equal(1, result.size)
    sub_node = result[0]
    assert_equal('table', sub_node.name)
    assert_equal(1, sub_node.attributes.size)
    assert_equal('1', sub_node.attributes[:border])
  end

  def test_a_composite_node_with_only_content
    content =
    '<table border="1">
      sample table
    </table>'

    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'table', :border => '1'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('table', new_node.name)
    assert_equal(1, new_node.attributes.size)
    assert_equal('1', new_node.attributes[:border])
    result = new_node.search_node({:label_name => 'pure_content'})
    assert_equal(1, result.size)
    sub_node = result[0]
    assert_equal('sample table', sub_node.content)
  end

  def test_failed_sample_of_meta
    content = '<meta http-equiv="Content-Type" content="text/html; charset=gb2312">'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'meta', :'http-equiv' => 'Content-Type', :content => 'text/html; charset=gb2312'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('meta', new_node.name)
    assert_equal(2, new_node.attributes.size)
    assert_equal('Content-Type', new_node.attributes[:"http-equiv"])
    assert_equal('text/html; charset=gb2312', new_node.attributes[:content])
  end

  def test_failed_sample_of_td
    content = '<td>&nbsp;|&nbsp;<br />&nbsp;</td>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'td'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('td', new_node.name)
    assert_equal(0, new_node.attributes.size)
    result = new_node.search_node({:label_name => 'pure_content'})
    assert_equal(2, result.size)
    assert_equal('&nbsp;|&nbsp;', result[0].content)
    assert_equal('&nbsp;', result[1].content)
    result = new_node.search_node({:label_name => 'br'})
    assert_equal(1, result.size)
  end

  def test_failed_sample_of_a
    content = '<a href="http://search.51job.com/jobsearch/index.php?lang=c&stype=1">关键字搜索</a><br />&nbsp;'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'a'})
    assert_equal(1, result.size)
    assert_equal('a', result[0].name)
    assert_equal(1, result[0].attributes.size)
    assert_equal('http://search.51job.com/jobsearch/index.php?lang=c&stype=1', result[0].attributes[:href])
    result = result[0].search_node({:label_name => 'pure_content'})
    assert_equal(1, result.size)
    assert_equal('关键字搜索', result[0].content)
    result = html_parser.search_node({:label_name => 'br'})
    assert_equal(1, result.size)
    assert_equal('br', result[0].name)
    result = html_parser.search_node({:label_name => 'pure_content'})
    assert_equal(1, result.size)
    assert_equal('&nbsp;', result[0].content)
  end
  
  def test_stack_failed_sample_of_comment
    content = '<!--<embed src="http://img01.51jobcdn.com/im/2009/logo/logo51.swf" quality="high" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" width="215" height="65" wmode="transparent"></embed>-->'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'comment'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    assert_equal('<embed src="http://img01.51jobcdn.com/im/2009/logo/logo51.swf" quality="high" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" width="215" height="65" wmode="transparent"></embed>',
      new_node.comment)
  end
  
  def test_stack_failed_sample_of_div_with_single_quote
    content = '<div id=\'container\' style="margin-top:0px;"><div id=\'content\'></div></div>'
    html_parser = HTMLParser.new
    html_parser.parse(content)
    result = html_parser.search_node({:label_name => 'div', :id => 'container'})
    assert_equal(1, result.size)
    new_node = result[0]
    assert_not_nil(new_node)
    result = new_node.search_node({:label_name => 'div', :id => 'content'})
    assert_equal(1, result.size)
  end
end

class ContentStackTester < Test::Unit::TestCase
  def test_stack
    content = '<html>
      <table>
        <div>
          <a></a>
          <br />
          abcdefghight
        </div>
      </table>
    </html>'
=begin
  stack[0] = an array
  stack[0][0] = '<html>'
  stack[0][1] = an array
    stack[0][1][0] = '<table>'
    stack[0][1][1] = an array
    stack[0][1][0] = '</table>'
  stack[0][2] = '</html>  '
=end
    stack = ContentStack.new
    stack.analyse(content.each_char)
    assert_equal(1, stack.content_stack.size)
    o = stack.content_stack[0]
    assert_equal(3, o.content_stack.size)
    assert_equal('<html>', o.content_stack[0])
    assert_equal('</html>', o.content_stack[2])
    o = o.content_stack[1]
    assert_equal(3, o.content_stack.size)
    assert_equal('<table>', o.content_stack[0])
    assert_equal('</table>', o.content_stack[2])
    o = o.content_stack[1]
    assert_equal(5, o.content_stack.size)
    assert_equal('<div>', o.content_stack[0])
    assert_equal('<br />', o.content_stack[2])
    assert_equal('abcdefghight', o.content_stack[3])
    assert_equal('</div>', o.content_stack[4])
    o = o.content_stack[1]
    assert_equal(2, o.content_stack.size)
    assert_equal('<a>', o.content_stack[0])
    assert_equal('</a>', o.content_stack[1])
  end
  
  def test_stack_failed_sample
    content = '<a href="http://search.51job.com/jobsearch/index.php?lang=c&stype=1">关键字搜索</a><br />&nbsp;'
    stack = ContentStack.new
    stack.analyse(content.each_char)
    assert_equal(3, stack.content_stack.size)
    assert_equal('<br />', stack.content_stack[1])
    assert_equal('&nbsp;', stack.content_stack[2])
    o = stack.content_stack[0]
    assert_equal(3, o.content_stack.size)
    assert_equal('<a href="http://search.51job.com/jobsearch/index.php?lang=c&stype=1">', o.content_stack[0])
    assert_equal('关键字搜索', o.content_stack[1])
    assert_equal('</a>', o.content_stack[2])
  end
  
  def test_stack_failed_comment
    content = '<!--<embed src="http://img01.51jobcdn.com/im/2009/logo/logo51.swf" quality="high" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" width="215" height="65" wmode="transparent"></embed>-->'
    stack = ContentStack.new
    stack.analyse(content.each_char)
    assert_equal(1, stack.content_stack.size)
  end
  
  def test_stack_failed_composite_mismatch
    #content = '<div class="grayline" id="announcementbody"><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/beijing">北京招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shanghai">上海招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/guangzhou">广州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shenzhen">深圳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/baotou">包头招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shijiazhuang">石家庄招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/tianjin">天津招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/taiyuan">太原招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huhhot">呼和浩特招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/baoding">保定招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/langfang">廊坊招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qinhuangdao">秦皇岛招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/tangshan">唐山招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changchun">长春招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/dalian">大连招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shenyang">沈阳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/harbin">哈尔滨招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jilin">吉林招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanjing">南京招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanchang">南昌招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/ningbo">宁波招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nantong">南通招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changzhou">常州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qingdao">青岛招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/quanzhou">泉州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/suzhou">苏州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shaoxing">绍兴招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/fuzhou">福州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/tz">台州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuxi">无锡招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wenzhou">温州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hangzhou">杭州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hefei">合肥招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiamen">厦门招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xuzhou">徐州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jinan">济南招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiaxing">嘉兴招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jinhua">金华招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yantai">烟台招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yangzhou">扬州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/kunshan">昆山招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhangzhou">漳州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhenjiang">镇江招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/linyi">临沂招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuhu">芜湖招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/weifang">潍坊招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/weihai">威海招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiangyin">江阴招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changshu">常熟招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhangjiagang">张家港招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yancheng">盐城招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/lianyungang">连云港招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huaian">淮安招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/taizhou">泰州招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/huzhou">湖州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yiwu">义乌招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zibo">淄博招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jining">济宁招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanning">南宁招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changsha">长沙招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/dongguan">东莞招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/sanya">三亚招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuhan">武汉招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhengzhou">郑州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhongshan">中山招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhuhai">珠海招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/haikou">海口招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/foshan">佛山招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huizhou">惠州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiangmen">江门招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shantou">汕头招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/luoyang">洛阳招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/yichang">宜昌招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiangyang">襄阳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jingzhou">荆州招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhuzhou">株洲招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hengyang">衡阳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiangtan">湘潭招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changde">常德招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhanjiang">湛江招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qingyuan">清远招聘</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/shunde">顺德招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/chengdu">成都招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/chongqing">重庆招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/guiyang">贵阳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/kunming">昆明招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/mianyang">绵阳招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/urumqi">乌鲁木齐招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xian">西安招聘</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/lanzhou">兰州招聘</a></li></ul></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/beijing">北京人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shanghai">上海人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/guangzhou">广州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shenzhen">深圳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/baotou">包头人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shijiazhuang">石家庄人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/tianjin">天津人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/taiyuan">太原人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huhhot">呼和浩特人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/baoding">保定人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/langfang">廊坊人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qinhuangdao">秦皇岛人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/tangshan">唐山人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changchun">长春人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/dalian">大连人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shenyang">沈阳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/harbin">哈尔滨人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jilin">吉林人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanjing">南京人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanchang">南昌人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/ningbo">宁波人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/nantong">南通人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changzhou">常州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qingdao">青岛人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/quanzhou">泉州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/suzhou">苏州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shaoxing">绍兴人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/fuzhou">福州人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/tz">台州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuxi">无锡人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wenzhou">温州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hangzhou">杭州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hefei">合肥人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiamen">厦门人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xuzhou">徐州人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/jinan">济南人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiaxing">嘉兴人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jinhua">金华人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yantai">烟台人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yangzhou">扬州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/kunshan">昆山人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhangzhou">漳州人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhenjiang">镇江人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/linyi">临沂人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuhu">芜湖人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/weifang">潍坊人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/weihai">威海人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiangyin">江阴人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changshu">常熟人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhangjiagang">张家港人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yancheng">盐城人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/lianyungang">连云港人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huaian">淮安人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/taizhou">泰州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huzhou">湖州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yiwu">义乌人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/zibo">淄博人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jining">济宁人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/nanning">南宁人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changsha">长沙人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/dongguan">东莞人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/sanya">三亚人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/wuhan">武汉人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhengzhou">郑州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhongshan">中山人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhuhai">珠海人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/haikou">海口人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/foshan">佛山人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/huizhou">惠州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jiangmen">江门人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/shantou">汕头人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/luoyang">洛阳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/yichang">宜昌人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiangyang">襄阳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/jingzhou">荆州人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhuzhou">株洲人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/hengyang">衡阳人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/xiangtan">湘潭人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/changde">常德人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/zhanjiang">湛江人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/qingyuan">清远人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/shunde">顺德人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/chengdu">成都人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/chongqing">重庆人才网</a></li></ul><ul><li style="font-weight: bold; font-size: 14px; color: rgb(102, 102, 102);">地区人才网招聘</li><li class="st_one"><a target="_blank" href="http://www.51job.com/guiyang">贵阳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/kunming">昆明人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/mianyang">绵阳人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/urumqi">乌鲁木齐人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/xian">西安人才网</a></li><li class="st_one"><a target="_blank" href="http://www.51job.com/lanzhou">兰州人才网</a></li></ul>	</div>'
    content = '<div><ul></ul></ul></div>'
    stack = ContentStack.new
    stack.analyse(content.each_char)
    assert_equal(1, stack.content_stack.size)
  end
end

class SearchNodeTester < Test::Unit::TestCase
  def test_search_a_node
    content = '<div id="all-channel" align="left"  style="overflow:hidden;border:#82868D solid 1px; font-size:12px;width:470px;display:none;z-index:999;background:url(http://img01.51jobcdn.com/im/2009/my/folder/gray_bg02.gif) repeat-x;" ></div>'
    parser = HTMLParser.new
    parser.parse(content)
    assert_equal(1, parser.root.search_node({:label_name => 'div', :id => 'all-channel'}).size)
  end
end