# Copyright (c) Twisted Matrix Laboratories.
# See LICENSE for details.
import textwrap

from twisted.trial import  unittest
from ometa.runtime import ParseError
from monte.compiler import ecompile, CompileError

class CompilerTest(unittest.TestCase):
    maxDiff = None
    def eq_(self, esrc, pysrc):
        self.assertMultiLineEqual(ecompile(textwrap.dedent(esrc).strip()),
                                  textwrap.dedent(pysrc).strip())

    def test_literal(self):
        self.assertEqual(ecompile("1"), "1")
        self.assertEqual(ecompile('"foo"'), "u'foo'")
        self.assertEqual(ecompile("'x'"), "_monte.Character('x')")
        self.assertEqual(ecompile("100_312"), "100312")
        self.assertEqual(ecompile('"\\u0061"'), "u'a'")

    # def test_noun(self):
    #     self.assertEqual(ecompile("foo"), "foo")
    #     self.assertEqual(ecompile('::"if"'), "_m_if")
    #     self.assertEqual(ecompile('_m_if'), "_m__m_if")
    #     self.assertEqual(ecompile('::"hello world!"'), "_m_hello_world_")

    def test_call(self):
        self.eq_("def x := 1; x.baz(2)",
                 """
                 x = 1
                 x.baz(2)
                 """)

    def test_def(self):
        self.eq_("def x := 1",
        """
        x = 1
        x
        """)

    def test_var(self):
        self.eq_("var x := 1",
        """
        x = 1
        x
        """)

    def test_assign(self):
        self.eq_(
            "var x := 1; x := 2",
            """
            x = 1
            x = 2
            x
            """)
        self.assertRaises(CompileError, ecompile, "def x := 1; x := 2")
        self.assertRaises(CompileError, ecompile, "x := 2")

    def test_guardpattern(self):
        self.eq_("def x :float64 := 1",
                 """
                 x = _monte.float64.coerce(1, _monte.throw)
                 x
                 """)

    def test_listpattern(self):
        self.eq_('def [x :float64, y :String, z] := "foo"',
                 """
                 _g_total_list1 = u'foo'
                 try:
                     _g_list2, _g_list3, _g_list4 = _g_total_list1
                 except ValueError, _g_e5:
                     _monte.throw(_g_e5)
                 x = _monte.float64.coerce(_g_list2, _monte.throw)
                 y = _monte.String.coerce(_g_list3, _monte.throw)
                 z = _g_list4
                 _g_total_list1
                 """)

        self.eq_('def ej := 1; def [x :float64, y :String, z] exit ej := "foo"',
                 """
                 ej = 1
                 _g_total_list1 = u'foo'
                 try:
                     _g_list2, _g_list3, _g_list4 = _g_total_list1
                 except ValueError, _g_e5:
                     ej(_g_e5)
                 x = _monte.float64.coerce(_g_list2, ej)
                 y = _monte.String.coerce(_g_list3, ej)
                 z = _g_list4
                 _g_total_list1
                 """)
        # self.eq_("def [x, y, z] + blee := foo.baz(a)",
        #          """
        #          _g_total_list1 = foo.baz(a)
        #          try:
        #              _g_list2, _g_list3, _g_list4 = _g_total_list1
        #          except ValueError, _g_e5:
        #              ej(_g_e5)
        #          x = _monte.float64.coerce(_g_list2, _monte.throw)
        #          y = _monte.String.coerce(_g_list3, _monte.throw)
        #          z = _g_list4
        #          _g_total_list1
        #          """)

    def test_trivialObject(self):
        self.eq_(
            'def foo { method baz(x, y) { x }}',
             """
             class _m_foo_Script(_monte.MonteObject):
                 def baz(foo, x, y):
                     return x

             foo = _m_foo_Script()
             foo
             """)

    def test_trivialNestedObject(self):
        self.eq_(
            '''
            def foo {
                method baz(x, y) {
                    def boz {
                        method blee() { 1 }
                    }
                }
            }''',
             """
             class _m_boz_Script(_monte.MonteObject):
                 def blee(boz):
                     return 1

             class _m_foo_Script(_monte.MonteObject):
                 def baz(foo, x, y):
                     boz = _m_boz_Script()
                     return boz

             foo = _m_foo_Script()
             foo
             """)

    def test_frameFinal(self):
        self.eq_(
            '''
            def foo {
                method baz(x, y) {
                    def a := 2
                    def boz {
                        method blee() { a + x }
                    }
                }
            }''',
             """
             class _m_boz_Script(_monte.MonteObject):
                 def __init__(boz, a, x):
                     boz.a = a
                     boz.x = x

                 def blee(boz):
                     return boz.a.add(boz.x)

             class _m_foo_Script(_monte.MonteObject):
                 def baz(foo, x, y):
                     a = 2
                     boz = _m_boz_Script(a, x)
                     return boz

             foo = _m_foo_Script()
             foo
             """)

    def test_function(self):
        self.eq_(
            '''
            def foo(x) {
                return 1
            }
            ''',
            """
            class _m_foo_Script(_monte.MonteObject):
                def run(foo, x):
                    __return = _monte.ejector("__return")
                    try:
                        __return(1)
                        _g_escape2 = None
                    except __return._m_type, _g___return1:
                        _g_escape2 = _g___return1
                    return _g_escape2

            foo = _m_foo_Script()
            foo
            """
            # """
            # class _m_foo_Script(_monte.MonteObject):
            #     def run(self, x):
            #         return 1
            # """
        )

    def test_unusedEscape(self):
        self.eq_(
            '''
            var x := 1
            escape e {
                x := 2
            } catch e {
                x := 3
            }
            ''',
            """
            x = 1
            x = 2
            x
            """)