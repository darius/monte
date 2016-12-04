Practical Security: The Mafia game
==================================

Let's look a bit deeper at Monte, working up to an implementation of
the `Mafia party game`__.

__ https://en.wikipedia.org/wiki/Mafia_%28party_game%29

Objects
-------

Monte has a simpler approach to object composition and inheritance than many
other object-based and object-oriented languages.

A Singleton Object
~~~~~~~~~~~~~~~~~~

We will start our exploration of objects with a simple singleton
object. Methods can be attached to objects with the ``to`` keyword::

  >>> object origin:
  ...     to getX():
  ...         return 0
  ...     to getY():
  ...         return 0
  ... # Now invoke the methods
  ... origin.getY()
  0

Unlike Java or Python, Monte objects are not constructed from classes.
Unlike JavaScript, Monte objects are not constructed from prototypes. As a
result, it might not be obvious at first how to build multiple objects which
are similar in behavior.

Functions are objects too
~~~~~~~~~~~~~~~~~~~~~~~~~

Functions are simply objects with a ``run`` method. There is no
difference between this function::

  >>> def square(x):
  ...     return x * x
  ... square.run(4)
  16

... and this object::

  >>> object square:
  ...     to run(x):
  ...         return x * x
  ... square(4)
  16

.. warning:: Python programmers beware, methods are not
             functions. Methods are just the public hooks to the
             object that receive messages; functions are standalone
             objects.

.. todo:: document docstrings

.. todo:: document named args, defaults

.. _maker:

Object constructors and encapsulation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Monte has a very simple idiom for class-like constructs::

  >>> def makeCounter(var value :Int):
  ...     return object counter:
  ...         to increment() :Int:
  ...             return value += 1
  ...         to makeOffsetCounter(delta :Int):
  ...             return makeCounter(value + delta)
  ...
  ... def c1 := makeCounter(1)
  ... c1.increment()
  ... def c2 := c1.makeOffsetCounter(10)
  ... c1.increment()
  ... c2.increment()
  ... [c1.increment(), c2.increment()]
  [4, 14]

And that's it. No declarations of object contents or special
references to ``this`` or ``self``.

.. sidebar:: Assignment Expressions

   Monte is an expression language.  The expression ``value += 1`` returns the
   resulting sum. That's why ``return value += 1`` works.

Inside the function ``makeCounter``, we simply define an object called
``counter`` and return it. Each time we call ``makeCounter()``, we get
a new counter object. As demonstrated by the ``makeOffsetCounter``
method, the function (``makeCounter``) can be referenced from within
its own body. (Similarly, our counter object could refer to itself in
any of its methods as ``counter``.)

The lack of a ``this`` or ``self`` keyword may be
surprising. But this straightforward use of lexical scoping saves us
the often tedious business in python or Java of copying the arguments
from the parameter list into instance variables: ``value`` is already
an instance variable.

The ``value`` passed into the function is not an ephemeral parameter
that goes out of existence when the function exits. Rather, it is a
true variable, and it persists as long as any of the objects that uses
it persist. Since the counter uses this variable, ``value`` will exist
as long as the counter exists.

.. sidebar:: Augmented Assignment

   Just as you would read ``x += 1`` short-hand for ``x := x + 1``,
   read the :ref:`augmented assignment <augmented_assignment>`
   ``players without= (victim)`` as ``players :=
   players.without(victim)`` .

A natural result is the **complete encapsulation** required for :ref:`object
capability discipline<ocap>`: ``value`` is not visible outside of
``makeCounter()``; this means that *no other object can directly observe nor
modify it*. Monte objects have no public attributes or fields or even a notion
of public and private. Instead, all names are private: if a name is not
visible (i.e. in scope), there is no way to use it.

We refer to an object-making function such as ``makeCounter`` as a
"Maker". As a more serious example, let's make a sketch of our game::

  >>> def makeMafia(var players :Set):
  ...     def mafiosoCount :Int := players.size() // 3
  ...     var mafiosos :Set := players.slice(0, mafiosoCount)
  ...     var innocents :Set := players.slice(mafiosoCount)
  ...
  ...     return object mafia:
  ...         to getWinner():
  ...             if (mafiosos.size() == 0):
  ...                 return "village"
  ...             if (mafiosos.size() >= innocents.size()):
  ...                 return "mafia"
  ...             return null
  ...
  ...         to lynch(victim):
  ...             players without= (victim)
  ...             mafiosos without= (victim)
  ...             innocents without= (victim)
  ...
  ... def game1 := makeMafia(["Alice", "Bob", "Charlie"].asSet())
  ... game1.lynch("Bob")
  ... game1.lynch("Charlie")
  ... game1.getWinner()
  "mafia"

