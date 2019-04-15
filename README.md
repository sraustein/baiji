baiji
=====

Baiji is a package building tool for Debian environments.  The overall
design borrows heavily from an existing tool called `whalebuilder`,
which in turn is in effect a reimplementation of `pbuilder` using
Docker to do the heavy lifting.

Clean room build environment
----------------------------

`pbuilder` is one of several tools all of which have the same basic
goal: building packages in an environment specified by the package's
`control` file with minimal dependencies on the native environment of
the machine where the build is being run.

`pbuilder` is probably the oldest surviving example of this kind of
build environment for the Debian universe, and uses a fairly simple
approach: it keeps a pristine build environment in a compressed
tarball, which it unpacks into a freshly-chrooted tree for every
build, thus insuring a predictable environment.  The pristine base
environment only includes the "build-essentials" environment that
every Debian package is allowed to assume is always installed:
anything else specified in the `control` file is installed on demand
every time.  While a bit finicky to set up, this is pretty simple in
overall concept, and pretty reliable.  Unfortunately, it's also pretty
slow.

`pbuilder` lacks direct support for dependencies on packages not known
to the Debian project, but it does support hook scripts, which is how
we taught it to use the local package collections that our current
build system stores in `/var/cache/pbuilder/local-packages/`.

If one looks closely at this setup, it turns out to have a lot in
common with Docker containers.  The specific mechanisms are different,
but the overall effect is the same: an isolated environment running a
controlled set of packages and scripts independent of the machine on
which it's running.  The difference is that Docker has a lot of
support for building and distributing images based on other images.

There's a lovely little tool called `whalebuilder` which to a first
approximation is a reimplementation of `pbuilder` on top of Docker.
It turns out that `whalebuilder` doesn't do quite what we want, but
it's close enough to serve as a (very) useful model for a new tool

baiji
-----

`baiji` is intended to incorporate the most useful features of both
`whalebuilder` and `git-buildpackage`, along with some custom features
such as the ability to load locally-built `.deb` packages directly
into the constructed Docker image.

Like both `pbuilder` and `whalebuilder`, `baiji` uses a "base image",
which is constructed using the `debbootstrap` package, along with a
few things needed by `baiji` itself.

Like `whalebuilder` but unlike `pbuilder`, `baiji` also builds
package-specific images for building a particular source package.
While this may sound wasteful, it turns out that it's not: everything
involved in the per-package image construction process is work that
`baiji` would have to do anyway, and by saving the result `baiji`
makes it possible to reuse that image if it turns out that one has to
build the same version of the same source package repeatedly.  By
default, `baiji` only generates a new package-specific build image
when the package's version or build dependencies have changed, but the
user can override this to force a new image.

Also like `whalebuilder` but unlike `pbuilder`, `baiji` performs the
build itself as a non-root user, which is a better fit for the base
Debian model of building packages, and runs with networking turned
off, so that it can catch undeclared dependencies like a package
quietly attempting to `pip install` 25 new packages from PyPi.

Like `debuild` and the `pdebuild` but unlike `whalebuilder`, `baiji`
can generate the source package from the source tree when needed.

As mentioned above, `baiji` supports pre-loading local binary packages
directly into a local APT repository within the package-specific
Docker image.

`baiji`'s base images can be pre-configured to know about local APT
servers,, so that any packages needed for a build can be downloaded
directly.  `apt` running within the usual build tools will use the
package version numbers to decide which version of a package to use
when more than one is available.

`baiji`'s current Interface to Docker just launches the Docker CLI
tool in a subprocess, which turns out to be a lot simpler than using
the official Docker Python API; the latter is only available from
GitHub and PyPi, and depends on enough other PyPi packages that it's a
bit of a maintenance nightmare.  Perhaps this will calm down someday,
but for now it's worth the minor inefficiency of using the Docker CLI
to avoid the swamp.

Unlike `whalebuilder`, which uses uses Ruby's built-in Jinja-like
template mechanism, `baiji` currently just includes the handful of
templates it needs inline using Python's `str.format()` method.  Some
day `baiji` may outgrow this, but it suffices for now.
