# xeus-ug4

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/UG4/xeus-ug4/master)

**xeus-ug4** is Jupyter kernel for UG4 based on the native implementation of the Jupyter protocol xeus.
**xeus-ug4** is early developer preview. Is is not suitable for general usage yet.  

## Usage

Launch the Jupyter notebook with 'jupyter notebook' or Jupyter lab with 'jupyter lab' and launch a new Jupyter notebook by selecting the **UG4 LUA**  kernel.


## Installation

Currently, only installation from source is available.

Conda dependencies:
```
conda create -n xeus-ug4-env
conda activate xeus-ug4-env
conda install cmake nlohmann_json xtl cppzmq xeus -c conda-forge
```

Install kernel:

```
mkdir build
cd build
cmake -D CMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make
make install
```

## Documentation

Documentation is not available yet.
Dependencies

xeus-ug4 depends on

    xeus
    nlohmann/json
    

## License

This software is licensed under the BSD-3-Clause license. See the LICENSE file for details.
