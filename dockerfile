# Build stage with Spack pre-installed and ready to be used
FROM spack/ubuntu-jammy:latest as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo spack: \
&&   echo '  # add package specs to the `specs` list' \
&&   echo '  config:' \
&&   echo '    shared_linking:' \
&&   echo '      bind: true' \
&&   echo '    install_tree: /opt/software' \
&&   echo '  specs:' \
&&   echo '  - cmake@3.27.7' \
&&   echo '  - hdf5@1.14.2 +mpi +threadsafe +fortran +hl +map +szip +tools +shared' \
&&   echo '  - netcdf-c build_system=cmake' \
&&   echo '  - netcdf-fortran' \
&&   echo '  - catch2' \
&&   echo '  - eigen' \
&&   echo '  - gsl+external-cblas' \
&&   echo '  - vtk-m+mpi~tbb' \
&&   echo '  - petsc@3.20.2 +double +fortran +mpi -openmp -superlu-dist +hypre +kokkos +hwloc' \
&&   echo '    +metis +mumps -parmmg +ptscotch +random123 +saws +scalapack cflags="-O3 -ffast-math"  fflags="-O3 -ffast-math"' \
&&   echo '  - googletest@1.12.0 cxxstd=17' \
&&   echo '  - py-pybind11' \
&&   echo '  - nlohmann-json' \
&&   echo '  - suite-sparse -openmp' \
&&   echo '  - mpich +fortran' \
&&   echo '  - hypre +fortran -openmp +mpi -magma -superlu-dist +shared' \
&&   echo '  - kokkos@master -openmp +examples +aggressive_vectorization -cuda -shared cxxflags="-O3' \
&&   echo '    -ffast-math"' \
&&   echo '  - kokkos-kernels@master  +blas +lapack +superlu -cuda -openmp -shared' \
&&   echo '  - fmt' \
&&   echo '  - spdlog +fmt_external +ipo -shared' \
&&   echo '  - nlohmann-json-schema-validator' \
&&   echo '  - intel-tbb@master' \
&&   echo '  - mgard -openmp' \
&&   echo '  - zlib-ng' \
&&   echo '  - amrex +petsc +eb +fortran +particles +hypre +linear_solvers +sundials' \
&&   echo '  - clhep cxxstd=17' \
&&   echo '  - mdspan~examples+ipo~tests' \
&&   echo '  - adios2@2.9.2 -sz' \
&&   echo '  - py-matplotlib' \
&&   echo '  - assimp' \
&&   echo '  - glfw +shared' \
&&   echo '  - imgui' \
&&   echo '  - freetype build_system=cmake -shared' \
&&   echo '  - taskflow@3.6.0+ipo' \
&&   echo '  - llvm@17.0.6 -flang' \
&&   echo '  - cgal@5.5.2 +core +eigen +imageio -shared build_system=cmake' \
&&   echo '  - libxc@6.2.2+kxc+lxc~shared' \
&&   echo '  - boost@1.83.0+context+math+multithreaded+signals+thread+timer cxxstd=20' \
&&   echo '  view: /opt/views/view' \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  compilers:' \
&&   echo '  - compiler:' \
&&   echo '      spec: clang@=14.0.5' \
&&   echo '      paths:' \
&&   echo '        cc: /usr/bin/clang' \
&&   echo '        cxx: /usr/bin/clang++' \
&&   echo '        f77: null' \
&&   echo '        fc: null' \
&&   echo '      flags: {}' \
&&   echo '      operating_system: fedora36' \
&&   echo '      target: aarch64' \
&&   echo '      modules: []' \
&&   echo '      environment: {}' \
&&   echo '      extra_rpaths: []' \
&&   echo '  - compiler:' \
&&   echo '      spec: gcc@=12.2.1' \
&&   echo '      paths:' \
&&   echo '        cc: /usr/bin/gcc' \
&&   echo '        cxx: /usr/bin/g++' \
&&   echo '        f77: /usr/bin/gfortran' \
&&   echo '        fc: /usr/bin/gfortran' \
&&   echo '      flags: {}' \
&&   echo '      operating_system: fedora36' \
&&   echo '      target: aarch64' \
&&   echo '      modules: []' \
&&   echo '      environment: {}' \
&&   echo '      extra_rpaths: []' \
&&   echo '  - compiler:' \
&&   echo '      spec: clang@=17.0.2' \
&&   echo '      paths:' \
&&   echo '        cc: /opt/homebrew/opt/llvm/bin/clang' \
&&   echo '        cxx: /opt/homebrew/opt/llvm/bin/clang++' \
&&   echo '        f77: /opt/homebrew/bin/gfortran' \
&&   echo '        fc: /opt/homebrew/bin/gfortran' \
&&   echo '      flags:' \
&&   echo '        # ldflags: -Wl,-ld_classic' \
&&   echo '        fflags: -L/opt/homebrew/opt/gcc/lib/gcc/current/' \
&&   echo '      operating_system: sonoma' \
&&   echo '      target: aarch64' \
&&   echo '      modules: []' \
&&   echo '      environment: {}' \
&&   echo '      extra_rpaths: []' \
&&   echo '  - compiler:' \
&&   echo '      spec: nag@=7.1.7125' \
&&   echo '      paths:' \
&&   echo '        cc: /usr/bin/clang' \
&&   echo '        cxx: /usr/bin/clang++' \
&&   echo '        f77: /usr/local/bin/nagfor' \
&&   echo '        fc: /usr/local/bin/nagfor' \
&&   echo '      flags:' \
&&   echo '        fflags: -f2018 -fpp -free -framework Accelerate' \
&&   echo '      operating_system: sonoma' \
&&   echo '      target: aarch64' \
&&   echo '      modules: []' \
&&   echo '      environment: {}' \
&&   echo '      extra_rpaths: []') > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# Strip all the binaries
RUN find -L /opt/views/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . > activate.sh


# Bare OS image to run the installed executables
FROM ubuntu:22.04

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software

# paths.view is a symlink, so copy the parent to avoid dereferencing and duplicating it
COPY --from=builder /opt/views /opt/views

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& ln -s /opt/views/view /opt/view


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]
