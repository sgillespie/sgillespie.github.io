---
title: "A Recipe for New Haskell Projects with Nix"
---
==========================================
A Recipe for New Haskell Projects with Nix
==========================================

How do you start a new Haskell project from scratch? Boilerplates and generators are one
option, such as summoner_, `hi`_, haskell-template_, and many more. However, there are some
issues with boilerplates. The main disadvantage is that, once started, boilerplates can't
be updated. More importantly, I believe it's important to practice starting new projects
from scratch.

Having repeated this exercise many times, a common pattern began to emerge, which will be
the subject of this article.

Before diving in, let's take a look at some of the choices I will make:

* Continuous Integration: `GitHub Actions`_
* Nix infrastructure: `haskell.nix`_
* Formatter: Fourmolu_

This means we'll need to create the following components:

* Cabal Boilerplate
* Nix Flake
* Fourmolu Configuration
* GitHub Actions Workflow

First Steps
===========

Start a nix shell with the required tools::

    nix-shell -p haskell.compiler.ghc964

Create a directory for the new project::

    mkdir -p new-project
    cd new-project
    git init

Generating Cabal Boilerplate
============================

Earlier I said I don't like boilerplates, but ``cabal init`` is lean enough that there isn't
much downside::

    cabal init --no-comments --overwrite

After answering the questions, we will have a very small cabal project. I will also
usually add a test library to the ``*.cabal`` package for QuickCheck or Hedgehog
generators::

    library testlib
      import:           warnings
      -- exposed-modules:  MyLib
      -- other-modules:
      -- other-extensions:
      build-depends:    base
      hs-source-dirs:   testlib
      default-language: Haskell2010

Create the testlib directory::

    mkdir -p testlib

Though not required, I recommend adding a cabal.project::

    packages: ./*.cabal

    index-state: YYYY-MM-DDT00:00:00Z

    tests: True
    test-show-details: direct

Commit what we have so far::

    git add .
    git commit -m "chore: Add cabal boilerplate"

Test that it builds::

    cabal build all
    cabal run
    cabal test

Nix Flake
=========

There are many options for using Nix with Haskell: callCabal2Nix, developPackage_,
haskell-flake_, `haskell.nix`_, on and on. I usually reach for `haskell.nix`_, because
it can easily produce windows cross-builds and fully static linux binaries.

Create the ``nix.flake``::

    {
      inputs = {
        haskellNix.url = "github:input-output-hk/haskell.nix";
        nixpkgs.follows = "haskellNix/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
      };

      outputs = { self, nixpkgs, flake-utils, haskellNix }@attrs:
        flake-utils.lib.eachSystemDefaultSystem (system:
          let
            overlays = [
              haskellNix.overlay

              (final: prev: {
                cabalProject =
                  final.haskell-nix.cabalProject' {
                    src = ./.;
                    compiler-nix-name = "ghc964";

                    # This is used by `nix develop .` to open a shell for use with
                    # `cabal`, `hlint` and `haskell-language-server`
                    shell.tools = {
                      cabal = {};
                      fourmolu = {};
                      hlint = {};
                      haskell-language-server = {};
                    };

                    # Non-Haskell shell tools go here
                    shell.buildInputs = with pkgs; [
                      nixpkgs-fmt
                    ];
                  };
              })
            ];

            pkgs = import nixpkgs {
              inherit system overlays;
              inherit (haskellNix) config;
            };

            flake = pkgs.cabalProject.flake { };

          in
            flake // {
              # Built by `nix build .`
              packages.default = flake.packages."hello:exe:hello";
            });
    }

**Important**: Nix will refuse to evaluate a flake unless it's in the git index. Add
``flake.nix``::

    git add flake.nix
    git commit -m "chore: Add cabal and nix boilerplate"

Make sure everything builds::

    nix develop .
    cabal build
    cabal run
    exit

This should have generated ``flake.lock``, so let's add that and commit::

    git add flake.lock
    git commit -m "chore: Add a nix flake"

Fourmolu Configuration
======================

Generate ``fourmolu.yaml``::

    nix develop -c fourmolu --print-defaults > fourmolu.yaml

We may as well reformat all sources::

    nix develop -c fourmolu --mode=inplace src app test

Then tweak it to your preferences, and commit it::

    git add .
    git commit -m "chore: Add fourmolu config"

GitHub Actions
==============

I happen to use GitHub, so I also use GitHub Actions. The cachix action is an excellent
choice, and they have instructions for many more Continuous Integration services.

Note the workflow below requires a Cachix [free] cache. This could save a lot of time
building dependencies. Still, you can always omit the ``cachix/cachix-action``.

Create a workflow at ``.github/workflows/build.yaml``. A good starting point is building the
executable and running the tests::

     name: Nix Build

     on:
       - push
       - pull_request

     permissions:
       contents: read

     jobs:
       build:
         runs-on: ubuntu-latest
         steps:
         - uses: actions/checkout@v3
         - uses: cachix/install-nix-action@v22
           with:
             github_access_token: ${{ secrets.GITHUB_TOKEN }}
             extra_nix_config: |
               experimental-features = nix-command flakes
               allow-import-from-derivation = true
               accept-flake-config = true
         - uses: cachix/cachix-action@v12
           with:
             name: <cache-name>
             authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
         - name: Build executable
           run: nix build -L .
         - name: Run tests
           run: |
             nix build -L .#checks.x86_64-linux."new-project:test:new-project-test"

Commit the the workflow::

    git add .github
    git commit -m "chore: Add GitHub workflow"

Finishing Up
============

Finally, push it upstream. The GitHub workflow should automatically run::

    git remote add origin git@github.com:my-user/new-project
    git fetch
    git push -u origin main

.. _Summoner: https://kowainik.github.io/projects/summoner
.. _hi: https://github.com/fujimura/hi
.. _haskell-template: https://srid.ca/haskell-template
.. _GitHub Actions: https://docs.github.com/en/actions
.. _haskell.nix: https://input-output-hk.github.io/haskell.nix/
.. _Fourmolu: https://github.com/fourmolu/fourmolu
.. _developPackage: https://nixos.wiki/wiki/Haskell#Using_developPackage_.28use_the_nix_packages_set_for_haskell.29
.. _haskell-flake: https://community.flake.parts/haskell-flake
