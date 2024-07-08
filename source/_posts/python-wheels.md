---
title: Python Wheels with AWS lambda
date: 2024-07-07 16:36:26
tags:
    - aws
    - lambda
    - python
    - wheels
categories:
---

This post is a summary of a deep dive I did on Python wheels.

## What are Python Wheels?

Wheels are a standard format used today to distribute Python packages. They contain all the files needed for the library or application and are more secure than previous methods of distributing packages (such as running an arbitrary setup.py).

Python Wheels were introduced in 2012 in [PEP 427](https://peps.python.org/pep-0427/). They have a .whl file extension, but are actually ZIP archives with a specific internal structure.

Wheels are broken down into tags, like:

```
{dist}-{version}(-{build})?-{python}-{abi}-{platform}.whl
```

An example might be:

```
openai-1.30.1-py3-none-any.whl
```

Breaking this down:

-   openai is the package name
-   1.30.1 is the package version
-   py3 is the python tag. It supported any Python 3 version (although the dependencies pulled in might not! This is the most common source of dependency errors)
-   none is the ABI tag - ABI means `application binary interface`
-   any is the platform tag - it will work on any platform

## Why Use Wheels?

On the [Python Wheels Website](https://pythonwheels.com/), some of the advantages of wheels are mentioned:

-   Faster installation for pure Python and native C extension packages.
-   Avoids arbitrary code execution for installation. (Avoids setup.py)
-   Installation of a C extension does not require a compiler on Linux, Windows or macOS.
-   Allows better caching for testing and continuous integration.
-   Creates .pyc files as part of installation to ensure they match the Python interpreter used.
-   More consistent installs across platforms and machines.

When installing from source distributions, sometimes you miss prerequisites needed to install from the source distribution.

When a wheel is available, an install command might look as simple as:

```bash
% pip install openai
Downloading openai-1.30.1-py3-none-any.whl (320 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 320.6/320.6 kB 1.1 MB/s eta 0:00:00
Using cached anyio-4.3.0-py3-none-any.whl (85 kB)
Using cached distro-1.9.0-py3-none-any.whl (20 kB)
Using cached httpx-0.27.0-py3-none-any.whl (75 kB)
Using cached httpcore-1.0.5-py3-none-any.whl (77 kB)
Using cached pydantic-2.7.1-py3-none-any.whl (409 kB)
Using cached pydantic_core-2.18.2-cp311-cp311-macosx_11_0_arm64.whl (1.8 MB)
Using cached sniffio-1.3.1-py3-none-any.whl (10 kB)
Using cached tqdm-4.66.4-py3-none-any.whl (78 kB)
Using cached typing_extensions-4.11.0-py3-none-any.whl (34 kB)
Using cached annotated_types-0.6.0-py3-none-any.whl (12 kB)
Using cached idna-3.7-py3-none-any.whl (66 kB)
Using cached certifi-2024.2.2-py3-none-any.whl (163 kB)
Using cached h11-0.14.0-py3-none-any.whl (58 kB)
Installing collected packages: typing-extensions, tqdm, sniffio, idna, h11, distro, certifi, annotated-types, pydantic-core, httpcore, anyio, pydantic, httpx, openai
Successfully installed annotated-types-0.6.0 anyio-4.3.0 certifi-2024.2.2 distro-1.9.0 h11-0.14.0 httpcore-1.0.5 httpx-0.27.0 idna-3.7 openai-1.30.1 pydantic-2.7.1 pydantic-core-2.18.2 sniffio-1.3.1 tqdm-4.66.4 typing-extensions-4.11.0
```

or

```bash
% pip install cryptography

Collecting cryptography
  Downloading cryptography-42.0.7-cp39-abi3-macosx_10_12_universal2.whl.metadata (5.3 kB)
Collecting cffi>=1.12 (from cryptography)
  Using cached cffi-1.16.0-cp311-cp311-macosx_11_0_arm64.whl.metadata (1.5 kB)
Collecting pycparser (from cffi>=1.12->cryptography)
  Downloading pycparser-2.22-py3-none-any.whl.metadata (943 bytes)
Downloading cryptography-42.0.7-cp39-abi3-macosx_10_12_universal2.whl (5.9 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 5.9/5.9 MB 6.9 MB/s eta 0:00:00
Using cached cffi-1.16.0-cp311-cp311-macosx_11_0_arm64.whl (176 kB)
Downloading pycparser-2.22-py3-none-any.whl (117 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 117.6/117.6 kB 9.9 MB/s eta 0:00:00
Installing collected packages: pycparser, cffi, cryptography
Successfully installed cffi-1.16.0 cryptography-42.0.7 pycparser-2.22
```

Without wheels, compiling `cryptography` yourself requires a C compiler, a Rust compiler, headers for Python (if you’re not using `pypy`), and headers for the OpenSSL and `libffi` libraries available on your system. The onus is on you to have everything in place when installing from a source distribution. The installation might look like:

```bash
// Alpine
sudo apk add gcc musl-dev python3-dev libffi-dev openssl-dev cargo pkgconfig

// Debian
sudo apt-get install build-essential libssl-dev libffi-dev \
    python3-dev cargo pkg-config

// Fedora/RHEL/CentOS
sudo dnf install redhat-rpm-config gcc libffi-devel python3-devel \
    openssl-devel cargo pkg-config

// MacOS
brew install openssl@3 rust
env OPENSSL_DIR="$(brew --prefix openssl@3)" pip install cryptography
```

## Caveats When Building Lambdas

When building a [lambda](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html) locally to upload to AWS, pip assumes you want to use wheels targetted to your local system and installs the corresponding wheel for it. However, your system is not necessarily the same as the target system on AWS. Many libraries like `requests` have an `any` tag for the target platform, which means it should work. However, it's entirely possible that your system packages the wrong wheels. This can lead to very cryptic errors, so be sure to watch your package manager (pip) installation logs, as sometimes, fetching the correct wheel requires specifying the correct platform.

The solution is tucked away in the above AWS documentation:

> To make your deployment package compatible with Lambda, you install the wheel for Linux operating systems and your function’s instruction set architecture.
> Some packages may only be available as source distributions. For these packages, you need to compile and build the C/C++ components yourself.
> To see what distributions are available for your required package, do the following:
>
> -   Search for the name of the package on the [Python Package Index main page](https://pypi.org/).
> -   Choose the version of the package you want to use.
> -   Choose Download files.

The platform will usually be `manylinux_x_y_z`, where x and y are glibc major and minor versions supported (ie: `manylinux_2_24_xxx` should only work on distros using glibc 2.24+) and z is the architecture, like x86_64 or aarch64. Other forms of `manylinux` include manylinux1 (glibc 2.5 on x86_64 and i686 architectures), manylinux2010 (glibc 2.12 on x86_64 and i686), and manylinux2014 supports glibc 2.17 on x86_64, i686, aarch64, armv7l, ppc64, ppc64le, and s390x.

Caution: when using Amazon Linux 2023 as a base image to run container-based Lambda functions, `manylinux2010_x86_64` and `manylinux2014_x86_64` will fail. The version of glibc in the AL2023 base image has been upgraded to 2.34, from 2.26 that was bundled in the AL2 base image.

```bash
pip install \
--platform manylinux2014_x86_64 \
--target=package \
--implementation cp \
--python-version 3.x \
--only-binary=:all: --upgrade \
<package_name>
```

For arm64

```bash
pip install \
--platform manylinux2014_aarch64 \
--target=package \
--implementation cp \
--python-version 3.x \
--only-binary=:all: --upgrade \
<package_name>
```

For [lambda layers](https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html), AWS explicitly states:

> Because Lambda functions run on Amazon Linux, your layer content must be able to compile and build in a Linux environment.
> In Python, most packages are available as wheels (.whl files) in addition to the source distribution. Each wheel is a type of built distribution that supports a specific combination of Python versions, operating systems, and machine instruction sets.
> Wheels are useful for ensuring that your layer is compatible with Amazon Linux. When you download your dependencies, download the universal wheel if possible. (By default, pip installs the universal wheel if one is available.) The universal wheel contains any as the platform tag, indicating that it's compatible with all platforms, including Amazon Linux.

However...

> Not all Python packages are distributed as universal wheels. For example, numpy has multiple wheel distributions, each supporting a different set of platforms. For such packages, download the manylinux distribution to ensure compatibility with Amazon Linux. For detailed instructions about how to package such layers, see Working with manylinux wheel distributions.

> In rare cases, a Python package might not be available as a wheel. If only the source distribution (sdist) exists, then we recommend installing and packaging your dependencies in a Docker environment based on the Amazon Linux 2023 base container image. We also recommend this approach if you want to include your own custom libraries written in other languages such as C/C++. This approach mimics the Lambda execution environment in Docker, and ensures that your non-Python package dependencies are compatible with Amazon Linux.

Understanding wheels will make your life easier, especially in the cases of troubleshooting Python dependencies.
