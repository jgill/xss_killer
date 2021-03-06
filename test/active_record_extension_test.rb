require File.dirname(__FILE__) + "/test_helper"

class ActiveRecordExtensionTest < Test::Unit::TestCase
  def initialize(name)
    super(name)
    require 'tidy'
    Tidy.path = defined?(TIDY_PATH) ? TIDY_PATH : "/opt/local/lib/libtidy.dylib"
  end
  
  test "setting which attributes are escaped" do
    foo = Foo.new :attr_to_allow_injection => "<js>", :attr_to_kill_xss => "<js>"
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<js>", foo.attr_to_allow_injection
      assert_equal "&lt;js&gt;", foo.attr_to_kill_xss
    end
  end

  test "escaping works when inheriting" do
    foo = SubFoo.new :attr_to_allow_injection => "<js>", :attr_to_kill_xss => "<js>"
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<js>", foo.attr_to_allow_injection
      assert_equal "&lt;js&gt;", foo.attr_to_kill_xss
    end
  end

  test "derived classes can kill xss even if base class does not" do
    base = Bar.new :name => "<js>"
    derived = SubBar.new :name => "<js>"
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<js>", base.name
      assert_equal "&lt;js&gt;", derived.name
    end
  end
  
  test "models not annotated with kills_xss to do not escape html" do
    bar = Bar.new :name => "<js>"
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<js>", bar.name
    end
  end
  
  test "using sanitize" do
    link = "<p><a href=\"http://www.google.com\">google</a></p>"
    foo = Foo.new :attr_to_sanitize => "<a href='http://www.google.com'>google</a>"
    foo.stubs(:tidy_defined?).returns(false)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal link, foo.attr_to_sanitize
    end

    js = "<script></script>"
    foo = Foo.new :attr_to_sanitize => js
    foo.stubs(:tidy_defined?).returns(false)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<p></p>", foo.attr_to_sanitize
    end
  end
  
  test "if using sanitize it also uses simple_format" do
    formatted = "<p><a href=\"http://www.google.com\">google\n<br />line2</a></p>"
    foo = Foo.new :attr_to_sanitize => "<a href='http://www.google.com'>google\nline2</a>"
    foo.stubs(:tidy_defined?).returns(false)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal formatted, foo.attr_to_sanitize
    end
  end
  
  test "if using sanitize and tidy is defined it uses tidy by default" do
    formatted = "<p><a href=\"http://www.google.com\">google<br />\nline2</a></p>\n\n"
    foo = Foo.new :attr_to_sanitize => "<a href='http://www.google.com'>google\nline2"
    foo.stubs(:tidy_defined?).returns(true)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal formatted, foo.attr_to_sanitize
    end
  end
  
  test "if using sanitize and tidy is defined it uses tidy if allow_tidy option is true" do
    formatted = "<p><a href=\"http://www.google.com\">google<br />\nline2</a></p>\n\n"
    foo = TidyFoo.new :attr_to_sanitize => "<a href='http://www.google.com'>google\nline2"
    foo.stubs(:tidy_defined?).returns(true)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal formatted, foo.attr_to_sanitize
    end
  end
  
  test "if using sanitize and tidy is defined it doesn't use tidy if allow_tidy option is false" do
    formatted = "<p><a href=\"http://www.google.com\">google\n<br />line2</p>"
    foo = NoTidyFoo.new :attr_to_sanitize => "<a href='http://www.google.com'>google\nline2"
    foo.stubs(:tidy_defined?).returns(true)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal formatted, foo.attr_to_sanitize
    end
  end
  
  test "if using sanitize and tidy is not defined it doesn't use it" do
    formatted = "<p><a href=\"http://www.google.com\">google\n<br />line2</p>"
    foo = TidyFoo.new :attr_to_sanitize => "<a href='http://www.google.com'>google\nline2"
    foo.stubs(:tidy_defined?).returns(false)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal formatted, foo.attr_to_sanitize
    end
  end
  
  test "tidy has no affect on allow_injection" do
    foo = Foo.new :attr_to_allow_injection => "<js>"
    foo.stubs(:tidy_defined?).returns(true)
    XssKiller.rendering :html, ActionView::Base.new do
      assert_equal "<js>", foo.attr_to_allow_injection
    end
  end
  
  test "tidy_defined? returns true when tidy is defined" do
    foo = TidyFoo.new
    assert_equal true, foo.tidy_defined?()
  end
  
  test "tidy_defined? returns false when tidy is not defined" do
    Object.send(:remove_const, :Tidy)
    foo = TidyFoo.new                     
    assert_equal false, foo.tidy_defined?()
    # reload tidy for other tests
    Kernel.load 'tidy.rb'
    Tidy.path = defined?(TIDY_PATH) ? TIDY_PATH : "/opt/local/lib/libtidy.dylib"
  end
end
