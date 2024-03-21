# Build stage with Spack pre-installed and ready to be used
FROM spack/fedora38:latest as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo spack: \
&&   echo '  specs:' \
&&   echo '  - cmake@3.27.7' \
&&   echo '  - hdf5@1.14.2 +mpi +threadsafe +fortran +hl +map +szip +tools +shared' \
&&   echo '  - netcdf-c@4.9.2 build_system=cmake' \
&&   echo '  - netcdf-fortran@4.6.1' \
&&   echo '  - catch2@3.4.0' \
&&   echo '  - eigen@3.4.0' \
&&   echo '  - gsl@2.7.1 +external-cblas' \
&&   echo '  - vtk-m@2.1.0 +mpi -tbb -cuda +rendering -shared  +openmp +fpic' \
&&   echo '  - petsc@3.20.1 +double +fortran +mpi +openmp -superlu-dist +int64 +hypre +kokkos +hwloc' \
&&   echo '    +metis +mumps -parmmg +ptscotch +random123 +saws +scalapack -memkind +strumpack +fftw' \
&&   echo '    +suite-sparse memalign=64' \
&&   echo '  - googletest@1.12.0 cxxstd=17' \
&&   echo '  - py-pybind11@2.11.1' \
&&   echo '  - nlohmann-json@3.11.2' \
&&   echo '  - suite-sparse@5.13.0 +openmp' \
&&   echo '  - mpich@4.1.2 +fortran' \
&&   echo '  - hypre@2.29.0 +fortran +openmp +mpi -magma -superlu-dist +shared +int64' \
&&   echo '  - kokkos@4.0.00 +openmp +examples +aggressive_vectorization -cuda +shared' \
&&   echo '  - kokkos-kernels@4.0.00 +blas +lapack +superlu -cuda +openmp +shared' \
&&   echo '  - fmt@10.1.1' \
&&   echo '  - spdlog@1.12.0 +fmt_external +shared' \
&&   echo '  - nlohmann-json-schema-validator@2.1.0' \
&&   echo '  - nlopt@2.7.0 +shared +python' \
&&   echo '  - mgard@2023-03-31 +openmp' \
&&   echo '  - zlib-ng@2.1.4' \
&&   echo '  - amrex@23.11 +petsc +eb +fortran +particles +hypre +linear_solvers +sundials' \
&&   echo '  - clhep@2.4.6.4' \
&&   echo '  - libcatalyst@2.0.0-rc4  +mpi' \
&&   echo '  - mdspan@0.6.0 ~examples ~tests' \
&&   echo '  - slepc@3.20.0 +arpack -blopex' \
&&   echo '  - adios2@2.9.2' \
&&   echo '  - assimp@5.3.1' \
&&   echo '  - openblas@0.3.24 +fortran +pic +locking threads=openmp' \
&&   echo '  - python@3.11.6' \
&&   echo '  - libsigsegv@2.14' \
&&   echo '  - googletest@1.12.0' \
&&   echo '  view: /opt/views/view' \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  compilers:' \
&&   echo '  - compiler:' \
&&   echo '      spec: gcc@=11.4.0' \
&&   echo '      paths:' \
&&   echo '        cc: /usr/bin/gcc' \
&&   echo '        cxx: /usr/bin/g++' \
&&   echo '        f77: /usr/bin/gfortran' \
&&   echo '        fc: /usr/bin/gfortran' \
&&   echo '      flags:' \
&&   echo '         cflags: -Ofast -ffast-math' \
&&   echo '         cxxflags: -Ofast -ffast-math' \
&&   echo '         fflags: -Ofast -ffast-math -frepack-arrays -ffree-line-length-none' \
&&   echo '      operating_system: fedora38' \
&&   echo '      target: x86_64' \
&&   echo '      modules: []' \
&&   echo '      environment: {}' \
&&   echo '      extra_rpaths: []' \
&&   echo '  config:' \
&&   echo '    install_tree: /opt/software') > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . \
&& spack install --source --reuse --fail-fast -j 8 && spack gc -y

# Strip all the binaries
# RUN find -L /opt/views/view/* -type f -exec readlink -f '{}' \; | \
#     xargs file -i | \
#     grep 'charset=binary' | \
#     grep 'x-executable\|x-archive\|x-sharedlib' | \
#     awk -F: '{print $1}' | xargs strip

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . > activate.sh


# Bare OS image to run the installed executables
FROM fedora:38

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software

# paths.view is a symlink, so copy the parent to avoid dereferencing and duplicating it
COPY --from=builder /opt/views /opt/views

ADD build.sh /build.sh
RUN chmod a+x /build.sh \
&& bash /build.sh

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& chmod a+x /opt/spack-environment/activate.sh \
&& ln -s /opt/views/view /opt/view


ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]