.. _def-fun:


Traditional Datatypes and Operators
-----------------------------------

Monte includes :ref:`basic data types <basic_data>` such as ``Int``,
``Double``, ``Str``, ``Char``, and ``Bool``. All integer arithmetic is
unlimited precision, like in Python.

The operators ``+``, ``-``, and ``*`` have their traditional meanings
for ``Int`` and ``Double``. The normal division operator ``/`` always
gives you a ``Double`` result. The floor divide operator ``//`` always
gives you an ``Int``, truncated towards negative infinity. So::

  >>> -3.5 // 1
  -4

.. sidebar:: Comments

   Monte uses the same ``# ...`` syntax for comments as Python and bash.

Strings are enclosed in double quotes. Characters are enclosed in
single quotes.

The function ``traceln`` sends diagnostic output to the console. The ``if``
and ``while`` constructs look much like their Python equivalents, as do lists
such as ``[4, 14]``.

Operator precedence is generally the same as in Java, Python, or C. In
a few cases, Monte will throw a syntax error and require the use of
parentheses.

With that, let's set aside our game sketch and look at a more complete
rendition, :download:`mafia.mt<tut/mafia.mt>`:

.. literalinclude:: tut/mafia.mt
    :linenos:
    :lines: 15-17,21-127
    :lineno-start: 15


Unit Testing
~~~~~~~~~~~~

This module also uses Monte's unit test facilities to capture a simulated
game:


.. literalinclude:: tut/mafia.mt
    :linenos:
    :lines: 18-20,127-
    :lineno-start: 18

We still cannot import access to a true source of entropy; ``makePCG``
constructs a pseudo-random number generator given an initial seed, and
``makeEntropy`` makes an object that takes the resulting sequence of bytes and
packages them up conveniently as integers etc. In
:ref:`secure_distributed_computing`, we will develop the part of the game that
provides a truly random seed. But for unit testing, the seed is an arbitrarily
chosen constant.

Additional flow of control
~~~~~~~~~~~~~~~~~~~~~~~~~~

Other traditional structures include:

 - ``try{...} catch errorVariable {...} finally {...}``
 - ``throw(ExceptionExpressionThatCanBeAString)``
 - ``break``, ``continue``
 - ``switch (expression) {match pattern1 {...} match pattern2 {...}
   ... match _ {defaultAction}}``

String Interpolation with quasi-literals
----------------------------------------

Monte's :ref:`quasi-literals<quasiliteral>` enable the easy processing
of complex strings as described in detail later;
``out.print(`currently $state>`)`` is a simple example wherein the
back-ticks denote a quasi-literal, and the dollar sign denotes a
variable whose value is to be embedded in the string.

Dynamic "type checking" with guards
-----------------------------------

Monte :ref:`guards <guards>` perform many of the functions usually thought of
as type checking, though they are so flexible that they also work as concise
assertions. Guards can be placed on variables (such as ``mafiososCount
:Int``), parameters (such as ``players :Set``), and return values (such as
``getState() :MafiaState``).

Guards are not checked during compilation. They are checked during
execution and will throw exceptions if the value cannot be coerced to
pass the guard.

.. sidebar:: Optimizing Monte Compilers

    Monte does not specify a compilation model. Some guards can be optimized
    away by intelligent Monte compilers, and linters may warn about
    statically-detectable guard failures.

Monte features strong types; monte values resist automatic coercion. As an
example of strong typing in Monte, consider the following statement::

    def x := 42 + true

This statement will result in an error, because ``true`` is a boolean value
and cannot be automatically transformed into an integer, float, or other value
which integers will accept for addition.

We can also build guards at runtime. The call to ``makeEnum`` returns
a list where the first item is a new guard and the remaining items are
distinct new objects that pass the guard. No other objects pass the
guard.

.. todo:: **show**: Guards play a key role in protecting security
          properties.

Final, Var, and DeepFrozen
--------------------------

Bindings in Monte are immutable by default.

The :ref:`DeepFrozen guard <deepfrozen>` ensures that an object and everything
it refers to are immutable.  The ``def makeMafia(…) as DeepFrozen`` expression
results in this sort of binding as well as patterns such as ``DAY
:DeepFrozen``.

Using a ``var`` pattern in a definition (such as ``mafiosos``) or parameter
(such as ``players``) lets you assign to that variable again later.

There are no (mutable) global variables, however. We cannot import a random
number generator. Rather, the random number generator argument ``rng`` is
passed to the ``makeMafia`` maker function explicitly.

Assignment and Equality
-----------------------

