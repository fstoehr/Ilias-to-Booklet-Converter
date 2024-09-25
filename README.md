# Ilias-to-Booklet-Converter

This script is intended to be used on files exported from the LMS (Learning Management System) ILIAS.
It converts exercises exported from ILIAS that contain many individual
assignments handed in by different students into one booklet per student
containing the first page of every exercise.

The main didactic context this is useful for are what are often called
booklet exams: Students are allowed to hand in one page of (often
hand-written) notes every week or so, and are provided with a printout of
their notes in brochure form when they take their exam.

More information and an English translation of the script will follow
later.

## Installing on Linux

### Using the Nix Flake (on NixOS or any other Distro)

This assumes nix is already installed. You can simply execute the script
using

```
nix run github:fstoehr/Ilias-to-Booklet-Converter
```

To install it so you always have it available, you can run

```
nix profile install github:fstoehr/Ilias-to-Booklet-Converter
```

To run the script if it's installed, just run

```
ilias-to-booklet
```

#### If flakes are disabled

If you don't have flakes enabled, you may need to instead use the
following commands:

```
nix --extra-experimental-feature "flakes nix-command" github:fstoehr/Ilias-to-Booklet-Converter
nix --extra-experimental-feature "flakes nix-command" profile install github:fstoehr/Ilias-to-Booklet-Converter
```

### Using your distribution's package manager

#### 1. Install dependencies

Make sure the following programs are installed:

```
p7zip imagemagick pdftk poppler-utils
```

the following programs are probably already installed:

```
ghostscript sed bc
```

As an example, for Debian-based distros, these can be installed with 

```
apt install poppler-utils pdftk-java ghostscript imagemagick p7zip sed bc
```


### 2. Install Script

Download the file `ilias-to-booklet.sh` above. Alternatively, clone this repo with

```
git clone github:fstoehr/Ilias-to-Booklet-Converter
```

Ideally, put the script somewhere in your path. Give yourself permission
to execute it using

```
chmod u+x ilias-to-booklet.sh
```

Then open a terminal in
the directory with the Zip-archives downloaded from Ilias and run:

```
ilias-to-booklet.sh
```

If the script isn't in your path, specify the directory it's in, for
instance

```
~/Downloads/ilias-to-booklet.sh
```




## MacOS

### with Nix (recommended)

#### 1. Install nix package manager

If you haven't already, install the nix package manager. The simplest way
to do that on MacOS appears to be the graphical installer by [Determinate
Systems](https://determinate.systems/posts/graphical-nix-installer/).


#### 2. Run or install script

You can run the script directly from a terminal if you enter the directory
with the Zip-archives downloaded from Ilias and then run:

```
nix run github:fstoehr/Ilias-to-Booklet-Converter
```


If you want to install the script so it's permanently available, run:

```
nix profile install github:fstoehr/Ilias-to-Booklet-Converter
```

Then run the script with 

```
ilias-to-booklet
```

(if you installed the nix package manager in another way as via ...,
flakes might not yet be activated. In that case, instead of the commands
above, run one of these:

```
nix --extra-experimental-feature "flakes nix-command" run github:fstoehr/Ilias-to-Booklet-Converter
nix --extra-experimental-feature "flakes nix-command" profile install github:fstoehr/Ilias-to-Booklet-Converter
```
)


### with Homebrew (not tested)

#### 1. Install Homebrew

If you haven't aleady, install [homebrew](https://brew.sh).

#### 2. Install Dependencies

```
brew install p7zip findutils pdftk-java ghostscript poppler
```

(
Everything else the script needs should already be installed in MacOS. If for some reason
it isn't, you could also run the following to see if the script will
work then:

```
brew install coreutils gnu-sed bc
```
)

#### 3. Download the script

Download the file ilias-to-booklet.sh above. You might want to add it to your path. Then open a terminal in the directory the
Zip-files you downloaded from ILIAS are located and run it:

```
ilias-to-booklet.sh
```

or, if the script is not in your path, but for instance in your Downloads
directory:

```
~/Downloads/ilias-to-booklet.sh
```
