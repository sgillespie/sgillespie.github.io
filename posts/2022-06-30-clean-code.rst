---
title: Functional Clean Code
---

Functional Clean Code: Applying Clean Code to Functional Programming
====================================================================

Clean Code, by Robert C Martin, is known to be one of the best resources on principals,
patterns and practices of writing clean, maintainable code.  Unfortunately this was
written in 2008, before functional programming features were introduced into mainstream
imperative languages. The focus is Object Oriented Design, but many of the principals can
be applied to any language.

Given the age of the book, let's revisit the principals and explore how these can be
applied to modern programming languages.

What is Clean Code?
-------------------

There is no explicitly stated definition of Clean Code. However, I think that Clean Code is:

1. Easy to read
2. Easy for other people to enhance
3. Testable

The Boyscout Rule
-----------------

The Boy Scouts of America have a simple rule that can apply to our profession:

   Leave the campground cleaner than you found it

Continuous improvement is the single most important principal in Clean Code. This idea
obviously applies to any programming paradigm, and in my opinion, can extent to all areas
of IT.
   
Principals
----------

The most important principals, practices, and patterns of Clean Code are:

1. Meaningful names
2. Small functions
3. Comments Are a Last Resort
4. Vertical Ordering
5. Data/Object Antisymmetry
6. Test code IS production code
7. Small Modules

Meaningful Names
^^^^^^^^^^^^^^^^

Modules, functions, parameters, and so on should be well named. This means that names
should reveal their intention. Unfortunately it is especially common in functional
programming to use shorthand names.

For example, consider the typeclass definition of the State Monad in Haskell::

    class Monad m => MonadState s m | m -> s where
      -- Snip --

In this case, `s` is the state type, and `m` is the underlying Monad. This forces us to
mentally map these type variables. A more readable declaration might look like::

    class Monad monad => MonadState state monad | monad -> state

While this is more verbose, it reveals the authors intent.

Small Functions
^^^^^^^^^^^^^^^

The first rule of functions is that they should be very small. Functions should also do
only one thing at only one level of abstraction. This principal comes very naturally when
functionally programming.

Comments Are a Last Resort
^^^^^^^^^^^^^^^^^^^^^^^^^^

Comments are used to compensate for our failure to express ourselves in code. This is no
different in functional programming, but our preference for shorthand names makes this
even worse.

Vertical Ordering
^^^^^^^^^^^^^^^^^

Generally, when we define a function, the functions it calls are defined directly below
it. This allows us to skim source files, getting the gist from the first few functions,
without having to immerse ourselves in the details. We can apply this principal in any
language, as long as our language supports forward declaration.

Personally, I like to use a variation of this. I define all my public functions at the top
of the module, then all the functions they depend on, and so forth. This allows us to skim
the module from its highest level to its lowest.


Data/Object Antisymmetry
^^^^^^^^^^^^^^^^^^^^^^^^

Objects hide their data behind abstractions and expose functions that operate on that
data.  Data structures expose their data.

When it comes to functional programming, data structures are frequently used, because we
rely on pattern matching. I think put too much emphasis on "information hiding", we should
really focus on hiding implemenetion. It can be valuable to separate the public API and
its implementation.

When we talk about OO-style abstractions, we are talking about adhoc-polymorphism, or
simply subtyping. In my opinion, we should try to make the abstraction as small as
possible, preferably just one method. Then we can define all other functions in terms of
that method.

For example, consider Java's interface java.util.List. It contains a massive amount of
methods, nearly 30.  Compare this to Haskell's Foldable typeclass, which contains only one
required method, foldr. All other functions can then be defined by using foldr. For
example, here is the definition of null::

    null = foldr (\_ _ -> False) True

Test Code Is Production Code
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Test Driven Development (TDD) enables all the other clean code principals. Furthermore,
test code is just as important as production code. Therefore, we should use the same
principals when maintaining test code.

This is equally important in functional programming. When we write our tests, we should
use the same rigor we do throughout the codebase.

Small Modules
^^^^^^^^^^^^^

The first rule of modules is that they should be small. In OO languages, the basic unit of
organization is a class. However, we may not have OO-style classes in functional
languages. Instead, we generalize this to include modules, which should include nearly all
languages.

Conclusion
----------

It is my opinion that Clean Code transcends programming paradigms. These principals can be
applied equally to functional programming, after slightly rewording some.

You may notice I left out parts of certain principals, like *Objects and Data* and
*Classes*.  Mostly, these deal with OO specifics they don't map cleanly to functional
programming. I've also left out entire principals. Some, like Error Handling or
Concurrency, address Java specifics, but there are other functional abstractions that may
be better. Others, such as boundaries, I didn't feel were as critical as others on this
list.