Assignment uses the ``:=`` operator, as in Pascal. The single equal
sign ``=`` is never legal in Monte; use ``:=`` for assignment and
``==`` for testing equality.

``==`` and ``!=`` are the boolean tests for sameness. For any pair
of refs x and y, "x == y" will tell whether these refs designate
the same object. The sameness test is monotonic, meaning that the
answer it returns will not change for any given pair of objects.
Chars, booleans, integers, and floating point numbers are all
compared by their contents, as are Strings, ConstLists, and ConstMaps.
Other objects only compare same with themselves, unless their
definition declares them:ref:`Transparent<selfless>`, which lets them
expose their contents and have them compared for sameness.

Data Structures for Game Play
-----------------------------

Monte has ``Set``, ``List``, and ``Map`` data structures that let us
express the rules of the game concisely.

A game of mafia has some finite number of players. They don't come in
any particular order, though, so we write ``var players :Set`` to
ensure that ``players`` is always bound to a ``Set``,
though it may be assigned to different sets at different times.

We use ``.size()`` to get the number of players, and once we get the
``mafiosos`` subset (using a ``sample`` function), the set of ``innocents`` is
the difference of ``players - mafiosos``.

We initialize ``votes`` to the empty ``Map``, written ``[].asMap()``
and add to it using ``votes with= (player, choice)``.

To ``lynch``, we use ``counter`` as a map from player to votes cast
against that player. We initialize it to an empty mutable map with
``[].asMap().diverge()`` and then iterate over the votes with ``for _
=> v in votes:``.

Functional Features (WIP)
~~~~~~~~~~~~~~~~~~~~~~~~~

Monte has support for the various language features required for programming
in the so-called "functional" style. Monte supports closing over values (by
reference and by binding), and Monte also supports creating new function
objects at runtime. This combination of features enables functional
programming patterns.

Monte also has several features similar to those found in languages in the
Lisp and ML families which are often conflated with the functional style, like
strict lexical scoping, immutable builtin value types, comprehension syntax,
and currying for message passing.

Comprehensions in Monte are written similarly to Python's, but in keeping with
Monte's style, the syntax elements are placed in evaluation order:
``[for KEY_PATTERN => VALUE_PATTERN in (ITERABLE) if (FILTER_EXPR) ELEMENT_EXPR]``.
Just as Python has dict comprehensions, Monte provides map comprehensions --
to produce a map, ``ELEMENT_EXPR`` would be replaced with ``KEY_EXPR => VALUE_EXPR``.

A list of players that got more than a quorum of votes is written
``[for k => v in (counter) ? (v >= quorum) k]``. Provided there
is one such player, we remove the player from the
game with ``players without= (victim)``.


Destructuring with Patterns
---------------------------

:ref:`Pattern matching <patterns>` is used in the following ways in
Monte:

  1. The left-hand side of a ``def`` expression has a pattern.

     A single name is typical, but the first ``def`` expression above
     binds ``MafiaState``, ``DAY``, and ``NIGHT`` to the items from
     ``makeEnum`` using a :ref:`list pattern<ListPatt>`.

     If the match fails, an :ref:`ejector<ejector>` is fired, if
     provided; otherwise, an exception is raised.

  2. Parameters to methods are patterns which are matched against
     arguments. Match failure raises an exception.

     A :ref:`final pattern<FinalPatt>` such as ``to _printOn(out)`` or with a
     guard ``to sample(population :List)`` should look familiar, but the
     :ref:`such-that patterns <SuchThatPattern>` in ``to vote(player ?
     (players.contains(player)), ...)`` are somewhat novel. The pattern
     matches only if the expression after the ``?`` evaluates to ``true``; at
     the same time, ``player`` is usable in the such-that expression.

  3. Each matcher in a ``switch`` expression has a pattern.

     In the ``advance`` method, if ``state`` matches the ``==DAY``
     pattern--that is, if ``state == DAY``--then ``NIGHT`` is assigned
     to ``state``. Likewise for the pattern ``==NIGHT`` and the
     expression ``DAY``.

     An exception would be raised if neither pattern matched, but that
     can't happen because we have ``state :MafiaState``.

  4. Match-bind :ref:`comparisons <comparisons>` such as
     :literal:`"<p>" =~ \`<@tag>\`` test the value on the left against
     the pattern on the right, and return whether the pattern matched
     or not.

  5. Matchers in object expressions provide flexible handlers for
     :ref:`message passing <message_passing>`.

The ``[=> makeEnum]`` pattern syntax is short for ``["makeEnum" =>
makeEnum]``, which picks out the value corresponding to the key
``"makeEnum"``. The :ref:`module_expansion` section explains how
imports turn out to be a special case of method parameters.
