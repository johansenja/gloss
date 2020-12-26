class MyClass
  def int : Integer
    "abc"
  end

  def sym : Symbol
    :abc
  end
end

mc = MyClass.new

5 + mc.sym + mc.int
