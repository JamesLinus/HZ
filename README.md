# HZ

> HZ is a reference implementation of Hazelnut, a bidirectionally typed structure editor calculus (see POPL 2017 draft)

# Running HZ
You can run HZ without installing any dependencies by opening /src/www/hz.html in a browser.

# Building HZ
You can build HZ using the following instructions.

## Installing OCaml and dependencies

An easy way to install both OCaml and the necessary libraries is to install [opam](https://opam.ocaml.org/). After having installed `opam` using the instructions on their website, follow these steps:

  - If you are using `opam` for the first time, you have to initialize it:

    ```sh
    > opam init
    > eval `opam config env`
    ```

    This will create a `.opam` directory in your home.

  - You need a recent version of the OCaml compiler. First check the current version used by `opam`:

    ```sh
    > opam switch
    --     -- 3.11.2  Official 3.11.2 release
    --     -- 3.12.1  Official 3.12.1 release
    --     -- 4.00.0  Official 4.00.0 release
    --     -- 4.00.1  Official 4.00.1 release
    --     -- 4.01.0  Official 4.01.0 release
    --     -- 4.02.0  Official 4.02.0 release
    --     -- 4.02.1  Official 4.02.1 release
    --     -- 4.02.2  Official 4.02.2 release
    --     -- 4.02.3  Official 4.02.3 release
    --     -- 4.03.0  Official 4.03.0 release
    system  C system  System compiler (4.02.1)
    ```

    The `C` marks the current compiler. Here version 4.02.1 is installed. We can see that a more recent version is available (4.03.0). So we will install it with `opam switch 4.03.0`. This won't remove the system compiler as `opam` will install the files in your `.opam` directory.

    The following command switches out the current compiler with the newly installed one and sets up your path to use it permanently.

    ```sh
    > opam switch 4.02.2
    > eval `opam config env`
    ```

  - We can now install Js_of_ocaml and tyxml, including optional dependencies.
  NOTE: Currently HZ only works with TyXML 4.0, which is NOT backwards compatible with TyXML 3.X
 
    ```sh
    > opam install js_of_ocaml tyxml deriving ppx_deriving reactiveData ocp-indent
    ```

  - To make sure you have the latest version, ask `opam` to upgrade the packages if needed:

    ```sh
    > opam update
    > opam upgrade
    ```

  Congratulations, you now have all the required packages! We can now build the application.

## Compilation

You can execute build.sh to compile hz.ml.

```sh
> cd src/
> /bin/sh build.sh
```

It consists of two steps:

1. Compile the `hz.ml` file to OCaml bytecode with the `ocamlbuild` command:

  ```sh
  > ocamlbuild -use-ocamlfind \
  -pkgs lwt.ppx,js_of_ocaml,js_of_ocaml.ppx,js_of_ocaml.tyxml,tyxml,react,reactiveData \
  hz.byte ;
  ```

2. Build the Javascript file from the `hz.byte` file with the `js_of_ocaml` command:

  ```sh
  > js_of_ocaml +weak.js --opt 3 -o www/js/hz.js hz.byte
  ```

  The command options are:
  - `+weak.js` to include the necessary `weak` package.
  - `-o hello.js` to set output file name.

  You can include `--opt 3` to optimize more heavily.

## Results
You can now open hz.html in a browser to see it working.

## Support

Js_of_ocaml is part of the [Ocsigen project](http://ocsigen.org/).

- [Mailing list](https://sympa.inria.fr/sympa/subscribe/ocsigen)
- IRC : #ocsigen on irc.freenode.net

## Resources

- [Website](http://ocsigen.org/js_of_ocaml/)
- [GitHub](https://github.com/ocsigen/js_of_ocaml)
- [Try Js_of_ocaml](http://try.ocamlpro.com/js_of_ocaml/)
- 
## Credit

This README is based on the readme.md file for the [TodoMVC example](https://github.com/slegrand45/examples_ocsigen/tree/master/jsoo/todomvc-react) by [Stéphane Legrand](https://github.com/slegrand45).

# Implementation Details

The file `hz_semantics.ml` implements the syntax and semantics from the paper in a pure functional style, independent of any details of the view. NOTE: We use positive ocaml integers for the Hazelnut `num` type. 

The file `hz_model.ml` gives the signature of the reactive signal that models edit states, which consist of a Z-expression paired with an H-type.

The file `hz_view.ml` transforms terms to HTML trees.

The file `hz.ml` (which should be read roughly from the bottom up) is the top-level file. It sets up the reactive signals  and constructs the action palette, which controls updates to the model and therefore the view. 

